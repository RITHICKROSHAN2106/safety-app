package com.womensafety.controller;

import com.womensafety.dto.request.LocationLogRequest;
import com.womensafety.dto.response.ApiResponse;
import com.womensafety.dto.response.LocationLogResponse;
import com.womensafety.entity.User;
import com.womensafety.repository.UserRepository;
import com.womensafety.service.LocationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/location")
@RequiredArgsConstructor
@SecurityRequirement(name = "Bearer Authentication")
@Tag(name = "Location", description = "Location tracking endpoints")
public class LocationController {

    private final LocationService locationService;
    private final UserRepository userRepository;

    @PostMapping
    @Operation(summary = "Log location", description = "Stores user location point")
    public ResponseEntity<ApiResponse<LocationLogResponse>> logLocation(
            @Valid @RequestBody LocationLogRequest request,
            Authentication authentication
    ) {
        Long userId = getUserIdFromAuth(authentication);
        LocationLogResponse response = locationService.logLocation(userId, request);
        return ResponseEntity.ok(ApiResponse.success("Location saved", response));
    }

    @GetMapping("/my")
    @Operation(summary = "Get my locations", description = "Returns user location history")
    public ResponseEntity<ApiResponse<List<LocationLogResponse>>> myLocations(Authentication authentication) {
        Long userId = getUserIdFromAuth(authentication);
        List<LocationLogResponse> response = locationService.getUserLocations(userId);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

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
