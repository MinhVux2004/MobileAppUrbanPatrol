import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/incident_model.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _selectedFilter = 'all'; // Bộ lọc trạng thái mặc định

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Trị Điều Hành Sự Cố'),
        backgroundColor: Colors.indigo,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('Tất cả trạng thái')),
              const PopupMenuItem(value: 'reported', child: Text('Mới báo cáo')),
              const PopupMenuItem(value: 'assigned', child: Text('Đã phân công')),
              const PopupMenuItem(value: 'in_progress', child: Text('Đang xử lý')),
              const PopupMenuItem(value: 'pending_review', child: Text('Chờ duyệt nghiệm thu')),
              const PopupMenuItem(value: 'closed', child: Text('Đã hoàn thành')),
            ],
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getFilteredQuery(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Không có dữ liệu sự cố phù hợp với bộ lọc.'),
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
                        'Mã băm SHA-256: ${incident.imageHash.substring(0, 16)}...',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Thời gian: ${incident.timestamp.toLocal().toString().split('.')[0]}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const Divider(height: 16),
                      _buildAdminActions(context, incident),
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

  // Truy vấn Firestore dựa vào bộ lọc trạng thái được chọn
  Stream<QuerySnapshot> _getFilteredQuery() {
    Query query = FirebaseFirestore.instance.collection('incidents');
    if (_selectedFilter != 'all') {
      query = query.where('status', isEqualTo: _selectedFilter);
    }
    return query.orderBy('timestamp', descending: true).snapshots();
  }

  // Widget hiển thị nhãn trạng thái trực quan
  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'reported':
        color = Colors.red;
        label = 'Mới báo cáo';
        break;
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
      case 'closed':
        color = Colors.green;
        label = 'Đã đóng';
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

  // Các nút hành động tương ứng với từng trạng thái sự cố dành cho Admin
  Widget _buildAdminActions(BuildContext context, Incident incident) {
    if (incident.status == 'reported') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
          onPressed: () => _showAssignWorkerDialog(context, incident.id),
          icon: const Icon(Icons.assignment_ind),
          label: const Text('Phân công cho Công nhân'),
        ),
      );
    } else if (incident.status == 'pending_review') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          onPressed: () => _showReviewDialog(context, incident),
          icon: const Icon(Icons.fact_check),
          label: const Text('Kiểm duyệt & Đóng sự cố'),
        ),
      );
    } else {
      return Text(
        incident.workerId != null ? 'Đã giao cho công nhân ID: ${incident.workerId}' : 'Chưa có thông tin phân công',
        style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 12),
      );
    }
  }

  // Hộp thoại chọn công nhân để phân công sự cố
  void _showAssignWorkerDialog(BuildContext context, String incidentId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chọn công nhân xử lý'),
        content: SizedBox(
          width: double.maxFinite,
          height: 200,
          child: StreamBuilder<QuerySnapshot>(
            // Lấy danh sách tài khoản có role là 'worker' từ collection 'users'
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'worker')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final workers = snapshot.data!.docs;
              if (workers.isEmpty) {
                return const Center(child: Text('Không tìm thấy tài khoản công nhân nào.'));
              }

              return ListView.builder(
                itemCount: workers.length,
                itemBuilder: (context, index) {
                  final workerData = workers[index].data() as Map<String, dynamic>;
                  final workerId = workers[index].id;
                  final workerEmail = workerData['email'] ?? 'Không rõ email';

                  return ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(workerEmail),
                    trailing: ElevatedButton(
                      onPressed: () async {
                        // Cập nhật workerId và chuyển trạng thái sang 'assigned'
                        await FirebaseFirestore.instance
                            .collection('incidents')
                            .doc(incidentId)
                            .update({
                          'workerId': workerId,
                          'status': 'assigned',
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã phân công thành công!')),
                        );
                      },
                      child: const Text('Giao việc'),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }

  // Hộp thoại kiểm duyệt ảnh hoàn thành và đóng sự cố
  void _showReviewDialog(BuildContext context, Incident incident) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kiểm duyệt nghiệm thu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
     children: [
            const Text('Ảnh minh chứng hoàn thành từ công nhân:'),
            const SizedBox(height: 8),
            incident.completedImageUrl != null
                ? Image.network(
                    incident.completedImageUrl!,
                    height: 150,
                    fit: BoxFit.cover,
                  )
                : const Text('Không có ảnh minh chứng'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              // Cập nhật trạng thái thành 'closed' (Hoàn thành)
              await FirebaseFirestore.instance
                  .collection('incidents')
                  .doc(incident.id)
                  .update({
                'status': 'closed',
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã phê duyệt và đóng sự cố thành công!')),
              );
            },
            child: const Text('Phê duyệt hoàn thành'),
          ),
        ],
      ),
    );
  }
}