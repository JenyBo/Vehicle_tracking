import 'dart:async';
import 'dart:developer';
import 'package:location/location.dart' as l;
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  l.Location location = l.Location();
  bool gpsEnabled = false;
  bool permissionGranted = false;

  Future<bool> isPermissionGranted() async {
    permissionGranted = await Permission.locationWhenInUse.isGranted;
    return permissionGranted;
  }

  Future<bool> isGpsEnabled() async {
    gpsEnabled = await Permission.location.serviceStatus.isEnabled;
    return gpsEnabled;
  }

  Future<void> checkStatus() async {
    permissionGranted = await isPermissionGranted();
    gpsEnabled = await isGpsEnabled();
  }

  Future<void> requestEnableGps() async {
    if (gpsEnabled) {
      log("Already open");
    } else {
      bool isGpsActive = await location.requestService();
      if (!isGpsActive) {
        gpsEnabled = false;
        log("User did not turn on GPS");
      } else {
        log("gave permission to the user and opened it");
        gpsEnabled = true;
      }
    }
  }

  Future<void> requestLocationPermission() async {
    PermissionStatus permissionStatus =
    await Permission.locationWhenInUse.request();
    if (permissionStatus == PermissionStatus.granted) {
      permissionGranted = true;
    } else {
      permissionGranted = false;
    }
  }
}