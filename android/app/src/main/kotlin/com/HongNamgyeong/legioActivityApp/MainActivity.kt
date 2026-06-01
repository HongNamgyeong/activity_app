package com.HongNamgyeong.legioActivityApp

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            BACKUP_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "writePublicBackup" -> {
                    val content = call.argument<String>("content")
                    if (content.isNullOrEmpty()) {
                        result.success(false)
                        return@setMethodCallHandler
                    }
                    result.success(PublicBackupStorage.write(this, content))
                }
                "readPublicBackup" -> {
                    result.success(PublicBackupStorage.read(this))
                }
                "publicBackupExists" -> {
                    result.success(PublicBackupStorage.exists(this))
                }
                else -> result.notImplemented()
            }
        }
    }

    companion object {
        const val BACKUP_CHANNEL = "com.HongNamgyeong.legioActivityApp/backup"
    }
}
