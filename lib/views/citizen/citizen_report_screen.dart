import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
class CitizenReportScreen extends StatefulWidget {
  const CitizenReportScreen({super.key});
  @override
  State<CitizenReportScreen> createState() => _CitizenReportScreenState();
}
class _CitizenReportScreenState extends State<CitizenReportScreen> {
  bool _isSending = false;
  XFile? _imageFile; 
  Uint8List? _imageBytes; 
  Position? _currentPosition;
  String _addressStatus = "Chưa lấy được định vị GPS";
  final TextEditingController _descController = TextEditingController();
  bool _isLoading = false;
  Future<String> _calculateImageHash(XFile imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  Map<String, dynamic> _generateMetadata({
    required double latitude,
    required double longitude,
  }) {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'deviceInfo': kIsWeb ? 'Web Browser' : Platform.operatingSystem,
      'capturedAt': DateTime.now().toIso8601String(),
    };
  }
  Future<void> _captureImageFromCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (!mounted) return;
    if (photo != null) {
      final bytes = await photo.readAsBytes();
      setState(() {
        _imageFile = photo; 
        _imageBytes = bytes;
      });
      await _getCurrentLocation();
    }
  }
  Future<void> _getCurrentLocation() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _addressStatus = "Đang khóa định vị GPS...";
    });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) return;
      if (!serviceEnabled) {
        setState(() {
          _addressStatus = "Vui lòng bật GPS trên thiết bị!";
          _isLoading = false;
        });
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (!mounted) return;
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (!mounted) return;
        if (permission == LocationPermission.denied) {
          setState(() {
            _addressStatus = "Quyền truy cập vị trí bị từ chối!";
            _isLoading = false;
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _addressStatus = "Quyền vị trí bị từ chối vĩnh viễn!";
          _isLoading = false;
        });
        return;
      }
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;
      setState(() {
        _currentPosition = position;
        _addressStatus = "Lat: ${position.latitude.toStringAsFixed(6)}, Lng:${position.longitude.toStringAsFixed(6)}";
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _addressStatus = "Lỗi khi lấy GPS: $e";
        _isLoading = false;
      });
    }
  }
  Future<void> _submitReport() async {
    if (_imageFile == null || _currentPosition == null || _isSending) return;

    setState(() {
      _isSending = true;
    });
    try {
      List<int> imageBytes = _imageBytes ?? await _imageFile!.readAsBytes();
      String base64Image = base64Encode(imageBytes);
      String imageHash = await _calculateImageHash(_imageFile!);
      Map<String, dynamic> metadata = _generateMetadata(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );
      await FirebaseFirestore.instance.collection('reports').add({
        'image_base64': base64Image,
        'image_hash': imageHash,
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
        'description': _descController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'Chờ xử lý',
        'metadata': metadata,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gửi phản ánh thành công với mã bảo mật SHA-256!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _imageFile = null;
        _imageBytes = null;
        _currentPosition = null;
        _addressStatus = "Chưa lấy được định vị GPS";
        _descController.clear();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Lỗi khi gửi: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey[50],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Báo cáo sự cố đô thị",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _captureImageFromCamera,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _imageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.memory(
                          _imageBytes!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt_rounded, size: 36, color: Colors.blueAccent),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "Chạm để chụp ảnh hiện trường",
                            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blueAccent),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "(Bắt buộc chụp trực tiếp kèm GPS)",
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.location_on_rounded, color: Colors.red),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Tọa độ hiện trường",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        _isLoading
                            ? const LinearProgressIndicator()
                            : Text(
                                _addressStatus,
                                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: "Mô tả chi tiết sự cố",
                hintText: "VD: Hố ga mất nắp, ngập úng đoạn đường...",
                alignLabelWithHint: true,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: (_imageBytes != null && _currentPosition != null && !_isSending)
                    ? _submitReport
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isSending
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        "GỬI PHẢN ÁNH NGAY",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}