import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';

class GoogleMapWidget extends StatefulWidget {
  final LatLng initialPosition;
  final Function(LatLng) onPositionChanged;

  GoogleMapWidget({required this.initialPosition, required this.onPositionChanged});

  @override
  _GoogleMapWidgetState createState() => _GoogleMapWidgetState();
}

class _GoogleMapWidgetState extends State<GoogleMapWidget> {
  final Completer<GoogleMapController> _controller = Completer();
  late LatLng _lastMapPosition;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _lastMapPosition = widget.initialPosition;
    _timer = Timer.periodic(Duration(seconds: 5), (Timer t) => updateLocation());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void updateLocation() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    LatLng newLocation = LatLng(position.latitude, position.longitude);

    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLng(newLocation));

    _lastMapPosition = newLocation;
    widget.onPositionChanged(newLocation);
  }
  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      onMapCreated: (GoogleMapController controller) {
        _controller.complete(controller);
      },
      initialCameraPosition: CameraPosition(
        target: widget.initialPosition,
        zoom: 14.4746,
      ),
      onCameraMove: (CameraPosition position) {
        _lastMapPosition = position.target;
      },
      onCameraIdle: () {
        widget.onPositionChanged(_lastMapPosition);
      },
    );
  }
}