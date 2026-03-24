package com.xjanova.aipray

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.xjanova.aipray/installer"
    private var pendingInstallResult: MethodChannel.Result? = null

    private lateinit var installPermissionLauncher: ActivityResultLauncher<Intent>

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register permission result launcher
        installPermissionLauncher = registerForActivityResult(
            ActivityResultContracts.StartActivityForResult()
        ) { _ ->
            // Re-check permission after user returns from settings
            val granted = canRequestInstallPackages()
            pendingInstallResult?.success(granted)
            pendingInstallResult = null
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "installApk" -> {
                        val filePath = call.argument<String>("filePath")
                        if (filePath != null) {
                            installApk(filePath, result)
                        } else {
                            result.error("INVALID_ARG", "filePath is required", null)
                        }
                    }
                    "canRequestInstall" -> {
                        result.success(canRequestInstallPackages())
                    }
                    "requestInstallPermission" -> {
                        requestInstallPermission(result)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun installApk(filePath: String, result: MethodChannel.Result) {
        try {
            val file = File(filePath)
            if (!file.exists()) {
                result.error("FILE_NOT_FOUND", "APK file not found: $filePath", null)
                return
            }

            val uri: Uri = FileProvider.getUriForFile(
                this,
                "${applicationContext.packageName}.fileprovider",
                file
            )

            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "application/vnd.android.package-archive")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }

            startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("INSTALL_FAILED", e.message, null)
        }
    }

    private fun canRequestInstallPackages(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            packageManager.canRequestPackageInstalls()
        } else {
            true
        }
    }

    private fun requestInstallPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            pendingInstallResult = result
            val intent = Intent(
                Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                Uri.parse("package:$packageName")
            )
            installPermissionLauncher.launch(intent)
        } else {
            result.success(true)
        }
    }
}
