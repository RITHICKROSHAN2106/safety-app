package com.womensafety.repository;

import com.womensafety.entity.LocationLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * Repository for LocationLog entity operations.
 */
@Repository
public interface LocationLogRepository extends JpaRepository<LocationLog, Long> {
    
    List<LocationLog> findByUserIdOrderByTimestampDesc(Long userId);
    
    @Query("SELECT l FROM LocationLog l WHERE l.user.id = :userId " +
           "ORDER BY l.timestamp DESC LIMIT 1")
    Optional<LocationLog> findLatestByUserId(@Param("userId") Long userId);
    
    @Query("SELECT l FROM LocationLog l WHERE l.user.id = :userId " +
           "AND l.timestamp BETWEEN :start AND :end ORDER BY l.timestamp")
    List<LocationLog> findUserRouteBetween(@Param("userId") Long userId,
                                          @Param("start") LocalDateTime start,
                                          @Param("end") LocalDateTime end);
}
