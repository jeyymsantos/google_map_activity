import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_map_activity/constants.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class GoogleMapPage extends StatefulWidget {
  const GoogleMapPage({super.key});

  @override
  State<GoogleMapPage> createState() => _GoogleMapPageState();
}

class _GoogleMapPageState extends State<GoogleMapPage> {
  final locationController = Location();
  static const house = LatLng(14.953818, 120.895367);
  static const school = LatLng(14.959450, 120.889935);

  LatLng? currentPosition;
  Map<PolylineId, Polyline> polylines = {};
  bool polylineVisible = false; // To control polyline visibility

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) async => await fetchLocationUpdates());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Google Map with Polyline'),
        ),
        body: Stack(
          children: [
            currentPosition == null
                ? const Center(child: CircularProgressIndicator())
                : GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: house,
                      zoom: 13,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('currentLocation'),
                        icon: BitmapDescriptor.defaultMarker,
                        position: currentPosition!,
                      ),
                      const Marker(
                        markerId: MarkerId('sourceLocation'),
                        icon: BitmapDescriptor.defaultMarker,
                        position: house,
                      ),
                      const Marker(
                        markerId: MarkerId('destinationLocation'),
                        icon: BitmapDescriptor.defaultMarker,
                        position: school,
                      ),
                    },
                    polylines: polylineVisible
                        ? Set<Polyline>.of(polylines.values)
                        : {}, // Show polyline if polylineVisible is true
                  ),
            Positioned(
              bottom: 50,
              right: 15,
              child: FloatingActionButton(
                onPressed: _onShowPolylineButtonPressed, // Trigger polyline
                child: const Icon(Icons.directions),
              ),
            ),
          ],
        ),
      );

  Future<void> _onShowPolylineButtonPressed() async {
    if (!polylineVisible) {
      // Fetch polyline coordinates and show them
      final coordinates = await fetchPolylinePoints();
      if (coordinates.isNotEmpty) {
        await generatePolyLineFromPoints(coordinates);
        setState(() {
          polylineVisible = true; // Show polyline after fetching coordinates
        });
      }
    }
  }

  Future<void> fetchLocationUpdates() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await locationController.serviceEnabled();
    if (serviceEnabled) {
      serviceEnabled = await locationController.requestService();
    } else {
      return;
    }

    permissionGranted = await locationController.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await locationController.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    locationController.onLocationChanged.listen((currentLocation) {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        setState(() {
          currentPosition = LatLng(
            currentLocation.latitude!,
            currentLocation.longitude!,
          );
        });
      }
    });
  }

  Future<List<LatLng>> fetchPolylinePoints() async {
    final polylinePoints = PolylinePoints();

    final result = await polylinePoints.getRouteBetweenCoordinates(
      googleMapsApiKey,
      PointLatLng(house.latitude, house.longitude),
      PointLatLng(school.latitude, school.longitude),
    );

    if (result.points.isNotEmpty) {
      return result.points
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();
    } else {
      debugPrint(result.errorMessage);
      return [];
    }
  }

  Future<void> generatePolyLineFromPoints(
      List<LatLng> polylineCoordinates) async {
    const id = PolylineId('polyline');

    final polyline = Polyline(
      polylineId: id,
      color: Colors.blueAccent,
      points: polylineCoordinates,
      width: 5,
    );

    setState(() => polylines[id] = polyline);
  }
}
