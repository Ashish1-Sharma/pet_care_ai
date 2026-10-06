import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/api.dart';
import 'api_service.dart';

/// Funnel events (signup → scan → paywall → purchase) sent in small batches
/// to the backend's `/api/pet/events`, which stores them in `pet_events`.
///
/// Events are only sent while signed in (the endpoint needs the JWT); until
/// then they wait in memory, capped so a long anonymous session cannot grow
/// the queue without bound.
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  static const int _maxQueue = 100;
  static const int _batchSize = 20;

  ApiService? _api;
  bool Function() _canSend = () => false;
  final List<Map<String, dynamic>> _queue = [];
  Timer? _timer;
  bool _sending = false;

  void attach(ApiService api, {required bool Function() canSend}) {
    _api = api;
    _canSend = canSend;
  }

  void log(String name, [Map<String, Object?> props = const {}]) {
    if (_queue.length >= _maxQueue) _queue.removeAt(0);
    _queue.add({
      'name': name,
      'props': props,
      'ts': DateTime.now().toUtc().toIso8601String(),
    });
    debugPrint('[analytics] $name $props');
    if (_queue.length >= _batchSize) {
      unawaited(flush());
    } else {
      _timer ??= Timer(const Duration(seconds: 20), () {
        _timer = null;
        unawaited(flush());
      });
    }
  }

  Future<void> flush() async {
    if (_sending || _queue.isEmpty || _api == null || !_canSend()) return;
    _sending = true;
    final batch = _queue.take(_batchSize).toList();
    try {
      await _api!.post(ApiEndpoints.events, data: {'events': batch});
      _queue.removeRange(0, batch.length);
    } catch (e) {
      // Keep the events for the next attempt; analytics must never surface
      // an error to the user.
      debugPrint('[analytics] flush failed: $e');
    } finally {
      _sending = false;
    }
  }
}

/// Shorthand: `track('paywall_view', {'from': 'home'})`.
void track(String name, [Map<String, Object?> props = const {}]) =>
    AnalyticsService.instance.log(name, props);
