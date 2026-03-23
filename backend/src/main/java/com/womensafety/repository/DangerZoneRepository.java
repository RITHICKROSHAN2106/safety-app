package com.womensafety.repository;

import com.womensafety.entity.DangerZone;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * Repository for DangerZone entity operations.
 */
@Repository
public interface DangerZoneRepository extends JpaRepository<DangerZone, Long> {
    
    List<DangerZone> findByIsActiveTrue();
    
    @Query("SELECT d FROM DangerZone d WHERE d.isActive = true " +
           "AND d.threatLevel IN ('HIGH', 'CRITICAL')")
    List<DangerZone> findHighThreatZones();
}
