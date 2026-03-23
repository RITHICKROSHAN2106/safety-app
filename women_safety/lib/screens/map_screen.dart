import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../bloc/location/location_cubit.dart';
import '../bloc/auth/auth_cubit.dart';
import '../services/config.dart';
import '../services/location_share_service.dart';
import '../models/guardian.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  static const routeName = '/map';

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng _initial = LatLng(28.6139, 77.2090); // New Delhi default
  LatLng? _userLocation;
  bool _isLoading = true;
  String? _error;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  Future<void> _prepare() async {
    _setBusy();

    final locationCubit = context.read<LocationCubit>();
    final state = locationCubit.state;

    final Position? pos;
    if (state.position != null) {
      pos = state.position;
    } else {
      pos = await _getPositionSafe();
    }

    if (!_isMounted) return;

    if (pos == null) {
      _setError('Location unavailable. Allow location access and try again.');
      return;
    }

    final latLng = LatLng(pos.latitude, pos.longitude);
    _setReady(latLng);
  }

  Future<Position?> _getPositionSafe() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setError('Location services are disabled. Enable GPS to view the map.');
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        _setError('Location permission denied. Grant access from Settings.');
        return null;
      }

      return await Geolocator.getCurrentPosition();
    } catch (e) {
      _setError('Failed to fetch current position: $e');
      return null;
    }
  }

  void _setBusy() {
    if (!_isMounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
  }

  void _setError(String message) {
    if (!_isMounted) return;
    setState(() {
      _isLoading = false;
      _error = message;
    });
  }

  void _setReady(LatLng latLng) {
    if (!_isMounted) return;
    setState(() {
      _userLocation = latLng;
      _initial = latLng;
      _isLoading = false;
      _error = null;
    });

    try {
      _mapController.move(latLng, 15);
    } catch (_) {}
  }

  bool get _isMounted => mounted && !_disposed;

  List<Marker> _buildMarkers() {
    if (_userLocation == null) {
      return const [];
    }
    return [
      Marker(
        point: _userLocation!,
        width: 44,
        height: 44,
        alignment: Alignment.center,
        child: const Icon(
          Icons.my_location,
          color: Colors.redAccent,
          size: 32,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _MapPlaceholder(
        message: _error!,
        onAction: () {
          openAppSettings();
        },
        onRetry: () {
          _prepare();
        },
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initial,
              initialZoom: 12,
              maxZoom: 18,
              minZoom: 3,
            ),
            children: [
              TileLayer(
                urlTemplate: AppConfig.mapTileUrlTemplate,
                userAgentPackageName: AppConfig.mapUserAgentPackage,
                tileBuilder: (context, widget, tile) => widget,
              ),
              MarkerLayer(markers: _buildMarkers()),
            ],
          ),
        ),
        if (_isLoading)
          const Positioned.fill(
            child: ColoredBox(
              color: Colors.black26,
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        Positioned(
          right: 16,
          bottom: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                heroTag: 'locate_me',
                onPressed: () async {
                  _setBusy();
                  final pos = await _getPositionSafe();
                  if (pos != null) {
                    _setReady(LatLng(pos.latitude, pos.longitude));
                  }
                },
                child: const Icon(Icons.my_location),
              ),
              const SizedBox(height: 12),
              FloatingActionButton.extended(
                heroTag: 'share_location',
                onPressed: () => _showShareLocationDialog(context),
                icon: const Icon(Icons.share_location),
                label: const Text('Share'),
                backgroundColor: Colors.green,
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    builder: (_) => const _AttributionSheet(),
                  );
                },
                child: const Text('Credits'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showShareLocationDialog(BuildContext context) async {
    final authState = context.read<AuthCubit>().state;
    final userId = authState.user?.uid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to share location')),
      );
      return;
    }

    // Load emergency contacts
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    if (!userDoc.exists) return;

    final contactIds = (userDoc.data()?['emergencyContactIds'] as List<dynamic>?)
            ?.cast<String>() ??
        [];

    if (contactIds.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No emergency contacts configured. Add them in Profile.'),
        ),
      );
      return;
    }

    final List<Guardian> contacts = [];
    for (final contactId in contactIds) {
      final contactDoc = await FirebaseFirestore.instance
          .collection('guardians')
          .doc(contactId)
          .get();

      if (contactDoc.exists) {
        contacts.add(Guardian.fromJson({
          'id': contactDoc.id,
          ...contactDoc.data()!,
        }));
      }
    }

    if (!context.mounted) return;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('📍 Share Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Share your current location with ${contacts.length} emergency contacts'),
            const SizedBox(height: 16),
            ...contacts.take(3).map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.person, size: 16),
                        const SizedBox(width: 8),
                        Text(c.name, style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ),
            if (contacts.length > 3)
              Text('...and ${contacts.length - 3} more',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await LocationShareService.shareCurrentLocation(
                contacts: contacts,
                viaWhatsApp: true,
                viaSMS: false,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? '✅ Location shared!'
                        : '❌ Failed to share location'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            icon: const Icon(Icons.send),
            label: const Text('Share via WhatsApp'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await LocationShareService.shareCurrentLocation(
                contacts: contacts,
                viaWhatsApp: false,
                viaSMS: true,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? '✅ Location shared via SMS!'
                        : '❌ Failed to share location'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            icon: const Icon(Icons.sms),
            label: const Text('Share via SMS'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class _AttributionSheet extends StatelessWidget {
  const _AttributionSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Map data attribution',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              '${AppConfig.mapAttribution}. Data is available under the Open Database Licence.',
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder({
    required this.message,
    required this.onRetry,
    required this.onAction,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.map_outlined, size: 72, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Map unavailable',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.settings_outlined),
            label: const Text('Open system settings'),
          ),
        ],
      ),
    );
  }
}
