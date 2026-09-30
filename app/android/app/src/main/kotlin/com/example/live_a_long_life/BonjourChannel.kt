package com.example.live_a_long_life

import android.content.Context
import android.net.nsd.NsdManager
import android.net.nsd.NsdServiceInfo
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.net.Inet4Address

/**
 * 局域网发现（V4-M5 mDNS）：手机按 Mac 的设备 ID 找回当前地址。与
 * ios/Runner/AppDelegate.swift 的 BonjourChannel 同一协议：服务类型
 * `_llal-sync._tcp`，服务名 `llal-<设备 ID>`，返回逗号分隔的 IPv4 `host:port`，
 * 包含 Mac 写在 TXT `ips` 里的局域网地址。手机不广播，只实现 resolve。
 */
object BonjourChannel {
    private const val TAG = "bonjour"
    private const val SERVICE_TYPE = "_llal-sync._tcp"

    private val main = Handler(Looper.getMainLooper())
    private lateinit var nsd: NsdManager

    private var pending: MethodChannel.Result? = null
    private var wanted: String? = null
    private var discovery: NsdManager.DiscoveryListener? = null
    private var resolving = false
    private val collected = mutableListOf<String>()
    private val timeout = Runnable { finish() }

    fun register(messenger: BinaryMessenger, context: Context) {
        nsd = context.getSystemService(Context.NSD_SERVICE) as NsdManager
        MethodChannel(messenger, "life.long/bonjour").setMethodCallHandler { call, result ->
            when (call.method) {
                "resolve" -> {
                    val name = call.argument<String>("name")
                    if (name == null) {
                        result.error("bad_args", "需要 name", null)
                        return@setMethodCallHandler
                    }
                    resolve(name, call.argument<Int>("timeoutMs") ?: 5000, result)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun resolve(name: String, timeoutMs: Int, result: MethodChannel.Result) {
        finish() // 上一次没完成的查找直接结束
        pending = result
        wanted = name
        val listener = object : NsdManager.DiscoveryListener {
            override fun onDiscoveryStarted(serviceType: String) {}
            override fun onDiscoveryStopped(serviceType: String) {}
            override fun onServiceLost(service: NsdServiceInfo) {}

            override fun onServiceFound(service: NsdServiceInfo) {
                main.post {
                    // NsdManager 同时只允许一个 resolve：Mac 在多块网卡上的同名广播
                    // 只解析第一份，局域网地址由 TXT 补齐。
                    if (service.serviceName != wanted || resolving) return@post
                    resolving = true
                    @Suppress("DEPRECATION")
                    nsd.resolveService(service, resolveListener)
                }
            }

            override fun onStartDiscoveryFailed(serviceType: String, errorCode: Int) {
                Log.w(TAG, "查找失败 $errorCode")
                main.post { discovery = null; finish() }
            }

            override fun onStopDiscoveryFailed(serviceType: String, errorCode: Int) {}
        }
        discovery = listener
        nsd.discoverServices(SERVICE_TYPE, NsdManager.PROTOCOL_DNS_SD, listener)
        main.postDelayed(timeout, timeoutMs.toLong())
    }

    private val resolveListener = object : NsdManager.ResolveListener {
        override fun onResolveFailed(service: NsdServiceInfo, errorCode: Int) {
            Log.w(TAG, "解析失败 ${service.serviceName} $errorCode")
            main.post { resolving = false }
        }

        override fun onServiceResolved(service: NsdServiceInfo) {
            main.post {
                if (service.serviceName != wanted) return@post
                val port = service.port
                service.attributes["ips"]?.let { String(it, Charsets.UTF_8) }
                    ?.split(",")?.filter { it.isNotEmpty() }
                    ?.forEach { add("$it:$port") }
                // 只取 IPv4：同步服务绑在 anyIPv4 上。
                @Suppress("DEPRECATION")
                (service.host as? Inet4Address)?.hostAddress?.let { add("$it:$port") }
                finish()
            }
        }
    }

    private fun add(addr: String) {
        if (!collected.contains(addr)) collected.add(addr)
    }

    private fun finish() {
        main.removeCallbacks(timeout)
        discovery?.let {
            try {
                nsd.stopServiceDiscovery(it)
            } catch (_: IllegalArgumentException) {
                // 查找没启动成功时 stop 会抛，忽略。
            }
        }
        discovery = null
        resolving = false
        wanted = null
        val value = if (collected.isEmpty()) null else collected.joinToString(",")
        collected.clear()
        pending?.let {
            pending = null
            it.success(value)
        }
    }
}
