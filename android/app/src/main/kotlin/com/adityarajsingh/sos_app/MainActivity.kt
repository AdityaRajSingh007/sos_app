package com.adityarajsingh.sos_app

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.adityarajsingh.sos_app/critical_alert"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startCriticalAlert" -> {
                    // Check for DND permission first
                    val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !notificationManager.isNotificationPolicyAccessGranted) {
                        val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
                        startActivity(intent)
                        result.error("PERMISSION_DENIED", "DND permission not granted. Please grant notification policy access.", null)
                    } else {
                        // Check for audio settings permission
                        if (ContextCompat.checkSelfPermission(this, android.Manifest.permission.MODIFY_AUDIO_SETTINGS) 
                            != PackageManager.PERMISSION_GRANTED) {
                            ActivityCompat.requestPermissions(this, 
                                arrayOf(android.Manifest.permission.MODIFY_AUDIO_SETTINGS), 1001)
                            result.error("AUDIO_PERMISSION_DENIED", "Audio settings permission required for volume control. Please grant permission.", null)
                        } else {
                            try {
                                val serviceIntent = Intent(this, CriticalAlertService::class.java)
                                startService(serviceIntent)
                                result.success("Critical alert started successfully")
                            } catch (e: Exception) {
                                result.error("SERVICE_ERROR", "Failed to start critical alert service: ${e.message}", null)
                            }
                        }
                    }
                }
                "stopCriticalAlert" -> {
                    try {
                        val serviceIntent = Intent(this, CriticalAlertService::class.java)
                        stopService(serviceIntent)
                        result.success("Critical alert stopped successfully")
                    } catch (e: Exception) {
                        result.error("SERVICE_ERROR", "Failed to stop critical alert service: ${e.message}", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
