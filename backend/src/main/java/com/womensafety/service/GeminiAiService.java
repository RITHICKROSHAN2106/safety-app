package com.womensafety.service;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.womensafety.dto.request.AiChatRequest;
import com.womensafety.dto.response.AiChatResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Gemini proxy service for the safety assistant.
 */
@Service
public class GeminiAiService {
    private static final String SYSTEM_PROMPT = """
            You are the Women Safety App assistant.
            Your job is to give concise, practical, safety-first guidance for women, guardians, and emergency situations.
            Prioritize immediate safety, de-escalation, SOS steps, route safety, and contact escalation.
            Never provide harmful, illegal, or abusive instructions.
            If the user indicates immediate danger, tell them to call emergency services, trigger SOS, move to a public place, and contact trusted guardians.
            Keep responses short, clear, and actionable.
            When helpful, include up to 3 suggested follow-up replies.
            """;

    private final RestClient restClient;
    private final String apiKey;
    private final String model;
    private final double temperature;
    private final int maxOutputTokens;

    public GeminiAiService(
            RestClient.Builder restClientBuilder,
            @Value("${GEMINI_API_KEY:}") String apiKey,
            @Value("${GEMINI_MODEL:gemini-2.0-flash}") String model,
            @Value("${GEMINI_TEMPERATURE:0.4}") double temperature,
            @Value("${GEMINI_MAX_OUTPUT_TOKENS:512}") int maxOutputTokens) {
        this.restClient = restClientBuilder.build();
        this.apiKey = apiKey;
        this.model = model;
        this.temperature = temperature;
        this.maxOutputTokens = maxOutputTokens;
    }

    public AiChatResponse chat(AiChatRequest request) {
        if (apiKey == null || apiKey.isBlank()) {
            return AiChatResponse.builder()
                    .reply("Gemini is not configured on the backend yet. Set GEMINI_API_KEY to enable the AI assistant.")
                    .model(model)
                    .safetySensitive(true)
                    .escalationRecommended(false)
                    .suggestedReplies(List.of(
                            "How do I trigger SOS?",
                            "What should I do if I feel unsafe?",
                            "Help me make a safety plan"
                    ))
                    .timestamp(Instant.now())
                    .build();
        }

        final Map<String, Object> payload = buildPayload(request);
        final GeminiGenerateContentResponse response = restClient.post()
                .uri("https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={key}", model, apiKey)
                .contentType(MediaType.APPLICATION_JSON)
                .body(payload)
                .retrieve()
                .body(GeminiGenerateContentResponse.class);

        final String reply = extractReply(response);
        final boolean safetySensitive = isSafetySensitive(request, reply);

        return AiChatResponse.builder()
                .reply(reply)
                .model(model)
                .safetySensitive(safetySensitive)
                .escalationRecommended(safetySensitive)
                .suggestedReplies(buildSuggestedReplies(safetySensitive))
                .timestamp(Instant.now())
                .build();
    }

    private Map<String, Object> buildPayload(AiChatRequest request) {
        final Map<String, Object> payload = new HashMap<>();
        payload.put("systemInstruction", Map.of(
                "parts", List.of(Map.of("text", SYSTEM_PROMPT))
        ));
        payload.put("generationConfig", Map.of(
                "temperature", temperature,
                "maxOutputTokens", maxOutputTokens,
                "topP", 0.95,
                "topK", 32
        ));
        payload.put("contents", buildContents(request));

        return payload;
    }

    private List<Map<String, Object>> buildContents(AiChatRequest request) {
        final List<Map<String, Object>> contents = new ArrayList<>();

        if (request.getHistory() != null) {
            for (Map<String, String> item : request.getHistory()) {
                final String role = item.getOrDefault("role", "user");
                final String text = item.getOrDefault("text", "");
                if (!text.isBlank()) {
                    contents.add(Map.of(
                            "role", role,
                            "parts", List.of(Map.of("text", text))
                    ));
                }
            }
        }

        contents.add(Map.of(
                "role", "user",
                "parts", List.of(Map.of("text", buildUserPrompt(request)))
        ));

        return contents;
    }

    private String buildUserPrompt(AiChatRequest request) {
        final StringBuilder prompt = new StringBuilder();
        prompt.append("User message: ").append(request.getMessage().trim()).append('\n');

        if (request.getContext() != null && !request.getContext().isBlank()) {
            prompt.append("Context: ").append(request.getContext().trim()).append('\n');
        }
        if (request.getLocationLabel() != null && !request.getLocationLabel().isBlank()) {
            prompt.append("Location label: ").append(request.getLocationLabel().trim()).append('\n');
        }
        if (Boolean.TRUE.equals(request.getSosActive())) {
            prompt.append("Emergency state: active SOS. Prioritize immediate actions and escalation.\n");
        }
        if (request.getLatitude() != null && request.getLongitude() != null) {
            prompt.append("Coordinates: ").append(request.getLatitude()).append(", ").append(request.getLongitude()).append('\n');
        }

        return prompt.toString();
    }

    private String extractReply(GeminiGenerateContentResponse response) {
        if (response == null || response.candidates == null || response.candidates.isEmpty()) {
            return "I could not generate a response right now. Try again in a moment.";
        }

        final GeminiCandidate candidate = response.candidates.get(0);
        if (candidate.content == null || candidate.content.parts == null || candidate.content.parts.isEmpty()) {
            return "I could not generate a response right now. Try again in a moment.";
        }

        final StringBuilder text = new StringBuilder();
        for (GeminiPart part : candidate.content.parts) {
            if (part.text != null) {
                text.append(part.text);
            }
        }

        final String reply = text.toString().trim();
        return reply.isEmpty() ? "I could not generate a response right now. Try again in a moment." : reply;
    }

    private boolean isSafetySensitive(AiChatRequest request, String reply) {
        final String combined = (request.getMessage() + " " + reply).toLowerCase();
        return combined.contains("danger")
                || combined.contains("unsafe")
                || combined.contains("emergency")
                || combined.contains("sos")
                || combined.contains("police")
                || Boolean.TRUE.equals(request.getSosActive());
    }

    private List<String> buildSuggestedReplies(boolean safetySensitive) {
        if (safetySensitive) {
            return List.of(
                    "Trigger SOS now",
                    "Share my live location",
                    "Help me contact guardians"
            );
        }

        final List<String> suggestions = new ArrayList<>();
        suggestions.add("What should I do next?");
        suggestions.add("Make this safer");
        suggestions.add("Create a quick safety plan");
        return suggestions;
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class GeminiGenerateContentResponse {
        @JsonProperty("candidates")
        List<GeminiCandidate> candidates;
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class GeminiCandidate {
        @JsonProperty("content")
        GeminiContent content;
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class GeminiContent {
        @JsonProperty("parts")
        List<GeminiPart> parts;
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class GeminiPart {
        @JsonProperty("text")
        String text;
    }
}