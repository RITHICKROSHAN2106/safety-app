/// Offline Queue Service
/// Handles offline data synchronization when network is unavailable
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OfflineQueueService {
  static const String _queueKey = 'offline_queue';
  static const String _pendingSosKey = 'pending_sos_alerts';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add item to offline queue
  Future<void> addToQueue(QueueItem item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> queue = prefs.getStringList(_queueKey) ?? [];

      queue.add(jsonEncode(item.toMap()));
      await prefs.setStringList(_queueKey, queue);

      print('Item added to offline queue: ${item.type}');
    } catch (e) {
      print('Failed to add item to queue: $e');
    }
  }

  // Get all queued items
  Future<List<QueueItem>> getQueuedItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> queue = prefs.getStringList(_queueKey) ?? [];

      return queue
          .map((item) => QueueItem.fromMap(jsonDecode(item)))
          .toList();
    } catch (e) {
      print('Failed to get queued items: $e');
      return [];
    }
  }

  // Process offline queue when online
  Future<void> processQueue() async {
    try {
      final items = await getQueuedItems();
      if (items.isEmpty) return;

      print('Processing ${items.length} queued items');

      List<QueueItem> failedItems = [];

      for (var item in items) {
        try {
          await _processQueueItem(item);
          print('Successfully processed: ${item.type}');
        } catch (e) {
          print('Failed to process item: ${item.type}, $e');
          failedItems.add(item);
        }
      }

      // Update queue with only failed items
      await _updateQueue(failedItems);
    } catch (e) {
      print('Failed to process queue: $e');
    }
  }

  // Process individual queue item
  Future<void> _processQueueItem(QueueItem item) async {
    switch (item.type) {
      case QueueItemType.sosLog:
        await _firestore.collection('sos_logs').doc(item.id).set(item.data);
        break;

      case QueueItemType.locationUpdate:
        await _firestore
            .collection('user_locations')
            .doc(item.id)
            .set(item.data);
        break;

      case QueueItemType.guardianUpdate:
        await _firestore.collection('guardians').doc(item.id).set(item.data);
        break;

      case QueueItemType.userUpdate:
        await _firestore.collection('users').doc(item.id).update(item.data);
        break;
    }
  }

  // Update queue with remaining items
  Future<void> _updateQueue(List<QueueItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> queue = items.map((item) => jsonEncode(item.toMap())).toList();
      await prefs.setStringList(_queueKey, queue);
    } catch (e) {
      print('Failed to update queue: $e');
    }
  }

  // Clear entire queue
  Future<void> clearQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_queueKey);
      print('Offline queue cleared');
    } catch (e) {
      print('Failed to clear queue: $e');
    }
  }

  // Save pending SOS alert for offline
  Future<void> savePendingSosAlert(Map<String, dynamic> sosData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pendingSosKey, jsonEncode(sosData));
      print('Pending SOS alert saved');
    } catch (e) {
      print('Failed to save pending SOS: $e');
    }
  }

  // Get pending SOS alert
  Future<Map<String, dynamic>?> getPendingSosAlert() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? data = prefs.getString(_pendingSosKey);
      if (data != null) {
        return jsonDecode(data);
      }
      return null;
    } catch (e) {
      print('Failed to get pending SOS: $e');
      return null;
    }
  }

  // Clear pending SOS alert
  Future<void> clearPendingSosAlert() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingSosKey);
    } catch (e) {
      print('Failed to clear pending SOS: $e');
    }
  }

  // Get queue size
  Future<int> getQueueSize() async {
    final items = await getQueuedItems();
    return items.length;
  }
}

// Queue item types
enum QueueItemType {
  sosLog,
  locationUpdate,
  guardianUpdate,
  userUpdate,
}

// Queue item model
class QueueItem {
  final String id;
  final QueueItemType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  QueueItem({
    required this.id,
    required this.type,
    required this.data,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.toString(),
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory QueueItem.fromMap(Map<String, dynamic> map) {
    return QueueItem(
      id: map['id'],
      type: QueueItemType.values.firstWhere(
        (e) => e.toString() == map['type'],
      ),
      data: Map<String, dynamic>.from(map['data']),
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
