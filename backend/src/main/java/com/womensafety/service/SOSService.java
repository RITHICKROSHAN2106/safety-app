package com.womensafety.service;

import com.womensafety.dto.request.SOSAlertRequest;
import com.womensafety.dto.response.SOSAlertResponse;
import com.womensafety.entity.EmergencyContact;
import com.womensafety.entity.SOSAlert;
import com.womensafety.entity.User;
import com.womensafety.repository.EmergencyContactRepository;
import com.womensafety.repository.SOSAlertRepository;
import com.womensafety.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Service for handling SOS alerts and notifications.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class SOSService {
    
    private final SOSAlertRepository sosAlertRepository;
    private final UserRepository userRepository;
    private final EmergencyContactRepository emergencyContactRepository;
    private final NotificationService notificationService;
    
    @Transactional
    public SOSAlertResponse createAlert(Long userId, SOSAlertRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));
        
        SOSAlert alert = SOSAlert.builder()
                .user(user)
                .latitude(request.getLatitude())
                .longitude(request.getLongitude())
                .mediaUrl(request.getMediaUrl())
                .triggerType(request.getTriggerType())
                .notes(request.getNotes())
                .status(SOSAlert.AlertStatus.ACTIVE)
                .build();
        
        alert = sosAlertRepository.save(alert);
        log.info("SOS Alert created: {} for user: {}", alert.getId(), userId);
        
        // Send notifications to emergency contacts
        List<EmergencyContact> contacts = emergencyContactRepository.findByUserId(userId);
        notificationService.notifyEmergencyContacts(alert, contacts);
        
        return mapToResponse(alert);
    }
    
    public List<SOSAlertResponse> getActiveAlerts() {
        return sosAlertRepository.findActiveAlerts().stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }
    
    public List<SOSAlertResponse> getUserAlerts(Long userId) {
        return sosAlertRepository.findByUserId(userId).stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }
    
    @Transactional
    public SOSAlertResponse resolveAlert(Long alertId, String resolvedBy) {
        SOSAlert alert = sosAlertRepository.findById(alertId)
                .orElseThrow(() -> new RuntimeException("Alert not found"));
        
        alert.setStatus(SOSAlert.AlertStatus.RESOLVED);
        alert.setResolvedAt(LocalDateTime.now());
        alert.setResolvedBy(resolvedBy);
        
        alert = sosAlertRepository.save(alert);
        log.info("SOS Alert resolved: {} by: {}", alertId, resolvedBy);
        
        return mapToResponse(alert);
    }
    
    private SOSAlertResponse mapToResponse(SOSAlert alert) {
        return SOSAlertResponse.builder()
                .id(alert.getId())
                .userId(alert.getUser().getId())
                .userName(alert.getUser().getName())
                .userPhone(alert.getUser().getPhone())
                .latitude(alert.getLatitude())
                .longitude(alert.getLongitude())
                .mediaUrl(alert.getMediaUrl())
                .status(alert.getStatus().name())
                .triggerType(alert.getTriggerType())
                .notes(alert.getNotes())
                .timestamp(alert.getTimestamp())
                .resolvedAt(alert.getResolvedAt())
                .resolvedBy(alert.getResolvedBy())
                .build();
    }
}
