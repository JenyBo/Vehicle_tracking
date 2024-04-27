import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:location/location.dart' as l;
import 'package:permission_handler/permission_handler.dart';
import 'location_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocationService locationService = LocationService();
  bool gpsEnabled = false;
  bool permissionGranted = false;
  late StreamSubscription<l.LocationData> subscription;
  bool trackingEnabled = false;

  List<Map<String, dynamic>> locations = [];
  int countdown = 5;
  bool isCountdownRunning = false;
  late Timer timer;

  @override
  void initState() {
    super.initState();
    initLocationService();
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }

  void initLocationService() async {
    await locationService.checkStatus();
    setState(() {
      gpsEnabled = locationService.gpsEnabled;
      permissionGranted = locationService.permissionGranted;
    });
  }

  void startCountDown() {
    if (isCountdownRunning) {
      return;
    }
    isCountdownRunning = true;
    Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        countdown--;
      });
      if (countdown == 0) {
        timer.cancel();
        isCountdownRunning = false;
        setState(() {
          countdown = 5;
        });
      }
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
    timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      l.LocationData currentLocation = await locationService.location.getLocation();
      addLocation(currentLocation);
    });
    setState(() {
      trackingEnabled = true;
    });
  }

  void stopTracking() {
    subscription.cancel();
    timer.cancel();
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
    });
  }

  void clearLocation() {
    setState(() {
      locations.clear();
    });
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