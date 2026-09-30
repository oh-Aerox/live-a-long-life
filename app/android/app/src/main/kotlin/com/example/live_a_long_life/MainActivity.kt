package com.example.live_a_long_life

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

// FlutterFragmentActivity：health 插件用 registerForActivityResult 申请
// Health Connect 权限，要求宿主是 ComponentActivity。
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        MedicalTextChannel.register(messenger, applicationContext)
        BonjourChannel.register(messenger, applicationContext)
        AndroidSettingsChannel.register(messenger, this)
    }
}
