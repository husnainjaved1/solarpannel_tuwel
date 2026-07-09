// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:solarpannel_tuwel/NewEntryScreen.dart';
import 'package:solarpannel_tuwel/edit_customer_screen.dart';
import 'package:solarpannel_tuwel/record_receipt_screen.dart';

class CostumerDetail extends StatefulWidget {
  final String customerName;

  const CostumerDetail({super.key, required this.customerName});

  @override
  State<CostumerDetail> createState() => _CostumerDetailState();
}

class _CostumerDetailState extends State<CostumerDetail>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  double _safeParseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  String _getUrduMonth(int month) {
    const months = [
      'جنوری',
      'فروری',
      'مارچ',
      'اپریل',
      'مئی',
      'جون',
      'جولائی',
      'اگست',
      'ستمبر',
      'اکتوبر',
      'نومبر',
      'دسمبر',
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 2);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0C7A43),
          title: const Text(
            'کسٹمر کھاتہ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EditCustomerScreen(currentName: widget.customerName),
                  ),
                );
              },
            ),
          ],
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('entries')
              .where('customer_name', isEqualTo: widget.customerName)
              .snapshots(),
          builder: (context, entrySnapshot) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('receipts')
                  .where('customer_name', isEqualTo: widget.customerName)
                  .snapshots(),
              builder: (context, receiptSnapshot) {
                if (entrySnapshot.connectionState == ConnectionState.waiting ||
                    receiptSnapshot.connectionState ==
                        ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF0C7A43)),
                  );
                }

                // ignore: unused_local_variable
                double totalHours = 0;
                double totalMinutes = 0;
                double totalAmount = 0;
                String mobileNo = "فون نمبر موجود نہیں";

                if (entrySnapshot.hasData) {
                  for (var doc in entrySnapshot.data!.docs) {
                    var data = doc.data() as Map<String, dynamic>;
                    totalHours += _safeParseDouble(data['hours']);
                    totalMinutes += _safeParseDouble(data['minutes']);
                    totalAmount += _safeParseDouble(data['total_amount']);

                    // یہاں پر دونوں کیز (customer_phone اور mobile_number) کو چیک کر لیا ہے
                    if (data['customer_phone'] != null &&
                        data['customer_phone'].toString().trim().isNotEmpty) {
                      mobileNo = data['customer_phone'].toString();
                    } else if (data['mobile_number'] != null &&
                        data['mobile_number'].toString().trim().isNotEmpty) {
                      mobileNo = data['mobile_number'].toString();
                    }
                  }
                }

                if (mobileNo == "فون نمبر موجود نہیں" &&
                    receiptSnapshot.hasData) {
                  for (var doc in receiptSnapshot.data!.docs) {
                    var data = doc.data() as Map<String, dynamic>;
                    if (data['customer_phone'] != null &&
                        data['customer_phone'].toString().trim().isNotEmpty) {
                      mobileNo = data['customer_phone'].toString();
                      break;
                    } else if (data['mobile_number'] != null &&
                        data['mobile_number'].toString().trim().isNotEmpty) {
                      mobileNo = data['mobile_number'].toString();
                      break;
                    }
                  }
                }

                totalHours += (totalMinutes / 60).floor();
                totalMinutes = totalMinutes % 60;

                double totalReceived = 0;
                if (receiptSnapshot.hasData) {
                  for (var doc in receiptSnapshot.data!.docs) {
                    var data = doc.data() as Map<String, dynamic>;
                    totalReceived += _safeParseDouble(data['today_received']);
                  }
                }

                double balance = totalAmount - totalReceived;

                List<Map<String, dynamic>> rawTransactions = [];
                if (entrySnapshot.hasData) {
                  for (var doc in entrySnapshot.data!.docs) {
                    var data = doc.data() as Map<String, dynamic>;
                    rawTransactions.add({
                      'type': 'entry',
                      'date': data['date'],
                      'hours': data['hours'] ?? '0',
                      'minutes': data['minutes'] ?? '0',
                      'amount': _safeParseDouble(data['total_amount']),
                      'collector': data['note'] ?? 'اندراج ریکارڈ',
                    });
                  }
                }
                if (receiptSnapshot.hasData) {
                  for (var doc in receiptSnapshot.data!.docs) {
                    var data = doc.data() as Map<String, dynamic>;
                    rawTransactions.add({
                      'type': 'receipt',
                      'date': data['date'],
                      'hours': '0',
                      'minutes': '0',
                      'amount': _safeParseDouble(data['today_received']),
                      'collector':
                          data['collector'] ?? data['note'] ?? 'نام موجود نہیں',
                    });
                  }
                }

                rawTransactions.sort((a, b) {
                  Timestamp tA = a['date'] ?? Timestamp.now();
                  Timestamp tB = b['date'] ?? Timestamp.now();
                  return tA.compareTo(tB);
                });

                double runningBalance = 0.0;
                List<Map<String, dynamic>> finalTransactions = [];

                for (var tx in rawTransactions) {
                  double previousBalance = runningBalance;
                  double txAmount = tx['amount'];

                  if (tx['type'] == 'entry') {
                    runningBalance += txAmount;
                  } else {
                    runningBalance -= txAmount;
                  }

                  finalTransactions.add({
                    ...tx,
                    'previous_balance': previousBalance,
                    'remaining_balance': runningBalance,
                  });
                }

                List<Map<String, dynamic>> displayTransactions = List.from(
                  finalTransactions.reversed,
                );

                return Column(
                  children: [
                    // Profile Header section
                    Container(
                      color: const Color(0xFFF9F9F9),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 35,
                              backgroundColor: Colors.blue.shade50,
                              child: const Icon(
                                Icons.person,
                                size: 50,
                                color: Color(0xFF4A80F0),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.customerName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            mobileNo,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Top 3 Metric Cards Grid
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildTopMetric(
                                'کل رقم',
                                totalAmount.toStringAsFixed(0),
                                'روپے',
                                Colors.black,
                              ),
                            ),
                            Container(
                              height: 40,
                              width: 1,
                              color: Colors.grey.shade200,
                            ),
                            Expanded(
                              child: _buildTopMetric(
                                'کل وصول شدہ',
                                totalReceived.toStringAsFixed(0),
                                'روپے',
                                const Color(0xFF0C7A43),
                              ),
                            ),
                            Container(
                              height: 40,
                              width: 1,
                              color: Colors.grey.shade200,
                            ),
                            Expanded(
                              child: _buildTopMetric(
                                'باقی بقایاجات',
                                balance.toStringAsFixed(0),
                                'روپے',
                                Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Navigation Tabs
                    Container(
                      height: 45,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicatorColor: const Color(0xFF0C7A43),
                        labelColor: const Color(0xFF0C7A43),
                        unselectedLabelColor: Colors.grey,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        tabs: const [
                          Tab(text: 'بقایاجات'),
                          Tab(text: 'وصولی'),
                          Tab(text: 'تفصیل'),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          _tabController.index == 2
                              ? 'تمام کھاتہ تفصیل (تفصیلی بقایاجات)'
                              : _tabController.index == 1
                              ? 'تمام وصولیاں (نام کے ساتھ)'
                              : 'باقی بقایاجات کا ریکارڈ',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildList(
                            displayTransactions
                                .where((tx) => tx['type'] == 'entry')
                                .toList(),
                            'بقایا',
                          ),
                          _buildList(
                            displayTransactions
                                .where((tx) => tx['type'] == 'receipt')
                                .toList(),
                            'وصول',
                          ),
                          _buildList(displayTransactions, 'mix'),
                        ],
                      ),
                    ),

                    // ================= BOTTOM BUTTONS =================
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0C7A43),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const RecordReceiptScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'وصولی درج کریں',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B6CD4),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const NewEntryScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'نیا اندراج',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopMetric(
    String title,
    String value,
    String unit,
    Color valColor,
  ) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: valColor,
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            fontSize: 11,
            color: valColor == Colors.red ? Colors.red : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items, String statusType) {
    if (items.isEmpty) {
      return const Center(child: Text('کوئی ریکارڈ موجود نہیں ہے۔'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        var tx = items[index];
        String dateStr = '';
        if (tx['date'] is Timestamp) {
          DateTime dt = (tx['date'] as Timestamp).toDate();
          dateStr = '${dt.day} ${_getUrduMonth(dt.month)} ${dt.year}';
        }

        bool isEntry = tx['type'] == 'entry';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateStr,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isEntry
                          ? const Color(0xFFFFEBEE)
                          : const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isEntry ? 'بل اندراج' : 'رقم وصولی',
                      style: TextStyle(
                        color: isEntry
                            ? Colors.red.shade700
                            : Colors.green.shade700,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 16, thickness: 0.5),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEntry
                            ? '${tx['hours'].toString().padLeft(2, '0')}:${tx['minutes'].toString().padLeft(2, '0')} گھنٹے'
                            : '${tx['collector']}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isEntry
                              ? Colors.black87
                              : const Color(0xFF0C7A43),
                        ),
                      ),
                      Text(
                        isEntry ? 'چلا ہوا وقت' : 'وصول کرنے والا بندہ',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isEntry ? "+" : "-"}${tx['amount'].toStringAsFixed(0)} روپے',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isEntry
                              ? Colors.red.shade700
                              : Colors.green.shade700,
                        ),
                      ),
                      Text(
                        isEntry ? 'کل بنا ہوا بل' : 'آج وصول کی گئی رقم',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          _safeParseDouble(
                            tx['previous_balance'],
                          ).toStringAsFixed(0),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const Text(
                          'سابقہ بقایا',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.arrow_left,
                      size: 16,
                      color: Colors.grey.shade400,
                    ),
                    Column(
                      children: [
                        Text(
                          tx['amount'].toStringAsFixed(0),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isEntry
                                ? Colors.red.shade400
                                : Colors.green.shade400,
                          ),
                        ),
                        Text(
                          isEntry ? 'مزید بل' : 'رقم وصول شدہ',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.arrow_left,
                      size: 16,
                      color: Colors.grey.shade400,
                    ),
                    Column(
                      children: [
                        Text(
                          _safeParseDouble(
                            tx['remaining_balance'],
                          ).toStringAsFixed(0),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const Text(
                          'نیٹ باقی کھاتہ',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
