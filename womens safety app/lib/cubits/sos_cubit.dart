/// SOS Cubit
/// Manages SOS alert state and operations
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/sos_log_model.dart';
import '../models/guardian_model.dart';
import '../services/sos_service.dart';

// SOS States
abstract class SosState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SosInitial extends SosState {}

class SosCountdown extends SosState {
  final int remainingSeconds;

  SosCountdown(this.remainingSeconds);

  @override
  List<Object?> get props => [remainingSeconds];
}

class SosTriggering extends SosState {}

class SosTriggered extends SosState {
  final SosLog sosLog;

  SosTriggered(this.sosLog);

  @override
  List<Object?> get props => [sosLog];
}

class SosCancelled extends SosState {}

class SosError extends SosState {
  final String message;

  SosError(this.message);

  @override
  List<Object?> get props => [message];
}

class SosHistoryLoaded extends SosState {
  final List<SosLog> history;

  SosHistoryLoaded(this.history);

  @override
  List<Object?> get props => [history];
}

// SOS Cubit
class SosCubit extends Cubit<SosState> {
  final SosService _sosService = SosService();

  SosCubit() : super(SosInitial()) {
    _listenToCountdown();
  }

  // Listen to countdown stream
  void _listenToCountdown() {
    _sosService.countdownStream.listen((countdown) {
      if (countdown > 0) {
        emit(SosCountdown(countdown));
      }
    });
  }

  // Start SOS countdown
  void startSosCountdown() {
    _sosService.startCountdown(
      onComplete: () {
        // Countdown completed - trigger SOS
        // Actual trigger happens when user confirms
      },
      onCancel: () {
        emit(SosCancelled());
      },
    );
  }

  // Cancel SOS countdown
  void cancelSos() {
    _sosService.cancelCountdown();
    _sosService.stopAlarm();
    emit(SosCancelled());
  }

  // Trigger SOS alert
  Future<void> triggerSos({
    required String userId,
    required String userName,
    required List<Guardian> guardians,
  }) async {
    try {
      emit(SosTriggering());

      // Trigger full SOS alert
      final sosLog = await _sosService.triggerSosAlert(
        userId: userId,
        userName: userName,
        guardians: guardians,
      );

      emit(SosTriggered(sosLog));

      // Auto-navigate back to initial after 5 seconds
      await Future.delayed(const Duration(seconds: 5));
      await _sosService.stopAlarm();
      emit(SosInitial());
    } catch (e) {
      emit(SosError('Failed to trigger SOS: $e'));
      await Future.delayed(const Duration(seconds: 3));
      emit(SosInitial());
    }
  }

  // Load SOS history
  Future<void> loadSosHistory(String userId) async {
    try {
      final history = await _sosService.getSosHistory(userId);
      emit(SosHistoryLoaded(history));
    } catch (e) {
      emit(SosError('Failed to load SOS history'));
    }
  }

  // Update SOS status
  Future<void> updateSosStatus(String sosId, String status) async {
    try {
      await _sosService.updateSosStatus(sosId, status);
    } catch (e) {
      emit(SosError('Failed to update SOS status'));
    }
  }

  // Make emergency call
  Future<void> makeEmergencyCall(String phoneNumber) async {
    try {
      await _sosService.makeEmergencyCall(phoneNumber);
    } catch (e) {
      emit(SosError('Failed to make emergency call'));
    }
  }

  @override
  Future<void> close() {
    _sosService.dispose();
    return super.close();
  }
}
