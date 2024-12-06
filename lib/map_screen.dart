import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:background_locator_2/settings/android_settings.dart';
import 'package:background_locator_2/settings/locator_settings.dart';
import 'package:background_locator_2/background_locator.dart';
import 'package:map_nav_example/location_callback_handler.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  final LatLng _startPoint = const LatLng(37.7749, -122.4194); // San Francisco
  final LatLng _endPoint = const LatLng(34.0522, -118.2437); // Los Angeles
  final List<LatLng> _routePoints = [];
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _fetchRoute();
  }

  bool isTracking = false;

  void startLocationTracking() {
    BackgroundLocator.registerLocationUpdate(
      CallbackHandler.callback,
      androidSettings: const AndroidSettings(
        accuracy: LocationAccuracy.NAVIGATION,
        interval: 5,
        distanceFilter: 0,
        client: LocationClient.google,
        androidNotificationSettings: AndroidNotificationSettings(
          notificationChannelName: 'Location Tracking',
          notificationTitle: 'Background Tracking',
          notificationMsg: 'App is tracking your location',
          notificationIcon: '',
        ),
      ),
    );
    setState(() {
      isTracking = true;
    });
  }

  void stopLocationTracking() {
    BackgroundLocator.unRegisterLocationUpdate();
    setState(() {
      isTracking = false;
    });
  }

  Future<void> _checkAndRequestPermission() async {
    PermissionStatus status = await Permission.location.request();

    if (status.isGranted) {
      print("permission granted!");
      _openGoogleMaps();
    } else if (status.isDenied) {
      print("permission denied!");
    } else if (status.isPermanentlyDenied) {
      print("permission permanently denied. Opening settings...");
      await openAppSettings();
    }
  }

  Future<void> _openGoogleMaps() async {
    final Uri url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=${_startPoint.latitude},${_startPoint.longitude}&destination=${_endPoint.latitude},${_endPoint.longitude}&travelmode=driving',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> _fetchRoute() async {
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: 'AIzaSyBbU6wILVYGpaZxPORG5IM9zIo0tx-i308',
      request: PolylineRequest(
          origin: PointLatLng(_startPoint.latitude, _startPoint.longitude),
          destination: PointLatLng(_endPoint.latitude, _endPoint.longitude),
          mode: TravelMode.driving),
    );

    if (result.points.isNotEmpty) {
      setState(() {
        _routePoints.addAll(result.points
            .map((point) => LatLng(point.latitude, point.longitude)));
        _polylines.add(Polyline(
          polylineId: const PolylineId("route"),
          points: _routePoints,
          color: Colors.blue,
          width: 5,
        ));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Route on Map")),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _startPoint,
              zoom: 7,
            ),
            onMapCreated: (controller) => _mapController = controller,
            markers: {
              Marker(markerId: const MarkerId("start"), position: _startPoint),
              Marker(markerId: const MarkerId("end"), position: _endPoint),
            },
            polylines: _polylines,
          ),
          Positioned(
            bottom: 20,
            right: 0,
            left: 0,
            child: ElevatedButton(
                onPressed: () {
                  startLocationTracking();
                  _checkAndRequestPermission();
                },
                child: const Text("Go to Map")),
          )
        ],
      ),
    );
  }
}
