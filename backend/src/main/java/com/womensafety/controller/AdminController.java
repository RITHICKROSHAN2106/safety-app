package com.womensafety.controller;

import com.womensafety.dto.response.ApiResponse;
import com.womensafety.service.NotificationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * Controller for admin operations.
 */
@RestController
@RequestMapping("/api/v1/admin")
@RequiredArgsConstructor
@SecurityRequirement(name = "Bearer Authentication")
@Tag(name = "Admin", description = "Admin dashboard operations")
@PreAuthorize("hasRole('ADMIN')")
public class AdminController {
    
    private final NotificationService notificationService;
    
    @PostMapping("/notify")
    @Operation(summary = "Send broadcast notification", description = "Send notification to all users")
    public ResponseEntity<ApiResponse<String>> sendBroadcast(
            @RequestParam String title,
            @RequestParam String message) {
        
        notificationService.sendBroadcastNotification(title, message);
        return ResponseEntity.ok(ApiResponse.success("Broadcast sent successfully"));
    }
}
