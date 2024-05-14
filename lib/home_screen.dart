import 'dart:async';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:camera/camera.dart';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as l;
import 'package:permission_handler/permission_handler.dart';
import 'camera_screen.dart';
import 'location_service.dart';
import 'google_map.dart';
import 'login_screen.dart';

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
  String? imagePath;
  LatLng _currentPosition = const LatLng(0, 0);
  late GoogleMapController mapController;
  final LatLng _center = const LatLng(20.9979212, 105.8482639);

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }


  @override
  void initState() {
    super.initState();
    initLocationService();
    initCameras();
    getCurrentLocation();
  }

  void getCurrentLocation() async {
    l.LocationData currentLocation;
    try {
      currentLocation = await locationService.location.getLocation();
      _currentPosition = LatLng(currentLocation.latitude!, currentLocation.longitude!);
    } catch (e) {
      print('Failed to get location: $e');
    }
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
    permissionGranted = await locationService.isPermissionGranted();
    gpsEnabled = await locationService.isGpsEnabled();
    setState(() {}); // Add this line to trigger a rebuild of the UI
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
          print(currentLocation);
        } catch (e) {
          print('Failed to get location: $e');
        }
        if (currentLocation != null) {
          addLocation(currentLocation);
          if (areLastThreeLocationsSame(lastThreeLocations, 5.0)) { // 5.0 is the threshold in meters
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return buildAlertDialog(context);
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

  Future<void> takePicture() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TakePictureScreen(
          camera: cameras[0], // Pass the appropriate camera to the TakePictureScreen widget.
        ),
      ),
    );
    if (result != null) {
      setState(() {
        imagePath = result as String;
      });
      // Do something with imagePath, like showing it in an AlertDialog.
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return buildAlertDialog(context);
        },
      );
    }
  }

  AlertDialog buildAlertDialog(BuildContext context) {
    String dropdownValue = 'Road blockage';
    String otherReason = '';
    return AlertDialog(
      content: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('You need to move'),
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
              if (imagePath != null)
                SizedBox(
                  child: Image.file(File(imagePath!)),
                  height: 200, // Adjust the size as needed.
                  width: 200, // Adjust the size as needed.
                ),
            ],
          );
        },
      ),
      actions: <Widget>[
        TextButton(
          child: Text('OK'),
          onPressed: () {
            if ((dropdownValue == 'Red light' || dropdownValue == 'Road blockage') && imagePath == null) {
              // Show a message to the user indicating that they need to take a picture.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please take a picture before pressing OK.')),
              );
            } else {
              if (imagePath != null) {
                Navigator.of(context).pop(); // Only pop the dialog off the stack if an image has been taken
              }
              Navigator.of(context).pop();
              print('Selected reason: $dropdownValue');
              if (dropdownValue == 'Other reason') {
                print('Other reason: $otherReason');
              }
              if (mounted) { // Check if the widget is still in the tree
                setState(() {
                  imagePath = null; // Clear the imagePath
                });
              }
            }
          },
        ),
        if (dropdownValue == 'Road blockage' || dropdownValue == 'Red light') // Only show the 'Take Picture' button for these options
          TextButton(
            onPressed: takePicture,
            child: const Text('Take Picture'),
          ),
      ],
    );
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
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        ],
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
              // flex: 1,
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
              ),
            ),
            Expanded(
              flex: 5,
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: _center,
                  zoom: 15.0,
                ),
            ),
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