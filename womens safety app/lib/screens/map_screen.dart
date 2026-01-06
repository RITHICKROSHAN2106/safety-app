/// Map Screen  
/// Displays user location on interactive map
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/location_cubit.dart';
import '../services/whatsapp_service.dart';
import '../services/sms_service.dart';

class MapScreen extends StatefulWidget {
  final double? latitude;
  final double? longitude;

  const MapScreen({
    Key? key,
    this.latitude,
    this.longitude,
  }) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.latitude == null || widget.longitude == null) {
      context.read<LocationCubit>().getCurrentLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Location'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareLocation,
          ),
        ],
      ),
      body: BlocBuilder<LocationCubit, LocationState>(
        builder: (context, state) {
          if (state is LocationLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is LocationLoaded || state is LocationTracking) {
            final location = state is LocationLoaded
                ? state.location
                : (state as LocationTracking).currentLocation;

            return Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    center: LatLng(location.latitude, location.longitude),
                    zoom: 15.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.women_safety_app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(location.latitude, location.longitude),
                          width: 80,
                          height: 80,
                          builder: (context) => const Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 50,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Current Location',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          if (location.address != null)
                            Text(location.address!),
                          Text(
                            '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else if (state is LocationError) {
            return Center(child: Text(state.message));
          }
          return const Center(child: Text('Getting location...'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<LocationCubit>().getCurrentLocation();
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }

  void _shareLocation() async {
    final location = context.read<LocationCubit>().getLastLocation();
    if (location != null) {
      showModalBottomSheet(
        context: context,
        builder: (context) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.message),
                title: const Text('Share via WhatsApp'),
                onTap: () async {
                  // Share via WhatsApp
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.sms),
                title: const Text('Share via SMS'),
                onTap: () async {
                  // Share via SMS
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      );
    }
  }
}
