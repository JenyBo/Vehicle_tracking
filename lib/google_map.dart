import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

class GoogleMapWidget extends StatefulWidget {
  final LatLng initialPosition;
  final Function(LatLng) onPositionChanged;

  GoogleMapWidget({required this.initialPosition, required this.onPositionChanged});

  @override
  _GoogleMapWidgetState createState() => _GoogleMapWidgetState();
}

class _GoogleMapWidgetState extends State<GoogleMapWidget> {
  final Completer<GoogleMapController> _controller = Completer();

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
        widget.onPositionChanged(position.target);
      },
    );
  }
}