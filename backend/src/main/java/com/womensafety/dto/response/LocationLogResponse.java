package com.womensafety.dto.response;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class LocationLogResponse {
    private Long id;
    private Long userId;
    private Double latitude;
    private Double longitude;
    private Double accuracy;
    private Double speed;
    private LocalDateTime timestamp;
}
