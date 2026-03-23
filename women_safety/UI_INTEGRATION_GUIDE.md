# 🎨 UI Integration Guide for New Features

This guide shows how to integrate the three new revolutionary services into your UI.

---

## 1. Guardian Live Tracking UI

### Track Active SOS Location

```dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/guardian_tracking_service.dart';

class LiveTrackingScreen extends StatelessWidget {
  final String trackingSessionId;

  const LiveTrackingScreen({required this.trackingSessionId});

  @override
  Widget build(BuildContext context) {
    final trackingService = GuardianTrackingService();

    return Scaffold(
      appBar: AppBar(title: Text('Live Location Tracking')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: trackingService.getTrackingStream(trackingSessionId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data();
          if (data == null) return Center(child: Text('No data'));

          final currentLocation = data['currentLocation'];
          final status = data['status'];
          final acknowledgments = data['acknowledgments'] ?? {};

          return Column(
            children: [
              // Status banner
              Container(
                padding: EdgeInsets.all(16),
                color: status == 'active' ? Colors.red : Colors.green,
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      status == 'active' ? 'SOS ACTIVE' : 'SOS ENDED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Current location
              ListTile(
                leading: Icon(Icons.my_location),
                title: Text('Current Location'),
                subtitle: Text(
                  'Lat: ${currentLocation['latitude'].toStringAsFixed(6)}\n'
                  'Lng: ${currentLocation['longitude'].toStringAsFixed(6)}',
                ),
              ),

              Divider(),

              // Guardian acknowledgments
              Text('Guardian Status:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ...acknowledgments.entries.map((entry) {
                final phone = entry.key;
                final ack = entry.value;
                return ListTile(
                  leading: Icon(
                    ack['acknowledged'] ? Icons.check_circle : Icons.pending,
                    color: ack['acknowledged'] ? Colors.green : Colors.orange,
                  ),
                  title: Text(ack['guardianName'] ?? phone),
                  subtitle: Text(phone),
                );
              }).toList(),

              Spacer(),

              // Acknowledge button (for guardian view)
              if (status == 'active')
                ElevatedButton.icon(
                  onPressed: () async {
                    await trackingService.acknowledgeAlert(
                      trackingSessionId: trackingSessionId,
                      guardianPhone: '+1234567890', // Get from user profile
                      guardianName: 'John Doe', // Get from user profile
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Acknowledged! User will be notified.')),
                    );
                  },
                  icon: Icon(Icons.check),
                  label: Text('I\'m On My Way'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
```

---

## 2. Evidence Capture UI

### Show Evidence Status During SOS

```dart
import 'package:flutter/material.dart';
import '../services/evidence_capture_service.dart';

class EvidenceCaptureWidget extends StatefulWidget {
  @override
  _EvidenceCaptureWidgetState createState() => _EvidenceCaptureWidgetState();
}

class _EvidenceCaptureWidgetState extends State<EvidenceCaptureWidget> {
  final evidenceService = EvidenceCaptureService();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.videocam, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Evidence Capture Active',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // Audio recording indicator
            _buildStatusRow(
              icon: Icons.mic,
              label: 'Audio Recording',
              isActive: evidenceService.isCapturing,
            ),
            
            // Photo capture indicator
            _buildStatusRow(
              icon: Icons.camera_alt,
              label: 'Photo Capture',
              isActive: evidenceService.isCapturing,
            ),
            
            // Encryption indicator
            _buildStatusRow(
              icon: Icons.lock,
              label: 'Encrypted Storage',
              isActive: true,
            ),
            
            SizedBox(height: 8),
            Text(
              'All evidence is encrypted and timestamped for legal protection',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow({
    required IconData icon,
    required String label,
    required bool isActive,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isActive ? Colors.green : Colors.grey,
          ),
          SizedBox(width: 8),
          Text(label),
          Spacer(),
          if (isActive)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'ACTIVE',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }
}
```

---

## 3. Safe Journey Mode UI

### Start Journey Screen

```dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/safe_journey_service.dart';
import '../models/app_user.dart';

class StartJourneyScreen extends StatefulWidget {
  final AppUser user;
  final List<String> guardianPhones;

  const StartJourneyScreen({
    required this.user,
    required this.guardianPhones,
  });

  @override
  _StartJourneyScreenState createState() => _StartJourneyScreenState();
}

class _StartJourneyScreenState extends State<StartJourneyScreen> {
  final _destinationController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedETA = DateTime.now().add(Duration(hours: 1));
  Map<String, double>? _destinationCoords;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Start Safe Journey')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.directions_car, size: 40, color: Colors.blue),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Safe Journey Mode',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Share your journey with guardians',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Destination input
            Text('Destination', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            TextField(
              controller: _destinationController,
              decoration: InputDecoration(
                hintText: 'Enter destination address',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 16),

            // ETA picker
            Text('Expected Arrival Time', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(_selectedETA),
                );
                if (time != null) {
                  setState(() {
                    _selectedETA = DateTime(
                      _selectedETA.year,
                      _selectedETA.month,
                      _selectedETA.day,
                      time.hour,
                      time.minute,
                    );
                  });
                }
              },
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time),
                    SizedBox(width: 16),
                    Text(
                      '${_selectedETA.hour.toString().padLeft(2, '0')}:${_selectedETA.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Notes
            Text('Additional Notes (Optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: 'e.g., Taking metro, will call when I arrive',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),

            SizedBox(height: 24),

            // Features info
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What happens during your journey:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    _buildFeatureItem('📍 Live location tracking every 30 seconds'),
                    _buildFeatureItem('⏰ Check-in reminders every 10 minutes'),
                    _buildFeatureItem('🚨 Auto-alert if route deviation detected'),
                    _buildFeatureItem('⌚ Alert if you don\'t arrive by ETA'),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Start button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _startJourney,
                icon: Icon(Icons.play_arrow),
                label: Text('Start Journey', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Text(text, style: TextStyle(fontSize: 14)),
    );
  }

  Future<void> _startJourney() async {
    if (_destinationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a destination')),
      );
      return;
    }

    try {
      // Get current location
      final currentPosition = await Geolocator.getCurrentPosition();

      // In production, geocode destination address to coordinates
      // For now, use placeholder coordinates
      final destinationCoords = {
        'latitude': 28.6139,
        'longitude': 77.2090,
      };

      final journeyService = SafeJourneyService();
      final journeyId = await journeyService.startJourney(
        userId: widget.user.id,
        userName: widget.user.name,
        startLocation: {
          'latitude': currentPosition.latitude,
          'longitude': currentPosition.longitude,
          'timestamp': DateTime.now().toIso8601String(),
        },
        destinationLocation: destinationCoords,
        destinationName: _destinationController.text,
        estimatedArrival: _selectedETA,
        guardianPhones: widget.guardianPhones,
        notes: _notesController.text,
      );

      // Navigate to active journey screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ActiveJourneyScreen(journeyId: journeyId),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting journey: $e')),
      );
    }
  }
}

class ActiveJourneyScreen extends StatelessWidget {
  final String journeyId;

  const ActiveJourneyScreen({required this.journeyId});

  @override
  Widget build(BuildContext context) {
    final journeyService = SafeJourneyService();

    return Scaffold(
      appBar: AppBar(
        title: Text('Active Journey'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: journeyService.getJourneyStream(journeyId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data();
          if (data == null) return Center(child: Text('No data'));

          final status = data['status'];
          final alerts = List.from(data['alerts'] ?? []);
          final checkIns = List.from(data['checkIns'] ?? []);

          return Column(
            children: [
              // Status banner
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                color: Colors.green,
                child: Text(
                  'Journey in Progress',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Alerts
              if (alerts.isNotEmpty)
                Container(
                  color: Colors.orange.shade100,
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: alerts.map((alert) {
                      return Text('⚠️ ${alert['message']}');
                    }).toList(),
                  ),
                ),

              // Check-in button
              Padding(
                padding: EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await journeyService.recordCheckIn(message: 'All good!');
                  },
                  icon: Icon(Icons.check_circle),
                  label: Text('Check In - I\'m Safe'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
              ),

              // End journey button
              Spacer(),
              Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await journeyService.endJourney(reason: 'User ended journey manually');
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.stop),
                    label: Text('End Journey'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
```

---

## Integration in Main SOS Screen

Add visual indicators that these services are active:

```dart
// In sos_screen.dart, after SOS is triggered:

// Show evidence capture widget
if (evidenceService.isCapturing) {
  EvidenceCaptureWidget(),
}

// Show live tracking link
if (trackingService.isTracking) {
  Card(
    child: ListTile(
      leading: Icon(Icons.location_on, color: Colors.red),
      title: Text('Live Tracking Active'),
      subtitle: Text('Guardians can see your location'),
      trailing: Icon(Icons.arrow_forward),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LiveTrackingScreen(
              trackingSessionId: trackingService.activeSessionId!,
            ),
          ),
        );
      },
    ),
  ),
}
```

---

## Testing Checklist

### Guardian Live Tracking:
- [ ] Trigger SOS and check Firestore `live_tracking` collection
- [ ] Verify location updates every 5-10 seconds
- [ ] Test guardian acknowledgment flow
- [ ] Check location history array grows

### Evidence Capture:
- [ ] Check microphone permission prompt
- [ ] Check camera permission prompt
- [ ] Verify audio file created in app documents
- [ ] Verify photos captured every 10 seconds
- [ ] Check Firebase Storage for encrypted files

### Safe Journey Mode:
- [ ] Start a journey and check Firestore `safe_journeys` collection
- [ ] Wait 10 minutes for check-in prompt
- [ ] Record a check-in
- [ ] Move 500m+ off route to trigger deviation alert
- [ ] Move within 100m of destination to auto-end

---

## 🎉 You're All Set!

Your app now has the most advanced safety features available. Test on a real device for the best experience!
