import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class ReportListScreen extends StatelessWidget {
  const ReportListScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey[50],
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Đã xảy ra lỗi: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_rounded, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    "Chưa có phản ánh nào",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }
          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            padding: const EdgeInsets.all(12.0),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final String base64Image = data['image_base64'] ?? '';
              final String description = data['description'] ?? 'Không có mô tả';
              final double latitude = data['latitude'] ?? 0.0;
              final double longitude = data['longitude'] ?? 0.0;
              final String status = data['status'] ?? 'Chờ xử lý';
              final bool isPending = status == 'Chờ xử lý';
              Widget imageWidget;
              try {
                if (base64Image.isNotEmpty) {
                  imageWidget = Image.memory(
                    base64Decode(base64Image),
                    height: 90,
                    width: 90,
                    fit: BoxFit.cover,
                  );
                } else {
                  imageWidget = Container(
                    height: 90,
                    width: 90,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported, color: Colors.grey),
                  );
                }
              } catch (e) {
                imageWidget = Container(
                  height: 90,
                  width: 90,
                  color: Colors.grey[200],
                  child: const Icon(Icons.error, color: Colors.red),
                );
              }
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black..withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: imageWidget,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isPending ? Colors.orange.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isPending ? Colors.orange[800] : Colors.green[800],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.3),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.place, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  "${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}",
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}