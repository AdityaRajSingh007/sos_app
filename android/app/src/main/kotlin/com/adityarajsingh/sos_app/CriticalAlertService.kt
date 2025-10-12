package com.adityarajsingh.sos_app

import android.app.*
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat

class CriticalAlertService : Service() {

    private var mediaPlayer: MediaPlayer? = null
    private val NOTIFICATION_ID = 1
    private val CHANNEL_ID = "CriticalAlertChannel"
    private val AUTO_STOP_DELAY = 60000L // 1 minute in milliseconds
    private var autoStopHandler: Handler? = null
    private var autoStopRunnable: Runnable? = null


    private fun startCriticalAlert() {
        try {
            // Maximize alarm volume
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_ALARM)
            audioManager.setStreamVolume(AudioManager.STREAM_ALARM, maxVolume, 0)

            // Play alarm sound
            mediaPlayer = MediaPlayer.create(this, R.raw.alarm_sound)
            mediaPlayer?.isLooping = true
            mediaPlayer?.start()

            // Create the full-screen intent
            val fullScreenIntent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("from_critical_alert", true)
            }
            val fullScreenPendingIntent = PendingIntent.getActivity(
                this, 0, fullScreenIntent, 
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            // Create dismiss intent
            val dismissIntent = Intent(this, CriticalAlertService::class.java).apply {
                action = "DISMISS_ALERT"
            }
            val dismissPendingIntent = PendingIntent.getService(
                this, 1, dismissIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val notification = NotificationCompat.Builder(this, CHANNEL_ID)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle("🚨 EMERGENCY ALERT 🚨")
                .setContentText("This is a critical emergency alert. Tap to acknowledge.")
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setCategory(NotificationCompat.CATEGORY_ALARM)
                .setFullScreenIntent(fullScreenPendingIntent, true)
                .addAction(R.mipmap.ic_launcher, "DISMISS", dismissPendingIntent)
                .setOngoing(true)
                .setAutoCancel(false)
                .build()

            startForeground(NOTIFICATION_ID, notification)

            // Auto-stop after 1 minute
            autoStopHandler = Handler(Looper.getMainLooper())
            autoStopRunnable = Runnable {
                stopCriticalAlert()
            }
            autoStopHandler?.postDelayed(autoStopRunnable!!, AUTO_STOP_DELAY)

        } catch (e: Exception) {
            // If there's an error, stop the service
            stopSelf()
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            "DISMISS_ALERT" -> {
                stopCriticalAlert()
                return START_NOT_STICKY
            }
            else -> {
                createNotificationChannel()
                startCriticalAlert()
                return START_STICKY
            }
        }
    }

    private fun stopCriticalAlert() {
        try {
            // Stop media player
            mediaPlayer?.stop()
            mediaPlayer?.release()
            mediaPlayer = null

            // Cancel auto-stop
            autoStopHandler?.removeCallbacks(autoStopRunnable!!)
            autoStopHandler = null
            autoStopRunnable = null

            // Stop foreground service
            stopForeground(true)
            stopSelf()
        } catch (e: Exception) {
            // Force stop even if there's an error
            stopSelf()
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "Critical Alert Channel",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Channel for critical emergency alerts"
                enableLights(true)
                enableVibration(true)
                setShowBadge(true)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(serviceChannel)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        stopCriticalAlert()
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
}
