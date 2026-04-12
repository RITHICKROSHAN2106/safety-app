# 🔐 Fake Call & Safety Check-In Features - Complete Guide

## Table of Contents
1. [Fake Call Service](#fake-call-service)
2. [Safety Check-In Service](#safety-check-in-service)
3. [Integration & Usage](#integration--usage)
4. [Technical Architecture](#technical-architecture)
5. [User Flows](#user-flows)

---

## 🎭 Fake Call Service

### Overview
The **Fake Call Service** creates a realistic incoming call UI to help users escape dangerous or uncomfortable situations. It simulates an incoming call from a trusted contact (customizable) with haptic vibration and ringtone audio, providing a discreet exit strategy.

### Key Features

#### 1. **Customizable Caller Identity**
- Set custom caller name (default: "Mom")
- Set custom phone number (default: "+91 98765 43210")
- Optional caller image/profile picture
- Personalize based on emergency contact preferences

#### 2. **Multi-Sensory Experience**
- **Visual:** Full-screen incoming call UI with caller info
- **Audio:** Realistic ringtone via AlarmService (WAV synthesis fallback)
- **Haptics:** Phone vibration in ring pattern (1s vibration, 0.5s pause, repeat)
- Ensures fake call is noticed even in noisy environments

#### 3. **Auto-Answer Feature**
- Optional auto-answer after customizable delay
- Example: Auto-answer after 3 seconds for seamless escape experience
- Can be triggered from volume button or notification quick action

#### 4. **Multiple Trigger Points**
- **Manual:** From a button in the app
- **Volume Button:** Long press (3+ seconds) for discrete trigger
- **Notification:** Quick action for background activation
- **Scheduled:** Can be triggered after a specified delay

#### 5. **State Management**
- Prevents multiple simultaneous fake calls (`_isCallActive` flag)
- Proper cleanup on call end (stops vibration, cancels timers, stops audio)
- Error handling to prevent service crashes

### How It Works

#### Trigger Flow
```
1. User initiates fake call (button/volume/notification)
   ↓
2. Service checks if call already active
   ↓
3. Starts vibration pattern (periodic 1s vibrations)
   ↓
4. Plays ringtone via AlarmService
   ↓
5. Opens fake call screen (full-screen dialog)
   ↓
6. User can accept/decline call or let auto-answer trigger
   ↓
7. On screen close, stops vibration and audio
```

#### Code Structure

**Main Service Class: `FakeCallService`**
- `triggerFakeCall()` - Main entry point with caller customization
- `_startVibrationPattern()` - Handles vibration ring pattern
- `_playRingtone()` - Reuses AlarmService for audio
- `stopFakeCall()` - Cleanup method
- `scheduleFakeCall()` - Delayed trigger
- `triggerFromVolumeButton()` - Volume button handler
- `triggerFromNotification()` - Notification quick action handler

**UI Component: `FakeCallScreen`**
- Displays caller name, number, and optional image
- Accept/Decline buttons
- Auto-answer countdown timer
- Professional calling interface

### Integration Points

#### 1. **With AlarmService**
```dart
// Fake call uses AlarmService for ringtone
await AlarmService.startAlarm();  // Start ringtone
await AlarmService.stopAlarm();   // Stop ringtone
```
- Leverages existing audio synthesis (WAV generation)
- Ensures audio works even without custom assets
- Maintains consistency with SOS siren audio

#### 2. **With Vibration Package**
```dart
import 'package:vibration/vibration.dart';

// Check device capability
final hasVibrator = await Vibration.hasVibrator();

// Ring pattern
await Vibration.vibrate(duration: 1000);  // 1 second vibration
await Vibration.cancel();                 // Stop vibration
```

#### 3. **With Navigation**
```dart
// Opens as full-screen dialog
await Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => FakeCallScreen(...),
    fullscreenDialog: true,
  ),
);
```

### Usage Examples

#### Basic Fake Call
```dart
await FakeCallService.triggerFakeCall(
  context: context,
  callerName: 'Mom',
  callerNumber: '+91 98765 43210',
);
```

#### With Auto-Answer
```dart
await FakeCallService.triggerFakeCall(
  context: context,
  callerName: 'Dad',
  callerNumber: '+91 87654 32109',
  autoAnswerAfter: const Duration(seconds: 3),
);
```

#### From Volume Button
```dart
await FakeCallService.triggerFromVolumeButton(context);
```

#### Scheduled Call
```dart
await FakeCallService.scheduleFakeCall(
  delay: const Duration(seconds: 10),
  context: context,
  callerName: 'Emergency Contact',
);
```

### Safety Considerations

✅ **Private & Discreet**
- No emergency service involvement
- No actual calls made
- Silent activation from volume button or notification

✅ **Non-Intrusive**
- Doesn't interfere with actual incoming calls
- Can be stopped anytime by user
- Proper state management prevents conflicts

✅ **Privacy Preserving**
- All caller info is customizable
- No data sharing with external services
- Works completely offline

### User Scenarios

| Scenario | Trigger | Caller | Auto-Answer |
|----------|---------|--------|-------------|
| Uncomfortable conversation | App button | "Mom" | No - wait for approach |
| Crowded public place | Volume button | "Emergency Contact" | Yes - 5s |
| While being followed | Notification | "Dad" | Yes - 3s |
| Need immediate exit | Scheduled | Custom contact | Yes - 1s |

---

## ⏱️ Safety Check-In Service

### Overview
The **Safety Check-In Service** maintains a recurring timer that requires users to confirm they're safe at regular intervals. If a user doesn't confirm within a grace period, it triggers an escalation callback (typically SOS emergency protocol).

Perfect for:
- Solo travel or commutes
- Late-night activities
- High-risk situations
- Continuous monitoring while in transit

### Key Features

#### 1. **Configurable Timer**
- Default interval: 10 minutes
- Customizable to any duration
- Counts down from interval to zero
- Real-time state updates via stream

#### 2. **Grace Period Mechanism**
- Default grace period: 45 seconds
- When timer expires, user enters "Awaiting Confirmation" state
- User has grace-period duration to tap "I'm Safe" button
- If grace expires, escalation callback is triggered

#### 3. **State Management**
- Tracks 4 states simultaneously:
  - `isActive`: Service running
  - `awaitingConfirmation`: User needs to confirm
  - `remainingSeconds`: Time until confirmation needed
  - `graceRemainingSeconds`: Time remaining to confirm
- Race condition guard: `_tickInProgress` prevents concurrent timer ticks

#### 4. **Stream-Based Updates**
```dart
// Subscribe to state changes
SafetyCheckInService.updates.listen((state) {
  // Update UI with countdown
  // Show alert when grace period starts
  // Disable buttons during transitions
});
```

#### 5. **Smart Notification Handling**
- Shows notification when check-in required
- Includes grace period countdown (e.g., "45 seconds")
- Tap to confirm directly from notification
- Automatic cleanup of old notifications

#### 6. **Escalation Callback**
```dart
// Pass custom callback for missed check-in
await SafetyCheckInService.start(
  onMissedCheckIn: () async {
    // Trigger SOS protocol
    // Alert guardians
    // Log incident
  },
);
```

### How It Works

#### State Diagram
```
┌─────────────────────────────────────────┐
│         INIT state: isActive = false    │
└─────────────┬───────────────────────────┘
              │ start()
              ↓
┌─────────────────────────────────────────┐
│  Timer running: remainingSeconds = 600  │
│  (Normal countdown state)               │
│  isActive = true                        │
│  awaitingConfirmation = false           │
└──────────────┬──────────────────────────┘
               │ remainingSeconds → 0
               ↓
┌─────────────────────────────────────────┐
│  Check-In Required: awaitingConfirmation │
│  graceRemainingSeconds = 45             │
│  Show notification                      │
│  isActive = true                        │
└──────────────┬──────────────────────────┘
      ↙                          ↘
   Check-in                   Grace
  Confirmed?                  Expired?
   ↙                            ↘
confirmSafe()              onMissedCheckIn()
   │                            │
   ↓                            ↓
Timer Reset              Escalation
(600s again)             Triggered
   │                            │
   └────────────┬───────────────┘
                ↓
     (Loop back to normal state
      or stop() if escalation)
```

#### Timer Tick Logic

**Every 1 second:**

1. **Check if tick in progress** → Return if `_tickInProgress` is true
2. **Enter critical section** → Set `_tickInProgress = true`
3. **Verify service still active** → Return if service stopped
4. **Handle two scenarios:**
   - **Awaiting Confirmation**: Decrement grace timer, check if expired
   - **Normal State**: Decrement countdown, check if check-in needed
5. **Emit state update** → All listeners receive new state
6. **Exit critical section** → Set `_tickInProgress = false`

This guard prevents race conditions where multiple ticks could overlap.

### Code Structure

**Main Service Class: `SafetyCheckInService`**
- Static-only pattern (no instantiation needed)
- `start()` - Initialize with custom interval/grace period
- `confirmSafe()` - User confirms they're safe
- `stop()` - Stop service and cleanup
- `updates` - Stream for state changes
- `currentState` - Get current state synchronously

**State Class: `CheckInState`**
```dart
class CheckInState {
  final bool isActive;                // Service running?
  final bool awaitingConfirmation;    // User needs to confirm?
  final int remainingSeconds;         // Main countdown
  final int graceRemainingSeconds;    // Grace period countdown
}
```

### Integration Points

#### 1. **With NotificationService**
```dart
// Show check-in notification
await NotificationService.showNotification(
  title: 'Safety Check-In',
  body: 'Tap I\'m Safe within 45s to avoid emergency escalation.',
  id: 45001,
);

// Cancel after confirmation
await NotificationService.cancelNotification(45001);
```

#### 2. **With Stream for UI Updates**
```dart
// In build method
StreamBuilder<CheckInState>(
  stream: SafetyCheckInService.updates,
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final state = snapshot.data!;
      return Column(
        children: [
          Text('Time remaining: ${state.remainingSeconds}s'),
          if (state.awaitingConfirmation)
            ElevatedButton(
              onPressed: () => SafetyCheckInService.confirmSafe(),
              child: Text('I\'m Safe'),
            ),
        ],
      );
    }
    return const SizedBox.shrink();
  },
)
```

#### 3. **With SOS System**
```dart
// Start check-in with SOS escalation
await SafetyCheckInService.start(
  interval: const Duration(minutes: 10),
  gracePeriod: const Duration(seconds: 45),
  onMissedCheckIn: () async {
    // Trigger full SOS protocol
    await GlobalSOSManager.triggerEmergency(
      source: 'check-in-timeout',
      reason: 'Safety check-in not confirmed',
    );
  },
);
```

### Usage Examples

#### Start with Custom Timer
```dart
await SafetyCheckInService.start(
  interval: const Duration(minutes: 5),        // Check-in every 5 min
  gracePeriod: const Duration(seconds: 30),   // 30 seconds to confirm
  onMissedCheckIn: () async {
    // Handle escalation
    print('Check-in missed! Triggering SOS...');
  },
);
```

#### Subscribe to State Changes
```dart
SafetyCheckInService.updates.listen((state) {
  print('Check-in state: ${state.remainingSeconds}s remaining');
  
  if (state.awaitingConfirmation) {
    print('⚠️ User must confirm within ${state.graceRemainingSeconds}s');
  }
});
```

#### Manual Confirmation
```dart
// When user taps "I'm Safe" button
await SafetyCheckInService.confirmSafe();
// Timer resets to full interval
```

#### Stop Service
```dart
await SafetyCheckInService.stop();
// Service deactivates, all timers canceled
```

### Safety Lifecycle

#### Example: 10-min Travel Scenario

```
T+0:00   → Service starts, 600s countdown begins
T+5:00   → State update: 300s remaining
T+9:45   → State update: 15s remaining (almost time)
T+10:00  → Timer expires → awaitingConfirmation = true
         → Grace period: 45s countdown starts
         → Notification sent: "Tap I'm Safe within 45s"
T+10:20  → User taps "I'm Safe" button
         → confirmSafe() called
         → Timer resets to 600s
         → awaitingConfirmation = false
         → New countdown cycle begins
T+20:00  → Second check-in required
...
T+40:00  → User forgets to confirm 😟
         → 45s grace period elapses
         → onMissedCheckIn() callback fires
         → SOS triggered, guardians notified
```

### User Scenarios

| Scenario | Interval | Grace | Escalation |
|----------|----------|-------|------------|
| Solo commute (10 min) | 10 min | 45 sec | SOS alert |
| Late-night travel | 5 min | 30 sec | SOS + location share |
| Night out with friends | 15 min | 60 sec | Notify guardians |
| Emergency safety check | 2 min | 15 sec | Immediate SOS |

---

## 🔗 Integration & Usage

### In Main App Flow

```dart
// In app initialization (main.dart or home screen)
if (isSafetyModeEnabled) {
  // Start check-in timer
  await SafetyCheckInService.start(
    interval: const Duration(minutes: 10),
    onMissedCheckIn: () async {
      await GlobalSOSManager.triggerEmergency(
        source: 'check-in-timeout',
        reason: 'Safety check-in not confirmed',
      );
    },
  );
}

// Make fake call available from multiple screens
FlatButton(
  onPressed: () => FakeCallService.triggerFakeCall(
    context: context,
    callerName: 'Mom',
  ),
  child: const Text('Fake Incoming Call'),
),
```

### Volume Button Long Press Detection

```dart
// In home screen or main widget
@override
Widget build(BuildContext context) {
  return RawKeyboardListener(
    focusNode: FocusNode(),
    onKey: (event) {
      if (event.isKeyPressed(LogicalKeyboardKey.audioVolumeUp)) {
        if (volumeLongPressDetected) {  // 3+ seconds
          FakeCallService.triggerFromVolumeButton(context);
        }
      }
    },
    child: Scaffold(...),
  );
}
```

### Notification Quick Action

```dart
// In notification_service.dart
// When user taps check-in notification
void _onNotificationTapped(NotificationResponse response) {
  if (response.id == 45001) {  // Check-in notification
    SafetyCheckInService.confirmSafe();
  } else if (response.actionId == 'fake_call_action') {
    FakeCallService.triggerFromNotification(context);
  }
}
```

---

## 🏗️ Technical Architecture

### Service Isolation

Both services follow singleton/static pattern:
- **No instantiation required** - Use `FakeCallService.method()` and `SafetyCheckInService.method()`
- **Global state management** - Static variables for timers, flags
- **Broadcast streams** - Multiple listeners supported
- **Clean shutdown** - Proper cleanup on stop/dispose

### Resource Management

**FakeCallService**
- Uses `Timer` for vibration scheduling
- Streams through `Navigator` (short-lived)
- Cleans up timers on completion

**SafetyCheckInService**
- Uses single `Timer` for all counting
- `StreamController.broadcast()` for unlimited listeners
- Race condition guard (`_tickInProgress`)
- Proper stream disposal on stop

### Error Handling

**Try-Catch Wrapping**
```dart
try {
  // Critical operation
} catch (e) {
  debugPrint('❌ Error: $e');
} finally {
  // Always cleanup
}
```

**Graceful Degradation**
- Missing vibrator? Service still works (no haptics)
- Missing audio file? Uses WAV synthesis fallback
- Notification service unavailable? Check-in still counts

### Performance Considerations

✅ **Lightweight Timer**
- Single `Timer.periodic()` for check-in (1 tick/second)
- No background isolates required
- ~100ms CPU per tick

✅ **Memory Efficient**
- Broadcast stream with weak listener references
- Timer cleaned up after service stops
- No persistent file operations

✅ **Battery Friendly**
- No GPS polling
- Minimal CPU during idle countdown
- Optional vibration/audio (can be disabled)

---

## 📋 Feature Comparison

| Feature | Fake Call | Check-In |
|---------|-----------|----------|
| **Purpose** | Escape dangerous situation | Passive continuous monitoring |
| **Duration** | One-time use | Recurring/ongoing |
| **User Action** | Instant activation | Periodic confirmation |
| **Escalation** | None (deception only) | SOS trigger on miss |
| **Audio?** | Yes (ringtone) | Only notification |
| **Vibration?** | Yes (ring pattern) | No |
| **Customizable?** | Caller name/number/image | Interval/grace/callback |
| **Multiple Concurrent?** | No (only one at a time) | Yes (with other services) |
| **Triggers** | Button/Volume/Notification/Scheduled | Timer only |
| **UI** | Full-screen call dialog | Stream-based status |

---

## ✅ Testing Checklist

### Fake Call Service
- [ ] Basic trigger with default settings
- [ ] Custom caller name and number
- [ ] Caller image display
- [ ] Vibration pattern (feel distinct from other vibrations)
- [ ] Ringtone plays and stops
- [ ] Auto-answer timer works
- [ ] Volume button trigger (test long-press detection)
- [ ] Notification quick action
- [ ] Stop fake call (cleanup)
- [ ] No duplicate simultaneous calls

### Safety Check-In Service
- [ ] Timer starts and counts down
- [ ] Notification appears at timer expiry
- [ ] Grace period starts and counts down
- [ ] User can confirm "I'm Safe"
- [ ] Timer resets after confirmation
- [ ] Escalation callback fires if grace expires
- [ ] Stream updates in real-time
- [ ] Service stops cleanly
- [ ] Multiple listeners work (StreamBuilder, etc.)
- [ ] No race conditions (tick-in-progress guard)

---

## 🚀 Future Enhancements

### Fake Call Service
- [ ] Incoming SMS simulation
- [ ] Multiple call duration options
- [ ] Call recording simulation (fake voice memo)
- [ ] Customizable ringtones per contact
- [ ] WhatsApp/Telegram message simulations

### Safety Check-In Service
- [ ] Progressive escalation (notify guardian → SOS)
- [ ] Snooze functionality (delay next check-in)
- [ ] Location check-in (must be in safe location)
- [ ] Different check-in intervals based on risk level
- [ ] Statistics dashboard (check-in history)

---

## 📞 Summary

**Fake Call Service** = Social Engineering for Safety
- Instant one-tap escape from uncomfortable situations
- Customizable caller identity
- Multi-sensory experience (visual + audio + haptic)
- Perfect for discretely getting away

**Safety Check-In Service** = Passive Monitoring with Escalation
- Recurring timer ensures continued safety confirmation
- Grace period prevents hair-trigger escalations
- SOS trigger on missed check-in
- Perfect for solo travel or high-risk activities

Both services work independently or together as part of the comprehensive Women Safety App ecosystem.
