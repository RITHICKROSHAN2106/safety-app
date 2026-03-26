package com.womensafety.service;

import com.womensafety.dto.request.LocationLogRequest;
import com.womensafety.dto.response.LocationLogResponse;
import com.womensafety.entity.LocationLog;
import com.womensafety.entity.User;
import com.womensafety.repository.LocationLogRepository;
import com.womensafety.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class LocationService {

    private final LocationLogRepository locationLogRepository;
    private final UserRepository userRepository;

    public LocationLogResponse logLocation(Long userId, LocationLogRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        LocationLog locationLog = LocationLog.builder()
                .user(user)
                .latitude(request.getLatitude())
                .longitude(request.getLongitude())
                .accuracy(request.getAccuracy())
                .speed(request.getSpeed())
                .build();

        locationLog = locationLogRepository.save(locationLog);
        return mapToResponse(locationLog);
    }

    public List<LocationLogResponse> getUserLocations(Long userId) {
        return locationLogRepository.findByUserIdOrderByTimestampDesc(userId)
                .stream()
                .map(this::mapToResponse)
                .toList();
    }

    private LocationLogResponse mapToResponse(LocationLog log) {
        return LocationLogResponse.builder()
                .id(log.getId())
                .userId(log.getUser().getId())
                .latitude(log.getLatitude())
                .longitude(log.getLongitude())
                .accuracy(log.getAccuracy())
                .speed(log.getSpeed())
                .timestamp(log.getTimestamp())
                .build();
    }
}
