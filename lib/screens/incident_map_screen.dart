import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class IncidentMapScreen extends StatefulWidget {
  const IncidentMapScreen({super.key});

  @override
  State<IncidentMapScreen> createState() => _IncidentMapScreenState();
}
class _IncidentMapScreenState extends State<IncidentMapScreen> {
  Set<Marker> _markers = {};
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(10.762622, 106.660172), 
    zoom: 14,
  );
  @override
  void initState() {
    super.initState();
    _loadIncidentsToMap();
  }
  Future<void> _loadIncidentsToMap() async {
    final querySnapshot = await FirebaseFirestore.instance.collection('incidents').get();   
    Set<Marker> loadedMarkers = {};
    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final double? lat = data['latitude'];
      final double? lng = data['longitude'];
      final String category = data['category'] ?? ' cố';
      final String incidentId = doc.id;
      if (lat != null && lng != null) {
        loadedMarkers.add(
          Marker(
            markerId: MarkerId(incidentId),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(
              title: category,
              snippet: 'Nhấn để xem chi tiết',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              data['status'] == 'closed' ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
            ),
          ),
        );
      }
    }
    setState(() {
      _markers = loadedMarkers;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bản đồ Quản lý Sự cố Đô thị'),
      ),
      body: GoogleMap(
        initialCameraPosition: _initialPosition,
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }
}