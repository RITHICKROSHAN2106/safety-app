package com.womensafety.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

/**
 * DTO for creating an SOS alert.
 */
@Data
public class SOSAlertRequest {
    
    @NotNull(message = "Latitude is required")
    private Double latitude;
    
    @NotNull(message = "Longitude is required")
    private Double longitude;
    
    private String mediaUrl;
    
    @NotBlank(message = "Trigger type is required")
    private String triggerType; // BUTTON, SHAKE, VOICE
    
    private String notes;
}
