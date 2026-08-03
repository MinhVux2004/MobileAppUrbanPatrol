import 'package:cloud_firestore/cloud_firestore.dart';

class Incident {
  final String id;
  final String category;         // Loại sự cố (ví dụ: ổ gà, ngập úng, rác thải...)
  final String imageUrl;         // Link ảnh trên Storage/Base64
  final String imageHash;        // Mã băm SHA-256 chống giả mạo ảnh
  final String address;          // Địa chỉ chi tiết
  final String district;         // Quận/Huyện
  final String status;           // reported -> assigned -> in_progress -> pending_review -> closed
  final String? workerId;        // ID công nhân được phân công (nếu có)
  final String? completedImageUrl; // Ảnh minh chứng sau khi sửa xong
  final DateTime? slaDeadline;   // Hạn chót xử lý theo SLA
  final DateTime timestamp;      // Thời gian tạo báo cáo
  final Map<String, dynamic> metadata; // Metadata: Tọa độ GPS, thiết bị, v.v.

  Incident({
    required this.id,
    required this.category,
    required this.imageUrl,
    required this.imageHash,
    required this.address,
    required this.district,
    required this.status,
    this.workerId,
    this.completedImageUrl,
    this.slaDeadline,
    required this.timestamp,
    required this.metadata,
  });

  // Chuyển đổi dữ liệu để lưu lên Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'imageUrl': imageUrl,
      'imageHash': imageHash,
      'address': address,
      'district': district,
      'status': status,
      'workerId': workerId,
      'completedImageUrl': completedImageUrl,
      'slaDeadline': slaDeadline != null ? Timestamp.fromDate(slaDeadline!) : null,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
    };
  }

  // Khởi tạo từ dữ liệu Firestore
  factory Incident.fromMap(Map<String, dynamic> map) {
    return Incident(
      id: map['id'] ?? '',
      category: map['category'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      imageHash: map['imageHash'] ?? '',
      address: map['address'] ?? '',
      district: map['district'] ?? '',
      status: map['status'] ?? 'reported',
      workerId: map['workerId'],
      completedImageUrl: map['completedImageUrl'],
      slaDeadline: (map['slaDeadline'] as Timestamp?)?.toDate(),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }
}