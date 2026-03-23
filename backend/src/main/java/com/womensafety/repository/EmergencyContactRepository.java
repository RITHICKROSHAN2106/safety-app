package com.womensafety.repository;

import com.womensafety.entity.EmergencyContact;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * Repository for EmergencyContact entity operations.
 */
@Repository
public interface EmergencyContactRepository extends JpaRepository<EmergencyContact, Long> {
    
    List<EmergencyContact> findByUserId(Long userId);
}
