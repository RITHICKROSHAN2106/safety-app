import 'package:bloc/bloc.dart';
import 'package:geolocator/geolocator.dart';

class LocationState {
  final Position? position;
  final bool serviceEnabled;
  final LocationPermission permission;
  const LocationState({
    this.position,
    this.serviceEnabled = false,
    this.permission = LocationPermission.denied,
  });
}

class LocationCubit extends Cubit<LocationState> {
  LocationCubit() : super(const LocationState());

  Future<void> init() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    Position? pos;
    if (enabled &&
        (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse)) {
      pos = await Geolocator.getCurrentPosition();
    }
    emit(
      LocationState(
        position: pos,
        serviceEnabled: enabled,
        permission: permission,
      ),
    );
  }
}
