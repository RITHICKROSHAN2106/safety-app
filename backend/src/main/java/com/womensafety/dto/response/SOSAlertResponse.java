package com.womensafety.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * DTO for SOS alert response.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SOSAlertResponse {
    private Long id;
    private Long userId;
    private String userName;
    private String userPhone;
    private Double latitude;
    private Double longitude;
    private String mediaUrl;
    private String status;
    private String triggerType;
    private String notes;
    private LocalDateTime timestamp;
    private LocalDateTime resolvedAt;
    private String resolvedBy;
}
