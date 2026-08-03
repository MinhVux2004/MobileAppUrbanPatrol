import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/incident_model.dart';

class WorkerScreen extends StatelessWidget {
  final String workerId; // ID của công nhân hiện tại (lấy từ Firebase Auth)

  const WorkerScreen({Key? key, required this.workerId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhiệm vụ được giao'),
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Truy vấn sự cố thuộc về workerId và có trạng thái cần xử lý
        stream: FirebaseFirestore.instance
            .collection('incidents')
            .where('workerId', isEqualTo: workerId)
            .where('status', whereIn: ['assigned', 'in_progress', 'pending_review'])
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Hiện tại không có sự cố nào được giao cho bạn.'),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final incident = Incident.fromMap(data);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            incident.category,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          _buildStatusBadge(incident.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Địa chỉ: ${incident.address}'),
                      const SizedBox(height: 4),
                      Text(
                        'Thời gian: ${incident.timestamp.toLocal().toString().split('.')[0]}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const Divider(height: 16),
                      _buildActionButtons(context, incident),
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

  // Widget hiển thị nhãn trạng thái trực quan
  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'assigned':
        color = Colors.orange;
        label = 'Đã phân công';
        break;
      case 'in_progress':
        color = Colors.blue;
        label = 'Đang xử lý';
        break;
      case 'pending_review':
        color = Colors.purple;
        label = 'Chờ duyệt';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  // Widget nút bấm thay đổi trạng thái linh hoạt theo vòng đời sự cố
  Widget _buildActionButtons(BuildContext context, Incident incident) {
    if (incident.status == 'assigned') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          onPressed: () => _updateStatus(context, incident.id, 'in_progress'),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Bắt đầu xử lý'),
        ),
      );
    } else if (incident.status == 'in_progress') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          onPressed: () {
            // Giả lập chụp ảnh hoàn thành và cập nhật lên pending_review
            _showCompleteDialog(context, incident.id);
          },
          icon: const Icon(Icons.check_circle),
          label: const Text('Hoàn thành & Gửi nghiệm thu'),
        ),
      );
    } else {
      return const Text(
        'Đã gửi báo cáo nghiệm thu, đang chờ Trung tâm phê duyệt.',
        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
      );
    }
  }

  // Hàm cập nhật trạng thái đơn thuần
  Future<void> _updateStatus(BuildContext context, String incidentId, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('incidents').doc(incidentId).update({
        'status': newStatus,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật trạng thái sự cố!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi cập nhật: $e')),
      );
    }
  }

  // Hộp thoại mô phỏng việc đính kèm ảnh hoàn thành trước khi chuyển sang pending_review
  void _showCompleteDialog(BuildContext context, String incidentId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận hoàn thành'),
        content: const Text('Bạn có chắc chắn đã khắc phục xong sự cố này? Hệ thống sẽ gửi ảnh minh chứng về cho Admin duyệt.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // Trong thực tế, bạn sẽ gọi hàm chọn ảnh từ camera ở đây. 
              // Tạm thời truyền link ảnh mẫu minh chứng hoàn thành.
              String mockCompletedImageUrl = 'https://via.placeholder.com/400';

              await FirebaseFirestore.instance.collection('incidents').doc(incidentId).update({
                'status': 'pending_review',
                'completedImageUrl': mockCompletedImageUrl,
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã gửi nghiệm thu thành công!')),
              );
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }
}