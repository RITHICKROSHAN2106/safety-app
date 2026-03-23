import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import '../../models/app_user.dart';
import '../../models/guardian.dart';
import '../../models/sos_alert.dart';
import '../../services/alarm_service.dart';
import '../../services/sos_service.dart';

class SOSState {
  final bool isTriggered;
  final bool isLoading;
  final String? error;
  final SOSAlert? activeAlert;
  final String? triggerType;

  const SOSState({
    this.isTriggered = false,
    this.isLoading = false,
    this.error,
    this.activeAlert,
    this.triggerType,
  });

  SOSState copyWith({
    bool? isTriggered,
    bool? isLoading,
    String? error,
    SOSAlert? activeAlert,
    String? triggerType,
  }) {
    return SOSState(
      isTriggered: isTriggered ?? this.isTriggered,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      activeAlert: activeAlert ?? this.activeAlert,
      triggerType: triggerType ?? this.triggerType,
    );
  }
}

class SosCubit extends Cubit<SOSState> {
  SosCubit() : super(const SOSState());

  /// Trigger SOS with full emergency actions
  Future<void> triggerSOS({
    required AppUser user,
    required List<Guardian> emergencyContacts,
    String triggerType = 'BUTTON',
    bool recordVideo = true,
    bool makeCall = true,
    bool playAlarm = true,
  }) async {
    if (state.isLoading) {
      debugPrint('⚠️ SOS already in progress');
      return;
    }

    try {
      // Set loading state
      emit(state.copyWith(
        isLoading: true,
        isTriggered: false,
        error: null,
        triggerType: triggerType,
      ));

      debugPrint('🚨 Triggering SOS from Cubit...');

      // Validate emergency contacts
      if (emergencyContacts.isEmpty) {
        emit(state.copyWith(
          isLoading: false,
          error: 'No emergency contacts configured',
        ));
        return;
      }

      // Call SOS Service
      final alert = await SOSService.triggerSOS(
        user: user,
        emergencyContacts: emergencyContacts,
        triggerType: triggerType,
        recordVideo: recordVideo,
        makeCall: makeCall,
        playAlarm: playAlarm,
      );

      if (alert != null) {
        // Success
        emit(state.copyWith(
          isLoading: false,
          isTriggered: true,
          activeAlert: alert,
          error: null,
        ));
        debugPrint('✅ SOS triggered successfully');
      } else {
        // Failure
        emit(state.copyWith(
          isLoading: false,
          error: 'Failed to trigger SOS. Please try again.',
        ));
        debugPrint('❌ SOS trigger failed');
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Error: ${e.toString()}',
      ));
      debugPrint('❌ SOS Cubit Error: $e');
    }
  }

  /// Cancel active SOS alert
  Future<void> cancelSOS() async {
    if (state.activeAlert == null) {
      debugPrint('⚠️ No active SOS alert to cancel');
      return;
    }

    try {
      emit(state.copyWith(isLoading: true));

      final success = await SOSService.cancelAlert(state.activeAlert!.id ?? '');

      if (success) {
        emit(const SOSState()); // Reset to initial state
        debugPrint('✅ SOS cancelled');
      } else {
        emit(state.copyWith(
          isLoading: false,
          error: 'Failed to cancel SOS',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Error cancelling SOS: ${e.toString()}',
      ));
      debugPrint('❌ Cancel SOS Error: $e');
    } finally {
      AlarmService.stopAlarm();
    }
  }

  /// Get active alerts
  Future<void> fetchActiveAlerts() async {
    try {
      final alerts = await SOSService.getActiveAlerts();
      if (alerts.isNotEmpty) {
        emit(state.copyWith(
          activeAlert: alerts.first,
          isTriggered: true,
        ));
      }
    } catch (e) {
      debugPrint('❌ Fetch active alerts error: $e');
    }
  }

  /// Reset SOS state
  void reset() {
    emit(const SOSState());
  }
}
