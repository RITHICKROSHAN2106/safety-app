package com.womensafety.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.womensafety.entity.User;
import com.womensafety.repository.LocationLogRepository;
import com.womensafety.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class LocationControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private LocationLogRepository locationLogRepository;

    @BeforeEach
    void setUp() {
        locationLogRepository.deleteAll();
        userRepository.deleteAll();

        User user = User.builder()
                .name("Location User")
                .email("location@womensafety.com")
                .phone("7777777777")
                .password("secret")
                .build();

        userRepository.save(user);
    }

    @Test
    @WithMockUser(username = "location@womensafety.com")
    void postLocation_storesLocationInH2() throws Exception {
        Map<String, Object> request = Map.of(
                "latitude", 12.975,
                "longitude", 77.61,
                "accuracy", 8.5,
                "speed", 0.0
        );

        mockMvc.perform(post("/api/v1/location")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.latitude").value(12.975));

        assertThat(locationLogRepository.count()).isEqualTo(1);
    }

    @Test
    @WithMockUser(username = "location@womensafety.com")
    void getMyLocations_returnsHistory() throws Exception {
        postLocation_storesLocationInH2();

        mockMvc.perform(get("/api/v1/location/my"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.length()").value(1));
    }
}
