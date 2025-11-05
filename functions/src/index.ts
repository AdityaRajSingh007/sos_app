/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import * as admin from "firebase-admin";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";

// Initialize Firebase Admin
admin.initializeApp();

// Get Firestore and Messaging instances
const db = admin.firestore();
const messaging = admin.messaging();

/**
 * HTTP Callable Function to trigger a critical alert for a student
 *
 * @param data - Must contain {targetUserId: string}
 * @param context - Firebase Auth context (automatically provided)
 * @returns Success message with alert ID
 */
export const triggerCriticalAlert = onCall(
  {
    maxInstances: 10,
    // Allow unauthenticated calls for testing
    // TODO: Re-enable authentication for production
    cors: true,
    invoker: "public", // Allow unauthenticated access
  },
  async (request) => {
    try {
      const {targetUserId} = request.data;

      // Validate input
      if (!targetUserId || typeof targetUserId !== "string") {
        throw new HttpsError(
          "invalid-argument",
          "targetUserId is required and must be a string"
        );
      }

      // For testing: Allow unauthenticated requests
      // const requesterId = request.auth?.uid || "anonymous";
      const requesterId = request.auth?.uid || "test_user";
      logger.info(
        `Trigger alert requested by ${requesterId} for ${targetUserId}`
      );

      // Generate unique alert ID
      const alertId = db.collection("_").doc().id; // Generate a unique ID

      // Fetch target user document
      const targetUserDoc = await db
        .collection("users")
        .doc(targetUserId)
        .get();

      if (!targetUserDoc.exists) {
        throw new HttpsError("not-found", "Target user not found");
      }

      const targetUserData = targetUserDoc.data();
      if (!targetUserData) {
        throw new HttpsError("not-found", "Target user data not found");
      }

      // Get assigned responders
      const assignedResponders = targetUserData.assignedResponders || [];

      if (
        !Array.isArray(assignedResponders) ||
        assignedResponders.length === 0
      ) {
        throw new HttpsError(
          "failed-precondition",
          "Target user has no assigned responders"
        );
      }

      logger.info(
        `Found ${assignedResponders.length} assigned responders ` +
        `for user ${targetUserId}`
      );

      // Fetch FCM tokens for all assigned responders
      const responderTokens: string[] = [];
      const responderPromises = assignedResponders.map(
        async (responderId: string) => {
          try {
            const responderDoc = await db
              .collection("users")
              .doc(responderId)
              .get();
            if (responderDoc.exists) {
              const responderData = responderDoc.data();
              if (responderData && responderData.fcmToken) {
                responderTokens.push(responderData.fcmToken);
              }
            }
          } catch (error) {
            logger.error(
              `Error fetching responder ${responderId}:`,
              error
            );
          }
        }
      );

      await Promise.all(responderPromises);

      if (responderTokens.length === 0) {
        throw new HttpsError(
          "failed-precondition",
          "No valid FCM tokens found for assigned responders"
        );
      }

      logger.info(`Sending alerts to ${responderTokens.length} devices`);

      // Prepare student information payload
      const alertPayload = {
        alertId,
        type: "critical_alert",
        studentInfo: {
          uid: targetUserData.uid,
          fullName: targetUserData.fullName,
          email: targetUserData.email,
          contact: targetUserData.contact,
          guardianContact: targetUserData.guardianContact,
          enrollmentNumber: targetUserData.enrollmentNumber,
          accommodationType: targetUserData.accommodationType,
          hostelWingAndRoom: targetUserData.hostelWingAndRoom || null,
          permanentHomeAddress: targetUserData.permanentHomeAddress,
          medicalInfo: targetUserData.medicalInfo || {},
        },
        triggeredBy: requesterId || "anonymous",
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      };

      // Send FCM messages to all responders
      const message: admin.messaging.MulticastMessage = {
        tokens: responderTokens,
        data: {
          alertId,
          type: "critical_alert",
          // Stringify nested objects for FCM data messages
          studentInfo: JSON.stringify(alertPayload.studentInfo),
          triggeredBy: requesterId || "anonymous",
        },
        android: {
          priority: "high" as const,
        },
        apns: {
          headers: {
            "apns-priority": "10",
          },
          payload: {
            aps: {
              sound: "default",
              contentAvailable: true,
            },
          },
        },
      };

      const response = await messaging.sendEachForMulticast(message);

      logger.info(
        `Successfully sent ${response.successCount} alerts, ` +
        `${response.failureCount} failed`
      );

      // Log failures if any
      if (response.failureCount > 0) {
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            logger.error(
              `Failed to send to token ${responderTokens[idx]}:`,
              resp.error
            );
          }
        });
      }

      return {
        success: true,
        alertId,
        message: "Alert triggered successfully. " +
          `Sent to ${response.successCount} device(s).`,
        sentCount: response.successCount,
        failedCount: response.failureCount,
      };
    } catch (error) {
      if (error instanceof HttpsError) {
        throw error;
      }
      logger.error("Error in triggerCriticalAlert:", error);
      throw new HttpsError(
        "internal",
        "An error occurred while triggering the alert"
      );
    }
  }
);
