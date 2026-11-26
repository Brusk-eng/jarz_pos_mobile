package com.example.jarz_pos

import android.content.Intent
import android.os.Bundle
import android.view.KeyEvent
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.plugins.util.GeneratedPluginRegister
import io.flutter.plugin.common.MethodChannel

/**
 * Entry activity of the Studio flavours. Same behaviour as the POS MainActivity,
 * but a FlutterFragmentActivity because local_auth (BiometricPrompt) needs a
 * FragmentActivity. Also hosts the biometric guard channel.
 */
class StudioMainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        OrderAlertChannel.storeLaunchPayload(intent?.extras)
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        OrderAlertChannel.storeLaunchPayload(intent.extras)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GeneratedPluginRegister.registerGeneratedPlugins(flutterEngine)
        flutterEngine.plugins.add(ClassicPrinterChannel())
        flutterEngine.plugins.add(OrderAlertChannel())
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WhatsAppShareChannel.CHANNEL)
            .setMethodCallHandler(WhatsAppShareChannel(this))
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, StudioBiometricGuard.CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "arm" -> result.success(StudioBiometricGuard.arm())
                    "isValid" -> result.success(StudioBiometricGuard.isValid())
                    "disarm" -> {
                        StudioBiometricGuard.disarm()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (event.action == KeyEvent.ACTION_DOWN &&
            (event.keyCode == KeyEvent.KEYCODE_VOLUME_DOWN || event.keyCode == KeyEvent.KEYCODE_VOLUME_UP || event.keyCode == KeyEvent.KEYCODE_VOLUME_MUTE)
        ) {
            if (OrderAlertNative.isVolumeLocked()) {
                return true
            }
        }
        return super.dispatchKeyEvent(event)
    }
}
