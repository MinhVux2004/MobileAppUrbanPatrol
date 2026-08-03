import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<bool> sendIncidentReport({
    required File imageFile,
    required Position position,
    required String description,
  }) async {
    try {
      String fileName = 'incident_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = _storage.ref().child('incident_images/$fileName');    
      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String imageUrl = await snapshot.ref.getDownloadURL();
      
      await _db.collection('incidents').add({
        'imageUrl': imageUrl,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'description': description,
        'status': 'Chờ xử lý', 
        'timestamp': FieldValue.serverTimestamp(), 
      });
      
      return true; 
    } catch (e) {
      log("Lỗi khi gửi phản ánh: $e");
      return false; 
    }
  }
}