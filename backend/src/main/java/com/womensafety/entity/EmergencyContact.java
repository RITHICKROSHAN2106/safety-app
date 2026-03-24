package com.womensafety.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Emergency contact stored for each user.
 */
@Entity
@Table(name = "emergency_contacts")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class EmergencyContact {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;
    
    @Column(nullable = false)
    private String name;
    
    @Column(nullable = false)
    private String phone;
    
    @Column
    private String email;
    
    @Column
    private String relationship; // e.g., "Mother", "Friend", "Spouse"
    
    @Column(name = "is_primary")
    private Boolean isPrimary = false; // Mark one contact as primary
}
