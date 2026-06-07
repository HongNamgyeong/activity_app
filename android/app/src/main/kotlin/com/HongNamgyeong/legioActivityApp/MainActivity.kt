package com.HongNamgyeong.legioActivityApp

import android.content.Intent
import android.net.Uri
import android.provider.Settings
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
                "openAppSettings" -> {
                    openApplicationSettings()
                    result.success(null)
                }
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
                "cleanupDuplicateBackups" -> {
                    PublicBackupStorage.cleanupDuplicates(this)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun openApplicationSettings() {
        val intent = Intent(
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.fromParts("package", packageName, null),
        ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }

    companion object {
        const val BACKUP_CHANNEL = "com.HongNamgyeong.legioActivityApp/backup"
    }
}
