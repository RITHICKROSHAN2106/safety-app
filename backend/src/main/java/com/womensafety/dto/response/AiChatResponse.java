package com.womensafety.dto.response;

import lombok.Builder;
import lombok.Data;

import java.time.Instant;
import java.util.List;

/**
 * Response payload for Gemini-backed safety chat.
 */
@Data
@Builder
public class AiChatResponse {
    private String reply;
    private String model;
    private Boolean safetySensitive;
    private Boolean escalationRecommended;
    private List<String> suggestedReplies;
    private Instant timestamp;
}