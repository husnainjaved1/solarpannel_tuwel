import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:solarpannel_tuwel/KhataListScreen.dart';
import 'package:solarpannel_tuwel/NewEntryScreen.dart';
import 'package:solarpannel_tuwel/baqayajat.dart';
import 'package:solarpannel_tuwel/reports_screen.dart';
import 'package:solarpannel_tuwel/wasooliyan_overview_screen.dart';
import 'taqseem_screen.dart';
import 'record_receipt_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _safeParseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  int _selectedIndex = 4; // 'ہوم' منتخب ہے

  // 1. Apni screens ki list banayen (yahan apni files ke naam likhen)
  late final List<Widget> _screens = [
    const TaqseemScreen(), // 'تقسیم'
    const ReportsScreen(), // 'رپورٹ'
    const WasooliyanOverviewScreen(), // 'وصولیاں'
    KhataListScreen(), // 'کسٹمر کھاتہ'
    const HomeScreen(), // 'ہوم'
  ];

  // 2. Tab change karne ka function
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Color(0xFF1E4620)),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none,
              color: Color(0xFF1E4620),
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: _selectedIndex == 4
          ? StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('entries')
                  .snapshots(),
              builder: (context, entriesSnapshot) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('receipts')
                      .snapshots(),
                  builder: (context, receiptsSnapshot) {
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('customers')
                          .snapshots(),
                      builder: (context, customersSnapshot) {
                        double totalIncome = 0.0;
                        double totalReceived = 0.0;
                        int totalCustomers = customersSnapshot.hasData
                            ? customersSnapshot.data!.docs.length
                            : 0;

                        if (entriesSnapshot.hasData) {
                          for (var doc in entriesSnapshot.data!.docs) {
                            var data = doc.data() as Map<String, dynamic>;
                            totalIncome += _safeParseDouble(
                              data['total_amount'],
                            );
                          }
                        }

                        if (receiptsSnapshot.hasData) {
                          for (var doc in receiptsSnapshot.data!.docs) {
                            var data = doc.data() as Map<String, dynamic>;
                            totalReceived += _safeParseDouble(
                              data['today_received'],
                            );
                          }
                        }

                        double remaining = totalIncome - totalReceived;

                        return SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: const [
                                            Text(
                                              'سولر ٹیوب ویل',
                                              style: TextStyle(
                                                fontSize: 28,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1E4620),
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'حساب کتاب سسٹم',
                                              style: TextStyle(
                                                fontSize: 18,
                                                color: Color(0xFF555555),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          children: const [
                                            Icon(
                                              Icons.wb_sunny,
                                              color: Colors.orange,
                                              size: 30,
                                            ),
                                            Icon(
                                              Icons.solar_power,
                                              color: Colors.blue,
                                              size: 50,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                        horizontal: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: const [
                                          Icon(
                                            Icons.calendar_month,
                                            color: Colors.grey,
                                          ),
                                          Text(
                                            'لائیو ریکارڈ',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_back_ios,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'آج کا خلاصہ',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.2,
                                children: [
                                  _buildSummaryCard(
                                    'کل وصولی',
                                    totalReceived.toStringAsFixed(0),
                                    'روپے',
                                    Icons.description,
                                    Colors.blue.shade50,
                                    Colors.blue,
                                  ),
                                  _buildSummaryCard(
                                    'کل آمدنی',
                                    totalIncome.toStringAsFixed(0),
                                    'روپے',
                                    Icons.calendar_today,
                                    Colors.green.shade50,
                                    Colors.green,
                                  ),
                                  _buildSummaryCard(
                                    'کل گاہک',
                                    totalCustomers.toString(),
                                    'کسٹمر',
                                    Icons.assignment_ind,
                                    Colors.purple.shade50,
                                    Colors.purple,
                                  ),
                                  _buildSummaryCard(
                                    'بقایاجات',
                                    remaining.toStringAsFixed(0),
                                    'روپے',
                                    Icons.person_search,
                                    Colors.orange.shade50,
                                    Colors.orange,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'فوری ایکشن',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildActionButton(
                                    context,
                                    'تقسیم کریں',
                                    Icons.pie_chart,
                                    Colors.purple.shade50,
                                    Colors.purple,
                                    () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const TaqseemScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  _buildActionButton(
                                    context,
                                    'بقایاجات',
                                    Icons.description,
                                    Colors.orange.shade50,
                                    Colors.orange,
                                    () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const CustomerLedgerScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  _buildActionButton(
                                    context,
                                    'وصولی درج کریں',
                                    Icons.account_balance_wallet,
                                    Colors.blue.shade50,
                                    Colors.blue,
                                    () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const RecordReceiptScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  _buildActionButton(
                                    context,
                                    'نیا اندراج',
                                    Icons.person_add,
                                    Colors.green.shade50,
                                    Colors.green,
                                    () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const NewEntryScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 40),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            )
          : _screens[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex, // Static 4 ki jagah variable use karen
        onTap: _onItemTapped, // Ye function call hoga
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF0C7A43),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: 'تقسیم'),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'رپورٹ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'وصولیاں',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'کھاتہ'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ہوم'),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    String unit,
    IconData icon,
    Color bgColor,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: bgColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: iconColor, size: 30),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  unit,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color bgColor,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
