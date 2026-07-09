import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WasooliyanOverviewScreen extends StatefulWidget {
  const WasooliyanOverviewScreen({super.key});

  @override
  State<WasooliyanOverviewScreen> createState() =>
      _WasooliyanOverviewScreenState();
}

class _WasooliyanOverviewScreenState extends State<WasooliyanOverviewScreen> {
  int activeTab = 1;
  String? selectedCustomer; // Class level variable

  // Collector tab index ke mutabiq sahi naam dene ke liye helper function
  String _getCollectorName(int tabIndex) {
    return tabIndex == 1 ? 'عبدالغفور' : 'محمد ارشد';
  }

  void _openAddWasooliDialog() {
    final TextEditingController amountController = TextEditingController();
    selectedCustomer = null; // Reset selection on open

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 20,
              left: 20,
              right: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'نئی وصولی درج کریں',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),

                // Safe Fetch for Dropdown to prevent crashes
                FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('customers')
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return const Text(
                        'کسٹمرز کا ڈیٹا لوڈ کرنے میں مسئلہ ہے۔',
                      );
                    }

                    // محفوظ طریقے سے نام نکالنا تاکہ کریش نہ ہو
                    final List<String> customers = snapshot.data!.docs
                        .map((doc) {
                          final data = doc.data() as Map<String, dynamic>?;
                          if (data != null && data.containsKey('name')) {
                            return data['name'].toString().trim();
                          }
                          return "";
                        })
                        .where((name) => name.isNotEmpty)
                        .toSet() // ڈپلیکیٹ ناموں سے بچاؤ
                        .toList();

                    if (customers.isEmpty) {
                      return const Text('کوئی کسٹمر موجود نہیں ہے۔');
                    }

                    return DropdownButtonFormField<String>(
                      value: selectedCustomer,
                      decoration: const InputDecoration(
                        labelText: "کسٹمر منتخب کریں",
                        border: OutlineInputBorder(),
                      ),
                      items: customers.map((customer) {
                        return DropdownMenuItem(
                          value: customer,
                          child: Text(customer),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setStateModal(() {
                          selectedCustomer = value;
                        });
                      },
                    );
                  },
                ),

                const SizedBox(height: 15),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "وصول شدہ رقم (روپے)",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0C7A43),
                    ),
                    onPressed: () async {
                      String amountStr = amountController.text.trim();
                      if (selectedCustomer == null || amountStr.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('براہ کرم کسٹمر اور رقم درج کریں'),
                          ),
                        );
                        return;
                      }

                      double? amount = double.tryParse(amountStr);
                      if (amount == null || amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('براہ کرم درست رقم درج کریں'),
                          ),
                        );
                        return;
                      }

                      try {
                        await FirebaseFirestore.instance
                            .collection('receipts')
                            .add({
                              'customer_name': selectedCustomer,
                              'today_received': amount,
                              'collector': _getCollectorName(activeTab),
                              'date': Timestamp.now(),
                            });

                        if (!mounted)
                          return; // محفوظ طریقہ (Deactivated widget fix)
                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('وصولی کامیابی سے محفوظ ہو گئی ہے'),
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('خرابی: $e')));
                      }
                    },
                    child: const Text(
                      'محفوظ کریں',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String currentCollector = _getCollectorName(activeTab);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7FBF6),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0C7A43),
          elevation: 0,
          title: const Text(
            'وصولیاں کا جائزہ',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Column(
          children: [
            // Tabs Row
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTabButton('عبدالغفور', 1),
                  _buildTabButton('محمد ارشد', 2),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Top Summary Card
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('receipts')
                  .where('collector', isEqualTo: currentCollector)
                  .snapshots(),
              builder: (context, snapshot) {
                double totalReceived = 0;
                if (snapshot.hasData) {
                  for (var doc in snapshot.data!.docs) {
                    var data = doc.data() as Map<String, dynamic>;
                    totalReceived += (data['today_received'] ?? 0).toDouble();
                  }
                }

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C7A43),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'کل وصولی رقم',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${totalReceived.toStringAsFixed(0)} روپے',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white70,
                        size: 40,
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'تفصیلی لسٹ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E4620),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Receipts Real-time List (FIXED QUERY AND LOCAL SORT)
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('receipts')
                    .where('collector', isEqualTo: currentCollector)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF0C7A43),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('خرابی: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('کوئی وصولی ریکارڈ نہیں ملی۔'),
                    );
                  }

                  // === FIX: Stream se orderBy hata kar list ko memory me sort kiya ===
                  List<DocumentSnapshot> docsList = snapshot.data!.docs;
                  docsList.sort((a, b) {
                    var dataA = a.data() as Map<String, dynamic>?;
                    var dataB = b.data() as Map<String, dynamic>?;
                    Timestamp tA = dataA?['date'] ?? Timestamp.now();
                    Timestamp tB = dataB?['date'] ?? Timestamp.now();
                    return tB.compareTo(tA); // Descending order sort
                  });

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: docsList.length,
                    itemBuilder: (context, index) {
                      var doc = docsList[index];
                      var data = doc.data() as Map<String, dynamic>;

                      String name =
                          data['customer_name'] ?? 'بغیر نام کا کسٹمر';
                      double amt = (data['today_received'] ?? 0).toDouble();

                      return _buildDetailsRow(
                        name,
                        '${amt.toStringAsFixed(0)} روپے',
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFF0C7A43),
          onPressed: _openAddWasooliDialog,
          child: const Icon(Icons.add, color: Colors.white, size: 30),
        ),
      ),
    );
  }

  Widget _buildTabButton(String text, int index) {
    bool isSelected = activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => activeTab = index),
      child: Column(
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? const Color(0xFF0C7A43) : Colors.grey,
            ),
          ),
          if (isSelected)
            Container(height: 3, width: 80, color: const Color(0xFF0C7A43)),
        ],
      ),
    );
  }

  Widget _buildDetailsRow(String name, String amount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEBEBEB)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0C7A43),
            ),
          ),
        ],
      ),
    );
  }
}
