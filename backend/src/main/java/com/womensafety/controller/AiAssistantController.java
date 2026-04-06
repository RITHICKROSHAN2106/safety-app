package com.womensafety.controller;

import com.womensafety.dto.request.AiChatRequest;
import com.womensafety.dto.response.AiChatResponse;
import com.womensafety.dto.response.ApiResponse;
import com.womensafety.service.GeminiAiService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Gemini-backed AI assistant endpoints.
 */
@RestController
@RequestMapping("/api/v1/ai")
@RequiredArgsConstructor
@Tag(name = "AI Assistant", description = "Gemini-powered safety assistant")
public class AiAssistantController {
    private final GeminiAiService geminiAiService;

    @PostMapping("/chat")
    @Operation(summary = "Chat with Gemini", description = "Generate safety-focused AI guidance")
    public ResponseEntity<ApiResponse<AiChatResponse>> chat(
            @RequestHeader(value = "Authorization", required = false) String authorization,
            @Valid @RequestBody AiChatRequest request) {

        final String backendApiKey = System.getenv("BACKEND_API_KEY");

        if (backendApiKey != null && !backendApiKey.isBlank()) {
            final String expectedHeader = "Bearer " + backendApiKey;
            if (authorization == null || !expectedHeader.equals(authorization.trim())) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                        .body(ApiResponse.error("Invalid backend API key"));
            }
        }

        final AiChatResponse response = geminiAiService.chat(request);
        return ResponseEntity.ok(ApiResponse.success("Gemini response generated", response));
    }
}