package com.womensafety.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Predefined danger zones with threat levels for risk analysis.
 */
@Entity
@Table(name = "danger_zones")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DangerZone {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(nullable = false)
    private String name;
    
    @Column(nullable = false)
    private Double latitude;
    
    @Column(nullable = false)
    private Double longitude;
    
    @Column(nullable = false)
    private Double radius; // Danger zone radius in meters
    
    @Enumerated(EnumType.STRING)
    @Column(name = "threat_level", nullable = false)
    private ThreatLevel threatLevel;
    
    @Column(length = 500)
    private String description;
    
    @Column(name = "is_active")
    @Builder.Default
    private Boolean isActive = true;
    
    public enum ThreatLevel {
        LOW, MEDIUM, HIGH, CRITICAL
    }
}
