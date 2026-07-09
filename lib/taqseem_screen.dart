import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TaqseemScreen extends StatelessWidget {
  const TaqseemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C7A43),
        title: const Text(
          'پانچ حصوں میں تقسیم',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('receipts').snapshots(),
        builder: (context, snapshot) {
          double totalAmount = 0.0;
          if (snapshot.hasData) {
            for (var doc in snapshot.data!.docs) {
              totalAmount +=
                  (doc.data() as Map<String, dynamic>)['today_received'] ?? 0.0;
            }
          }

          double eachShare = totalAmount / 5;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFDE7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.money, size: 40, color: Colors.green),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'کل تقسیم کے لیے رقم (وصول شدہ)',
                            style: TextStyle(color: Colors.black54),
                          ),
                          Text(
                            '${totalAmount.toStringAsFixed(0)} روپے',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildShareRow(
                  'حصہ 1 (20%)',
                  '${eachShare.toStringAsFixed(0)} روپے',
                ),
                _buildShareRow(
                  'حصہ 2 (20%)',
                  '${eachShare.toStringAsFixed(0)} روپے',
                ),
                _buildShareRow(
                  'حصہ 3 (20%)',
                  '${eachShare.toStringAsFixed(0)} روپے',
                ),
                _buildShareRow(
                  'حصہ 4 (20%)',
                  '${eachShare.toStringAsFixed(0)} روپے',
                ),
                _buildShareRow(
                  'حصہ 5 (20%)',
                  '${eachShare.toStringAsFixed(0)} روپے',
                ),
              ],
            ),
          );
        },
      ),
      // bottomNavigationBar: BottomNavigationBar(
      //   currentIndex: 0,
      //   type: BottomNavigationBarType.fixed,
      //   selectedItemColor: const Color(0xFF0C7A43),
      //   unselectedItemColor: Colors.grey,
      //   items: const [
      //     BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: 'تقسیم'),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.trending_up),
      //       label: 'رپورٹ',
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.receipt_long),
      //       label: 'وصولیاں',
      //     ),
      //     BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'کھاتہ'),
      //     BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ہوم'),
      //   ],
      // ),
    );
  }

  Widget _buildShareRow(String title, String amount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEBEBEB)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16)),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
