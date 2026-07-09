import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:solarpannel_tuwel/costumer_detail.dart';

class CustomerLedgerScreen extends StatelessWidget {
  const CustomerLedgerScreen({super.key});

  // String یا کسی بھی غلط ڈیٹا ٹائپ کو محفوظ طریقے سے نمبر میں تبدیل کرنے والا فنکشن
  double _safeParseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  // Customer ka sara data delete karne ka function
  void _deleteCustomerPrompt(BuildContext context, String customerName) {
    showDialog(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('ریکارڈ حذف کریں؟'),
          content: Text(
            'کیا آپ سچ میں $customerName کا تمام ریکارڈ (انٹریز اور وصولی) ڈیلیٹ کرنا چاہتے ہیں؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('کینسل'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(dialogContext);

                // Entries delete karna
                var entriesQuery = await FirebaseFirestore.instance
                    .collection('entries')
                    .where('customer_name', isEqualTo: customerName)
                    .get();
                for (var doc in entriesQuery.docs) {
                  await doc.reference.delete();
                }

                // Receipts delete karna
                var receiptsQuery = await FirebaseFirestore.instance
                    .collection('receipts')
                    .where('customer_name', isEqualTo: customerName)
                    .get();
                for (var doc in receiptsQuery.docs) {
                  await doc.reference.delete();
                }

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '$customerName کا ریکارڈ کامیابی سے ڈیلیٹ ہو گیا',
                      ),
                    ),
                  );
                }
              },
              child: const Text(
                'ڈیلیٹ کریں',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
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
            'کسٹمر لسٹ ریکارڈ',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('entries').snapshots(),
          builder: (context, entrySnapshot) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('receipts')
                  .snapshots(),
              builder: (context, receiptSnapshot) {
                if (entrySnapshot.connectionState == ConnectionState.waiting ||
                    receiptSnapshot.connectionState ==
                        ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF0C7A43)),
                  );
                }

                if (!entrySnapshot.hasData) {
                  return const Center(child: Text('کوئی ریکارڈ نہیں ملا'));
                }

                // Map banayenge customerwise data merge karne ke liye
                Map<String, Map<String, dynamic>> customerMap = {};

                // 1. Saari entries ko customer ke mutabiq jama (merge) karenge
                for (var doc in entrySnapshot.data!.docs) {
                  var data = doc.data() as Map<String, dynamic>;
                  String name = data['customer_name'] ?? 'نامعلوم';
                  double amount = _safeParseDouble(data['total_amount']);
                  double hours = _safeParseDouble(data['hours']);
                  double minutes = _safeParseDouble(data['minutes']);
                  Timestamp date = data['date'] ?? Timestamp.now();

                  if (customerMap.containsKey(name)) {
                    customerMap[name]!['total_amount'] += amount;
                    customerMap[name]!['hours'] += hours;
                    customerMap[name]!['minutes'] += minutes;

                    Timestamp existingDate = customerMap[name]!['date'];
                    if (date.compareTo(existingDate) > 0) {
                      customerMap[name]!['date'] = date;
                    }
                  } else {
                    customerMap[name] = {
                      'customer_name': name,
                      'total_amount': amount,
                      'hours': hours,
                      'minutes': minutes,
                      'date': date,
                    };
                  }
                }

                // 2. Receipts (wasooli) nikal kar total amount se minus karenge
                if (receiptSnapshot.hasData) {
                  for (var doc in receiptSnapshot.data!.docs) {
                    var data = doc.data() as Map<String, dynamic>;
                    String name = data['customer_name'] ?? 'نامعلوم';
                    double received = _safeParseDouble(data['today_received']);
                    Timestamp date = data['date'] ?? Timestamp.now();

                    if (customerMap.containsKey(name)) {
                      customerMap[name]!['total_amount'] -= received;

                      Timestamp existingDate = customerMap[name]!['date'];
                      if (date.compareTo(existingDate) > 0) {
                        customerMap[name]!['date'] = date;
                      }
                    } else {
                      // Agar kisi customer ki entry nahi hai par sirf raqam wasool hui hai
                      customerMap[name] = {
                        'customer_name': name,
                        'total_amount':
                            -received, // Minus show karega ke advance jama hai
                        'hours': 0.0,
                        'minutes': 0.0,
                        'date': date,
                      };
                    }
                  }
                }

                // 3. List banayenge aur SIRF 0 balance wale customers ko remove karenge
                List<Map<String, dynamic>> customerList = [];
                customerMap.forEach((key, value) {
                  double totalMin = value['minutes'];
                  double extraHours = (totalMin / 60).floorToDouble();
                  value['hours'] += extraHours;
                  value['minutes'] = (totalMin % 60).toInt();

                  // Agar amount 0 ke barabar nahi hai (yaani chahe positive ho ya minus/advance ho) toh dikhayen
                  if (value['total_amount'] != 0) {
                    customerList.add(value);
                  }
                });

                // 4. Nayi entry/receipt wale customers ko top par lane ke liye sort karna
                customerList.sort((a, b) {
                  Timestamp tA = a['date'];
                  Timestamp tB = b['date'];
                  return tB.compareTo(tA);
                });

                if (customerList.isEmpty) {
                  return const Center(
                    child: Text('کوئی بقایاجات والا کسٹمر موجود نہیں ہے'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: customerList.length,
                  itemBuilder: (context, index) {
                    var data = customerList[index];
                    double remainingAmount = data['total_amount'];

                    // Agar amount minus mein hai, toh iska matlab hai unho ne zyada paise jama karwaye hain
                    bool isAdvance = remainingAmount < 0;
                    // Display ke liye minus ka sign khatam karne ke liye absolute value (.abs()) use karenge
                    double displayAmount = remainingAmount.abs();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CostumerDetail(
                                customerName: data['customer_name'] ?? '',
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Right Side: Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['customer_name'] ?? 'نامعلوم',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${data['hours'].toInt()} گھنٹے ${data['minutes']} منٹ',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Left Side: Amount and Delete Action
                              Row(
                                children: [
                                  Text(
                                    isAdvance
                                        ? '${displayAmount.toStringAsFixed(0)} روپے (جمع)' // 1500 روپے (جمع)
                                        : '${displayAmount.toStringAsFixed(0)} روپے', // 3500 روپے (باقیا)
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      // Agar advance jama ho toh blue ya orange color de sakte hain, warna standard green
                                      color: isAdvance
                                          ? Colors.blue.shade700
                                          : const Color(0xFF0C7A43),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () {
                                      _deleteCustomerPrompt(
                                        context,
                                        data['customer_name'],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
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
    );
  }
}
