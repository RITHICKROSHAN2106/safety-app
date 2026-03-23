package com.womensafety.controller;

import com.womensafety.dto.request.SOSAlertRequest;
import com.womensafety.dto.response.ApiResponse;
import com.womensafety.dto.response.SOSAlertResponse;
import com.womensafety.entity.User;
import com.womensafety.repository.UserRepository;
import com.womensafety.service.SOSService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Controller for SOS alert operations.
 */
@RestController
@RequestMapping("/api/v1/sos")
@RequiredArgsConstructor
@SecurityRequirement(name = "Bearer Authentication")
@Tag(name = "SOS Alerts", description = "Emergency alert management")
public class SOSController {
    
    private final SOSService sosService;
    private final UserRepository userRepository;
    
    @PostMapping
    @Operation(summary = "Create SOS alert", description = "Trigger emergency alert with location")
    public ResponseEntity<ApiResponse<SOSAlertResponse>> createAlert(
            @Valid @RequestBody SOSAlertRequest request,
            Authentication authentication) {
        
        // Extract user ID from authentication (email-based)
        Long userId = getUserIdFromAuth(authentication);
        SOSAlertResponse response = sosService.createAlert(userId, request);
        
        return ResponseEntity.ok(ApiResponse.success("SOS alert created successfully", response));
    }
    
    @GetMapping("/active")
    @Operation(summary = "Get active alerts", description = "List all active SOS alerts")
    public ResponseEntity<ApiResponse<List<SOSAlertResponse>>> getActiveAlerts() {
        List<SOSAlertResponse> alerts = sosService.getActiveAlerts();
        return ResponseEntity.ok(ApiResponse.success(alerts));
    }
    
    @GetMapping("/my-alerts")
    @Operation(summary = "Get user alerts", description = "Get all alerts for current user")
    public ResponseEntity<ApiResponse<List<SOSAlertResponse>>> getUserAlerts(Authentication authentication) {
        Long userId = getUserIdFromAuth(authentication);
        List<SOSAlertResponse> alerts = sosService.getUserAlerts(userId);
        return ResponseEntity.ok(ApiResponse.success(alerts));
    }
    
    @PutMapping("/{alertId}/resolve")
    @Operation(summary = "Resolve alert", description = "Mark alert as resolved (Admin only)")
    public ResponseEntity<ApiResponse<SOSAlertResponse>> resolveAlert(
            @PathVariable Long alertId,
            Authentication authentication) {
        
        String resolvedBy = authentication.getName();
        SOSAlertResponse response = sosService.resolveAlert(alertId, resolvedBy);
        
        return ResponseEntity.ok(ApiResponse.success("Alert resolved successfully", response));
    }
    
    // Helper method to extract user ID from authentication
    private Long getUserIdFromAuth(Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) {
            throw new RuntimeException("User not authenticated");
        }

        String email = authentication.getName();
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found: " + email));

        return user.getId();
    }
}
