package com.womensafety.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

/**
 * SOS Alert entity representing emergency alerts triggered by users.
 */
@Entity
@Table(name = "sos_alerts")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SOSAlert {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;
    
    @Column(nullable = false)
    private Double latitude;
    
    @Column(nullable = false)
    private Double longitude;
    
    @Column(name = "media_url")
    private String mediaUrl; // URL to uploaded video/audio evidence
    
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private AlertStatus status = AlertStatus.ACTIVE;
    
    @Column(name = "trigger_type")
    private String triggerType; // e.g., "BUTTON", "SHAKE", "VOICE"
    
    @Column(length = 1000)
    private String notes;
    
    @CreationTimestamp
    @Column(name = "created_at", updatable = false, nullable = false)
    private LocalDateTime timestamp;
    
    @Column(name = "resolved_at")
    private LocalDateTime resolvedAt;
    
    @Column(name = "resolved_by")
    private String resolvedBy; // Admin username who resolved
    
    public enum AlertStatus {
        ACTIVE, RESOLVED, FALSE_ALARM
    }
}
