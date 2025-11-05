import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Service to call Firebase Cloud Functions
class CloudFunctionService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Trigger a critical alert for a target user
  /// 
  /// [targetUserId] - The UID of the student for whom to trigger the alert
  /// 
  /// Returns a map with:
  /// - success: bool
  /// - alertId: string (unique alert identifier)
  /// - message: string
  /// - sentCount: int (number of devices alerts were sent to)
  /// - failedCount: int (number of failed sends)
  static Future<Map<String, dynamic>> triggerCriticalAlert({
    required String targetUserId,
  }) async {
    try {
      debugPrint('Calling Cloud Function to trigger alert for user: $targetUserId');
      
      final callable = _functions.httpsCallable('triggerCriticalAlert');
      final result = await callable.call({
        'targetUserId': targetUserId,
      });

      final data = result.data as Map<String, dynamic>;
      debugPrint('Cloud Function response: $data');
      
      return data;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Cloud Function error: ${e.code} - ${e.message}');
      throw _handleCloudFunctionError(e);
    } catch (e) {
      debugPrint('Unexpected error calling Cloud Function: $e');
      rethrow;
    }
  }

  /// Handle and convert Cloud Function errors to user-friendly messages
  static Exception _handleCloudFunctionError(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'invalid-argument':
        return Exception('Invalid request. Please check the target user ID.');
      case 'unauthenticated':
        return Exception('You must be logged in to trigger alerts.');
      case 'not-found':
        return Exception('Target user not found.');
      case 'failed-precondition':
        return Exception('Cannot trigger alert: ${e.message ?? 'Precondition failed'}');
      case 'permission-denied':
        return Exception('You do not have permission to trigger this alert.');
      case 'internal':
        return Exception('Server error. Please try again later.');
      default:
        return Exception(e.message ?? 'An error occurred while triggering the alert.');
    }
  }
}

