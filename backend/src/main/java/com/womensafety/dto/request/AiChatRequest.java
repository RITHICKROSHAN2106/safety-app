package com.womensafety.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

import java.util.List;
import java.util.Map;

/**
 * Request payload for Gemini-backed safety chat.
 */
@Data
public class AiChatRequest {
    @NotBlank(message = "Message is required")
    private String message;

    private String context;
    private String locationLabel;
    private Boolean sosActive;
    private Double latitude;
    private Double longitude;
    private List<Map<String, String>> history;
}