package com.womensafety.repository;

import com.womensafety.entity.SOSAlert;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Repository for SOSAlert entity operations.
 */
@Repository
public interface SOSAlertRepository extends JpaRepository<SOSAlert, Long> {
    
    List<SOSAlert> findByStatus(SOSAlert.AlertStatus status);
    
    List<SOSAlert> findByUserId(Long userId);
    
    @Query("SELECT s FROM SOSAlert s WHERE s.status = 'ACTIVE' ORDER BY s.timestamp DESC")
    List<SOSAlert> findActiveAlerts();
    
    @Query("SELECT s FROM SOSAlert s WHERE s.timestamp BETWEEN :start AND :end")
    List<SOSAlert> findAlertsBetween(@Param("start") LocalDateTime start, 
                                     @Param("end") LocalDateTime end);
    
    @Query("SELECT COUNT(s) FROM SOSAlert s WHERE s.status = :status")
    Long countByStatus(@Param("status") SOSAlert.AlertStatus status);
}
