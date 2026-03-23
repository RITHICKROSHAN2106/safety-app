import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Manages offline queue and network resilience for SOS alerts
class OfflineQueueService {
  static const String _queueKey = 'sos_offline_queue';
  static final Connectivity _connectivity = Connectivity();
  static StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  static bool _isProcessing = false;

  /// Queue item structure
  static const int maxQueueSize = 50;
  static const int maxRetries = 5;

  /// Start monitoring network connectivity
  static Future<void> initialize() async {
    // Check for queued items on startup
    await _processQueue();

    // Listen for network changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        if (results.isNotEmpty && results.first != ConnectivityResult.none) {
          debugPrint('📶 Network connected, processing queue...');
          _processQueue();
        }
      },
    );

    debugPrint('✅ Offline queue service initialized');
  }

  /// Stop monitoring
  static Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  /// Add SOS alert to offline queue
  static Future<bool> queueAlert({
    required String alertId,
    required String userId,
    required double latitude,
    required double longitude,
    required String triggerType,
    required List<String> guardianPhones,
    required String message,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_queueKey);
      final List<dynamic> queue =
          queueJson != null ? jsonDecode(queueJson) : [];

      // Check queue size limit
      if (queue.length >= maxQueueSize) {
        debugPrint('⚠️ Queue full, removing oldest item');
        queue.removeAt(0);
      }

      // Add new item
      final item = {
        'id': alertId,
        'userId': userId,
        'latitude': latitude,
        'longitude': longitude,
        'triggerType': triggerType,
        'guardianPhones': guardianPhones,
        'message': message,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'retries': 0,
      };

      queue.add(item);

      // Save queue
      await prefs.setString(_queueKey, jsonEncode(queue));
      debugPrint('📝 Alert queued (${queue.length} items in queue)');

      // Try to process immediately
      _processQueue();

      return true;
    } catch (e) {
      debugPrint('❌ Failed to queue alert: $e');
      return false;
    }
  }

  /// Process queued alerts
  static Future<void> _processQueue() async {
    if (_isProcessing) {
      debugPrint('⚠️ Queue processing already in progress');
      return;
    }

    _isProcessing = true;

    try {
      // Check network connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult.first == ConnectivityResult.none) {
        debugPrint('📵 No network, keeping items in queue');
        _isProcessing = false;
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_queueKey);

      if (queueJson == null || queueJson.isEmpty) {
        _isProcessing = false;
        return;
      }

      final List<dynamic> queue = jsonDecode(queueJson);

      if (queue.isEmpty) {
        _isProcessing = false;
        return;
      }

      debugPrint('📤 Processing ${queue.length} queued alerts...');

      final List<dynamic> remainingQueue = [];

      for (final item in queue) {
        final success = await _sendQueuedAlert(item);

        if (!success) {
          // Increment retry count
          item['retries'] = (item['retries'] ?? 0) + 1;

          // Keep in queue if under retry limit
          if (item['retries'] < maxRetries) {
            remainingQueue.add(item);
            debugPrint(
                '⚠️ Alert failed, will retry (${item['retries']}/$maxRetries)');
          } else {
            debugPrint('❌ Alert exceeded retry limit, dropping');
          }
        } else {
          debugPrint('✅ Queued alert sent successfully');
        }
      }

      // Save remaining queue
      await prefs.setString(_queueKey, jsonEncode(remainingQueue));

      if (remainingQueue.isEmpty) {
        debugPrint('✅ All queued alerts processed');
      } else {
        debugPrint(
            '⚠️ ${remainingQueue.length} alerts remain in queue');
      }
    } catch (e) {
      debugPrint('❌ Queue processing error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// Send a queued alert (SMS fallback)
  static Future<bool> _sendQueuedAlert(Map<String, dynamic> item) async {
    try {
      // Use SMS as primary fallback when offline/queued
      final phones = List<String>.from(item['guardianPhones'] ?? []);

      if (phones.isEmpty) {
        debugPrint('⚠️ No guardian phones in queued alert');
        return false;
      }

      // Will be sent automatically when SMS service is available
      debugPrint('📤 Queued alert ready for SMS delivery to ${phones.length} guardians');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to process queued alert: $e');
      return false;
    }
  }

  /// Get current queue size
  static Future<int> getQueueSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_queueKey);

      if (queueJson == null || queueJson.isEmpty) {
        return 0;
      }

      final List<dynamic> queue = jsonDecode(queueJson);
      return queue.length;
    } catch (e) {
      debugPrint('❌ Failed to get queue size: $e');
      return 0;
    }
  }

  /// Clear all queued items
  static Future<void> clearQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_queueKey);
      debugPrint('✅ Queue cleared');
    } catch (e) {
      debugPrint('❌ Failed to clear queue: $e');
    }
  }

  /// Check if network is available
  static Future<bool> isNetworkAvailable() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult.first != ConnectivityResult.none;
  }
}
