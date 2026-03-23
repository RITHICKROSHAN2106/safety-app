package com.womensafety.service;

import com.google.firebase.messaging.*;
import com.womensafety.entity.EmergencyContact;
import com.womensafety.entity.SOSAlert;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * Service for sending push notifications via Firebase Cloud Messaging.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class NotificationService {
    
    /**
     * Send FCM notifications to emergency contacts when SOS is triggered.
     */
    public void notifyEmergencyContacts(SOSAlert alert, List<EmergencyContact> contacts) {
        String title = "🚨 SOS Alert from " + alert.getUser().getName();
        String body = String.format("Emergency at: %.6f, %.6f. Please respond immediately!", 
                alert.getLatitude(), alert.getLongitude());
        
        contacts.forEach(contact -> {
            log.info("Notifying emergency contact: {} ({}) about alert {}", 
                    contact.getName(), contact.getPhone(), alert.getId());
            
            // In production: send SMS via Twilio/Fast2SMS
            // sendSMS(contact.getPhone(), body);
            
            // Send push notification if contact has FCM token (future enhancement)
            // sendPushNotification(contact.getFcmToken(), title, body);
        });
        
        // Notify admin dashboard (future: WebSocket)
        log.info("SOS Alert {} broadcasted to admin dashboard", alert.getId());
    }
    
    /**
     * Send FCM push notification to specific token.
     */
    public void sendPushNotification(String fcmToken, String title, String body) {
        if (fcmToken == null || fcmToken.isBlank()) {
            log.warn("FCM token is null or empty, skipping notification");
            return;
        }
        
        try {
            Message message = Message.builder()
                    .setToken(fcmToken)
                    .setNotification(Notification.builder()
                            .setTitle(title)
                            .setBody(body)
                            .build())
                    .putData("type", "SOS_ALERT")
                    .setAndroidConfig(AndroidConfig.builder()
                            .setPriority(AndroidConfig.Priority.HIGH)
                            .build())
                    .setApnsConfig(ApnsConfig.builder()
                            .setAps(Aps.builder()
                                    .setSound("default")
                                    .build())
                            .build())
                    .build();
            
            String response = FirebaseMessaging.getInstance().send(message);
            log.info("Successfully sent FCM message: {}", response);
            
        } catch (FirebaseMessagingException e) {
            log.error("Error sending FCM notification: {}", e.getMessage());
        }
    }
    
    /**
     * Send broadcast notification to all users (admin feature).
     */
    public void sendBroadcastNotification(String title, String message) {
        log.info("Broadcasting notification: {} - {}", title, message);
        // Implementation: fetch all FCM tokens and send in batch
    }
}
