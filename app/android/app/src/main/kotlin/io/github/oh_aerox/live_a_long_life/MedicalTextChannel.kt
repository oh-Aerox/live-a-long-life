package io.github.oh_aerox.live_a_long_life

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.graphics.Matrix
import android.graphics.pdf.PdfRenderer
import android.os.Handler
import android.os.Looper
import android.os.ParcelFileDescriptor
import androidx.exifinterface.media.ExifInterface
import com.google.android.gms.tasks.Tasks
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions
import com.tom_roush.pdfbox.android.PDFBoxResourceLoader
import com.tom_roush.pdfbox.pdmodel.PDDocument
import com.tom_roush.pdfbox.text.PDFTextStripper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.Executors

/**
 * 本地文字提取（D-23）：PDF 文字层直取 + 扫描页渲染 + ML Kit 中文识别。
 * 与 ios/Runner/AppDelegate.swift 的 MedicalTextChannel 同名同参同返回：
 * 坐标是 0–1 归一化、原点左上，定位高亮（A-19）直接复用。
 */
object MedicalTextChannel {
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    /** OCR 用途：最长边约 2200px，与 iOS 一致。 */
    private const val RENDER_LONG_SIDE = 2200f

    /** 照片解码上限：5000 万像素原图全尺寸解码要约 200MB 内存。 */
    private const val OCR_MAX_SIDE = 4000

    fun register(messenger: BinaryMessenger, context: Context) {
        PDFBoxResourceLoader.init(context)
        val recognizer = TextRecognition.getClient(
            ChineseTextRecognizerOptions.Builder().build())
        val channel = MethodChannel(messenger, "life.long/medical_text")
        channel.setMethodCallHandler { call, result ->
            val path = call.argument<String>("path")
            if (path == null) {
                result.error("bad_args", "缺少 path", null)
                return@setMethodCallHandler
            }
            // 全部放到后台线程；结果回主线程交给 Flutter。
            worker.execute {
                try {
                    val value: Any? = when (call.method) {
                        "pdfPageCount" -> openPdf(path).use { it.pageCount }
                        "pdfPageText" -> pdfPageText(path, call.argument<Int>("page")!!)
                        "renderPdfPage" -> renderPdfPage(
                            path, call.argument<Int>("page")!!,
                            call.argument<String>("outPath")!!)
                        "ocrImage" -> ocrImage(recognizer, path)
                        else -> {
                            main.post { result.notImplemented() }
                            return@execute
                        }
                    }
                    main.post { result.success(value) }
                } catch (e: Exception) {
                    main.post {
                        result.error("${call.method}_failed", "${call.method} 失败：$e", null)
                    }
                }
            }
        }
    }

    private fun openPdf(path: String): PdfRenderer =
        PdfRenderer(ParcelFileDescriptor.open(File(path), ParcelFileDescriptor.MODE_READ_ONLY))

    /** 某页文字层（0 起页号）。加密或结构损坏抽不出来时返回 null，Dart 端退回渲染 + OCR。 */
    private fun pdfPageText(path: String, page: Int): String? = try {
        PDDocument.load(File(path)).use { doc ->
            PDFTextStripper().apply {
                startPage = page + 1
                endPage = page + 1
            }.getText(doc)
        }
    } catch (e: Exception) {
        null
    }

    private fun renderPdfPage(path: String, page: Int, outPath: String): String {
        openPdf(path).use { renderer ->
            renderer.openPage(page).use { p ->
                val scale = minOf(RENDER_LONG_SIDE / maxOf(p.width, p.height), 4f)
                val bitmap = Bitmap.createBitmap(
                    (p.width * scale).toInt(), (p.height * scale).toInt(),
                    Bitmap.Config.ARGB_8888)
                // PdfRenderer 画在透明底上，先铺白，否则 OCR 和显示都是黑底。
                bitmap.eraseColor(Color.WHITE)
                p.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                FileOutputStream(outPath).use {
                    bitmap.compress(Bitmap.CompressFormat.PNG, 100, it)
                }
                bitmap.recycle()
            }
        }
        return outPath
    }

    /**
     * 按 EXIF 方向转正后识别：Flutter 显示图片时会按 EXIF 转正，坐标要对齐
     * 转正后的图。坐标按解码图尺寸归一化，缩小解码不影响结果。
     */
    private fun ocrImage(
        recognizer: com.google.mlkit.vision.text.TextRecognizer, path: String
    ): List<Map<String, Any>> {
        val bitmap = decodeUpright(path)
        try {
            val text = Tasks.await(recognizer.process(InputImage.fromBitmap(bitmap, 0)))
            val w = bitmap.width.toDouble()
            val h = bitmap.height.toDouble()
            val lines = mutableListOf<Map<String, Any>>()
            for (block in text.textBlocks) {
                for (line in block.lines) {
                    val b = line.boundingBox ?: continue
                    lines.add(mapOf(
                        "text" to line.text,
                        "x" to b.left / w,
                        "y" to b.top / h,
                        "w" to b.width() / w,
                        "h" to b.height() / h,
                    ))
                }
            }
            return lines
        } finally {
            bitmap.recycle()
        }
    }

    private fun decodeUpright(path: String): Bitmap {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(path, bounds)
        var sample = 1
        while (maxOf(bounds.outWidth, bounds.outHeight) / sample > OCR_MAX_SIDE) sample *= 2
        val raw = BitmapFactory.decodeFile(path, BitmapFactory.Options().apply {
            inSampleSize = sample
        }) ?: throw IllegalArgumentException("无法解码图片")
        val degrees = when (ExifInterface(path).getAttributeInt(
            ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL)) {
            ExifInterface.ORIENTATION_ROTATE_90 -> 90f
            ExifInterface.ORIENTATION_ROTATE_180 -> 180f
            ExifInterface.ORIENTATION_ROTATE_270 -> 270f
            else -> 0f
        }
        if (degrees == 0f) return raw
        val rotated = Bitmap.createBitmap(
            raw, 0, 0, raw.width, raw.height, Matrix().apply { postRotate(degrees) }, true)
        raw.recycle()
        return rotated
    }
}
