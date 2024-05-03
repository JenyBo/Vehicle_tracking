import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:camera/camera.dart';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:location/location.dart' as l;
import 'package:permission_handler/permission_handler.dart';
import 'camera_screen.dart';
import 'location_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocationService locationService = LocationService();
  late List<CameraDescription> cameras;

  bool gpsEnabled = false;
  bool permissionGranted = false;
  late StreamSubscription<l.LocationData> subscription;
  bool trackingEnabled = false;
  List<l.LocationData> lastThreeLocations = [];
  List<Map<String, dynamic>> locations = [];
  int countdown = 5;
  bool isCountdownRunning = false;
  late Timer timer;

  @override
  void initState() {
    super.initState();
    initLocationService();
    initCameras();
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }

  void initCameras() async {
    PermissionStatus status = await Permission.camera.request();
    if (status.isGranted) {
      cameras = await availableCameras();
    } else {
      // You can show a message to the user indicating that the camera permission was not granted.
      print('Camera permission was not granted');
    }
  }

  void initLocationService() async {
    await locationService.checkStatus();
    setState(() {
      gpsEnabled = locationService.gpsEnabled;
      permissionGranted = locationService.permissionGranted;
    });
  }

  void startTracking() async {
    if (!(await locationService.isGpsEnabled()) || !(await locationService.isPermissionGranted())) {
      return;
    }
    subscription = locationService.location.onLocationChanged.listen((event) async {
      addLocation(event);
      startCountDown();
    });
    setState(() {
      trackingEnabled = true;
    });
  }

  void startCountDown() {
    if (isCountdownRunning) {
      return;
    }
    countdown = 5;
    isCountdownRunning = true;
    timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (countdown == 1) {
        timer.cancel();
        isCountdownRunning = false;
        l.LocationData? currentLocation;
        try {
          currentLocation = await locationService.location.getLocation();
        } catch (e) {
          print('Failed to get location: $e');
        }
        if (currentLocation != null) {
          addLocation(currentLocation);
          if (areLastThreeLocationsSame(lastThreeLocations, 10.0)) { // 10.0 is the threshold in meters
            showDialog(
              context: context,
              builder: (context) {
                String dropdownValue = 'Road blockage';
                String otherReason = '';
                return StatefulBuilder(
                  builder: (context, setState) {
                    return AlertDialog(
                      title: const Text('You are stopped !!!'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          DropdownButton<String>(
                            value: dropdownValue,
                            onChanged: (String? newValue) {
                              setState(() {
                                dropdownValue = newValue!;
                              });
                            },
                            items: <String>['Road blockage', 'Red light', 'Other reason']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                          if (dropdownValue == 'Other reason')
                            TextField(
                              onChanged: (value) {
                                otherReason = value;
                              },
                              decoration: const InputDecoration(
                                hintText: 'Enter your reason',
                              ),
                            ),
                        ],
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: Text('OK'),
                          onPressed: () {
                            Navigator.of(context).pop();
                            print('Selected reason: $dropdownValue');
                            if (dropdownValue == 'Other reason') {
                              print('Other reason: $otherReason');
                            }
                          },
                        ),
                        if (dropdownValue == 'traffic jam' || dropdownValue == 'red light')
                          TextButton(
                            child: Text('Take Picture'),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TakePictureScreen(
                                    camera: cameras[0], // Pass the appropriate camera to the TakePictureScreen widget.
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    );
                  },
                );
              },
            );
            stopTracking();
            return;
          }
        }
        startCountDown();
      } else {
        setState(() {
          countdown--;
        });
      }
    });
  }

  void stopTracking() {
    if (timer.isActive) {
      timer.cancel();
    }
    subscription.cancel();
    setState(() {
      trackingEnabled = false;
    });
    clearLocation();
  }

  void addLocation(l.LocationData data) {
    DateTime updateTime = DateTime.now();
    setState(() {
      if (locations.isNotEmpty) {
        locations[0] = {'location': data, 'time': updateTime};
      } else {
        locations.insert(0, {'location': data, 'time': updateTime});
      }

      lastThreeLocations.insert(0, data);
      if (lastThreeLocations.length > 3) {
        lastThreeLocations.removeLast();
      }
    });
  }

  void clearLocation() {
    setState(() {
      locations.clear();
    });
  }

  bool areLocationsClose(l.LocationData loc1, l.LocationData loc2, double thresholdInMeters) {
    double distanceInMeters = Geolocator.distanceBetween(
      loc1.latitude!,
      loc1.longitude!,
      loc2.latitude!,
      loc2.longitude!,
    );

    return distanceInMeters <= thresholdInMeters;
  }

  bool areLastThreeLocationsSame(List<l.LocationData> lastThreeLocations, double thresholdInMeters) {
    if (lastThreeLocations.length < 3) {
      return false;
    }

    bool isSameLocation1And2 = areLocationsClose(lastThreeLocations[0], lastThreeLocations[1], thresholdInMeters);
    bool isSameLocation2And3 = areLocationsClose(lastThreeLocations[1], lastThreeLocations[2], thresholdInMeters);

    return isSameLocation1And2 && isSameLocation2And3;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location App'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            buildListTile(
              "GPS",
              gpsEnabled
                  ? const Text("Okey")
                  : ElevatedButton(
                  onPressed: () {
                    locationService.requestEnableGps();
                  },
                  child: const Text("Enable Gps")),
            ),
            buildListTile(
              "Permission",
              permissionGranted
                  ? const Text("Okey")
                  : ElevatedButton(
                  onPressed: () {
                    locationService.requestLocationPermission();
                  },
                  child: const Text("Request Permission")),
            ),
            buildListTile(
              "Location",
              trackingEnabled
                  ? ElevatedButton(
                  onPressed: () {
                    stopTracking();
                  },
                  child: const Text("Stop"))
                  : ElevatedButton(
                  onPressed: gpsEnabled && permissionGranted
                      ? () {
                    startTracking();
                  }
                      : null,
                  child: const Text("Start")),
            ),
            Expanded(
                child: ListView.builder(
                  itemCount: locations.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(
                          "${locations[index]['location'].latitude}, ${locations[index]['location'].longitude}"
                      ),
                      subtitle: Text(
                          "Last updated: ${locations[index]['time']}"
                      ),
                      trailing: Text(
                          "Countdown: $countdown"
                      ),
                    );
                  },
                )
            )
          ],
        ),
      ),
    );
  }

  ListTile buildListTile(
      String title,
      Widget? trailing,
      ) {
    return ListTile(
      dense: true,
      title: Text(title),
      trailing: trailing,
    );
  }
}