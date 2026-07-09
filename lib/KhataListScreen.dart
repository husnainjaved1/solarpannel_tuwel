import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:solarpannel_tuwel/costumer_detail.dart'; // اپنی فائل کا درست پاتھ چیک کر لیں

class KhataListScreen extends StatefulWidget {
  const KhataListScreen({super.key});

  @override
  State<KhataListScreen> createState() => _KhataListScreenState();
}

class _KhataListScreenState extends State<KhataListScreen> {
  // Search text کو ٹریک کرنے کے لیے کنٹرولر اور سٹرنگ
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  double _safeParseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  // کسٹمر کو فائر بیس سے ڈیلیٹ کرنے کا فنکشن
  Future<void> _deleteCustomerData(String customerName) async {
    final entryQuery = await FirebaseFirestore.instance
        .collection('entries')
        .where('customer_name', isEqualTo: customerName)
        .get();
    for (var doc in entryQuery.docs) {
      await doc.reference.delete();
    }

    final receiptQuery = await FirebaseFirestore.instance
        .collection('receipts')
        .where('customer_name', isEqualTo: customerName)
        .get();
    for (var doc in receiptQuery.docs) {
      await doc.reference.delete();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // یہاں پکی تسلی کر لیتے ہیں کہ نل ویلیو نہ رہے
    final bool showClearIcon = _searchQuery.trim().isNotEmpty;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0C7A43),
          title: const Text(
            'کسٹمر لسٹ ریکارڈ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          elevation: 0,
        ),
        body: Column(
          children: [
            // ================= SEARCH BAR FIXED =================
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'کسٹمر کا نام تلاش کریں...',
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF0C7A43),
                    ),
                    suffixIcon: showClearIcon
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = "";
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                  ),
                ),
              ),
            ),

            // کسٹمرز کی لسٹ والا حصہ
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('entries')
                    .snapshots(),
                builder: (context, entrySnapshot) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('receipts')
                        .snapshots(),
                    builder: (context, receiptSnapshot) {
                      if (entrySnapshot.connectionState ==
                              ConnectionState.waiting ||
                          receiptSnapshot.connectionState ==
                              ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF0C7A43),
                          ),
                        );
                      }

                      Map<String, Map<String, dynamic>> customerMap = {};

                      // 1. Entries سے ڈیٹا کیلکولیٹ کریں
                      if (entrySnapshot.hasData) {
                        for (var doc in entrySnapshot.data!.docs) {
                          var data = doc.data() as Map<String, dynamic>;
                          String name = data['customer_name'] ?? 'نامعلوم';

                          if (!customerMap.containsKey(name)) {
                            customerMap[name] = {
                              'name': name,
                              'hours': 0.0,
                              'minutes': 0.0,
                              'total_amount': 0.0,
                              'total_received': 0.0,
                            };
                          }

                          customerMap[name]!['hours'] += _safeParseDouble(
                            data['hours'],
                          );
                          customerMap[name]!['minutes'] += _safeParseDouble(
                            data['minutes'],
                          );
                          customerMap[name]!['total_amount'] +=
                              _safeParseDouble(data['total_amount']);
                        }
                      }

                      // 2. Receipts سے ڈیٹا کیلکولیٹ کریں
                      if (receiptSnapshot.hasData) {
                        for (var doc in receiptSnapshot.data!.docs) {
                          var data = doc.data() as Map<String, dynamic>;
                          String name = data['customer_name'] ?? 'نامعلوم';

                          if (!customerMap.containsKey(name)) {
                            customerMap[name] = {
                              'name': name,
                              'hours': 0.0,
                              'minutes': 0.0,
                              'total_amount': 0.0,
                              'total_received': 0.0,
                            };
                          }

                          customerMap[name]!['total_received'] +=
                              _safeParseDouble(data['today_received']);
                        }
                      }

                      // تمام کسٹمرز کو لسٹ میں تبدیل کریں
                      List<Map<String, dynamic>> allCustomers = customerMap
                          .values
                          .toList();

                      // ================= SEARCH FILTER LOGIC FIXED =================
                      List<Map<String, dynamic>> filteredCustomers =
                          allCustomers;
                      if (_searchQuery.trim().isNotEmpty) {
                        filteredCustomers = allCustomers.where((customer) {
                          final String customerName = (customer['name'] ?? '')
                              .toString()
                              .toLowerCase();
                          return customerName.contains(
                            _searchQuery.trim().toLowerCase(),
                          );
                        }).toList();
                      }

                      if (filteredCustomers.isEmpty) {
                        return const Center(
                          child: Text(
                            'کوئی کسٹمر میچ نہیں ہوا یا کھاتہ موجود نہیں ہے۔',
                            style: TextStyle(fontSize: 15, color: Colors.grey),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredCustomers.length,
                        itemBuilder: (context, index) {
                          var customer = filteredCustomers[index];

                          double cHours = customer['hours'];
                          double cMinutes = customer['minutes'];
                          cHours += (cMinutes / 60).floor();
                          cMinutes = cMinutes % 60;

                          double netBalance =
                              customer['total_amount'] -
                              customer['total_received'];

                          String balanceStatus = netBalance < 0
                              ? " روپے (جمع)"
                              : " روپے";
                          double displayBalance = netBalance.abs();

                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CostumerDetail(
                                    customerName: customer['name'],
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.02),
                                    spreadRadius: 1,
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // ڈیلیٹ کا بٹن
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () {
                                      _showDeleteDialog(customer['name']);
                                    },
                                  ),

                                  // رقم اور اسٹیٹس
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${displayBalance.toStringAsFixed(0)}$balanceStatus",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: netBalance < 0
                                              ? Colors.blue.shade700
                                              : Colors.red.shade700,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const Spacer(),

                                  // کسٹمر کا نام اور گھنٹے
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        customer['name'],
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${cHours.toInt()} گھنٹے ${cMinutes.toInt()} منٹ",
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('کھاتہ حذف کریں؟', textAlign: TextAlign.right),
        content: Text(
          'کیا آپ واقعی $name کا پورا ریکارڈ حذف کرنا چاہتے ہیں؟',
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('نہیں'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteCustomerData(name);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$name کا ریکارڈ حذف کر دیا گیا ہے۔')),
              );
            },
            child: const Text(
              'ہاں، حذف کریں',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
