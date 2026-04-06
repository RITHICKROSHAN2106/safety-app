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
  final bool _autoInit;

  LocationCubit({bool autoInit = true})
      : _autoInit = autoInit,
        super(const LocationState());

  Future<void> init() async {
    if (!_autoInit) {
      emit(const LocationState());
      return;
    }

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
