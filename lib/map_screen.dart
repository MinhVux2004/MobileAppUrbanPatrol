import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<Marker> _markers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReportsFromFirestore();
  }

  Future<void> _loadReportsFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('reports').get();

      final markers = snapshot.docs.map((doc) {
        final data = doc.data();
        final double lat = data['latitude'] ?? 21.028511;
        final double lng = data['longitude'] ?? 105.804817;
        final String description = data['description'] ?? 'Sự cố đô thị';
        final String status = data['status'] ?? 'Chờ xử lý';

        return Marker(
          point: LatLng(lat, lng),
          width: 45,
          height: 45,
          child: GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                      const SizedBox(width: 8),
                      const Text('Chi tiết sự cố', style: TextStyle(fontSize: 18)),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Trạng thái: $status", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                      const SizedBox(height: 8),
                      Text(description, style: const TextStyle(fontSize: 15)),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Đóng', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            },
            child: const Icon(
              Icons.location_on_rounded,
              color: Colors.redAccent,
              size: 42,
            ),
          ),
        );
      }).toList();

      setState(() {
        _markers = markers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
        options: const MapOptions(
          initialCenter: LatLng(21.028511, 105.804817),
          initialZoom: 13.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.urbanpatrol',
          ),
          MarkerLayer(
            markers: _markers,
          ),
        ],
      ),
    );
  }
}