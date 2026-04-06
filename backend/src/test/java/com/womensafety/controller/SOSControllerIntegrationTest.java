package com.womensafety.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.womensafety.entity.EmergencyContact;
import com.womensafety.entity.SOSAlert;
import com.womensafety.entity.User;
import com.womensafety.repository.EmergencyContactRepository;
import com.womensafety.repository.SOSAlertRepository;
import com.womensafety.repository.UserRepository;
import com.womensafety.service.NotificationService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.Mockito.doNothing;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class SOSControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private EmergencyContactRepository emergencyContactRepository;

    @Autowired
    private SOSAlertRepository sosAlertRepository;

    @SuppressWarnings("removal")
    @MockBean
    private NotificationService notificationService;

    @BeforeEach
    void setUp() {
        sosAlertRepository.deleteAll();
        emergencyContactRepository.deleteAll();
        userRepository.deleteAll();

        doNothing().when(notificationService).notifyEmergencyContacts(any(SOSAlert.class), anyList());

        User user = User.builder()
                .name("Test User")
                .email("test@womensafety.com")
                .phone("9999999999")
                .password("secret")
                .build();

        user = userRepository.save(user);

        EmergencyContact contact = new EmergencyContact();
        contact.setUser(user);
        contact.setName("Guardian One");
        contact.setPhone("8888888888");
        contact.setEmail("guardian@example.com");
        contact.setRelationship("friend");
        contact.setIsPrimary(true);
        emergencyContactRepository.save(contact);
    }

    @Test
    @WithMockUser(username = "test@womensafety.com")
    void createSosAlert_persistsAndReturnsResponse() throws Exception {
        Map<String, Object> request = Map.of(
                "latitude", 12.9716,
                "longitude", 77.5946,
                "triggerType", "BUTTON",
                "notes", "Integration test"
        );

        mockMvc.perform(post("/api/v1/sos")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.status").value("ACTIVE"))
                .andExpect(jsonPath("$.data.triggerType").value("BUTTON"));

        assertThat(sosAlertRepository.count()).isEqualTo(1);
    }

    @Test
    @WithMockUser(username = "test@womensafety.com")
    void getMyAlerts_returnsStoredAlerts() throws Exception {
        createSosAlert_persistsAndReturnsResponse();

        mockMvc.perform(get("/api/v1/sos/my-alerts"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.length()").value(1));
    }
}
