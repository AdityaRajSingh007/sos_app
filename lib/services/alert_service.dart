import 'package:flutter/services.dart';
import 'dart:convert';

/// Service to trigger critical alerts via platform channel
class AlertService {
  static const platform = MethodChannel('com.adityarajsingh.sos_app/critical_alert');

  /// Trigger a critical alert on the device
  /// This calls the native Android service that bypasses DND and plays alarm
  static Future<void> triggerCriticalAlert() async {
    try {
      await platform.invokeMethod('startCriticalAlert');
    } on PlatformException catch (e) {
      // Log error but don't throw - this allows the app to continue
      // The error will be handled by the calling code if needed
      print('Error triggering critical alert: ${e.message}');
      rethrow;
    }
  }

  /// Stop a currently active critical alert
  static Future<void> stopCriticalAlert() async {
    try {
      await platform.invokeMethod('stopCriticalAlert');
    } on PlatformException catch (e) {
      print('Error stopping critical alert: ${e.message}');
      rethrow;
    }
  }
}

