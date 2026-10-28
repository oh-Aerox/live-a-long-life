package io.github.oh_aerox.live_a_long_life

import android.app.Activity
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * 后台与提醒引导（plan-android AN-M2）：小米等系统会清理后台应用，提醒不响、
 * 后台同步不发生。这里只负责查状态和打开对应的系统设置页，设置由用户自己点。
 */
object AndroidSettingsChannel {
    fun register(messenger: BinaryMessenger, activity: Activity) {
        MethodChannel(messenger, "life.long/android_settings").setMethodCallHandler { call, result ->
            when (call.method) {
                "status" -> {
                    val pm = activity.getSystemService(Context.POWER_SERVICE) as PowerManager
                    result.success(mapOf(
                        "ignoringBatteryOptimizations" to
                            pm.isIgnoringBatteryOptimizations(activity.packageName),
                        "manufacturer" to Build.MANUFACTURER,
                        "model" to Build.MODEL,
                        "release" to Build.VERSION.RELEASE,
                        "sdk" to Build.VERSION.SDK_INT,
                    ))
                }
                "openAppDetails" -> result.success(open(activity, appDetails(activity)))
                "openAutoStart" -> {
                    // 小米"自启动管理"；别的品牌或系统改版后打不开时退回应用详情页。
                    val miui = Intent().setComponent(ComponentName(
                        "com.miui.securitycenter",
                        "com.miui.permcenter.autostart.AutoStartManagementActivity"))
                    result.success(open(activity, miui) || open(activity, appDetails(activity)))
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun appDetails(activity: Activity) =
        Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.fromParts("package", activity.packageName, null))

    private fun open(activity: Activity, intent: Intent): Boolean = try {
        activity.startActivity(intent)
        true
    } catch (e: Exception) {
        false
    }
}
