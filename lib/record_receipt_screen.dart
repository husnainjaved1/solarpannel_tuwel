import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecordReceiptScreen extends StatefulWidget {
  const RecordReceiptScreen({super.key});

  @override
  State<RecordReceiptScreen> createState() => _RecordReceiptScreenState();
}

class _RecordReceiptScreenState extends State<RecordReceiptScreen> {
  int activeTab = 1;
  String? _selectedCustomer;
  final _amountController = TextEditingController();
  bool _isLoading = false;

  Future<void> _saveReceipt() async {
    // Validation check
    if (_selectedCustomer == null || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('براہ کرم کسٹمر منتخب کریں اور رقم درج کریں'),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('receipts').add({
        'customer_name': _selectedCustomer,
        'today_received': double.tryParse(_amountController.text) ?? 0.0,
        'collector': activeTab == 1 ? 'عبدالغفور' : 'محمد ارشد',
        'date': Timestamp.now(),
      });

      // کنٹیکسٹ کا محفوظ استعمال (Deactivated widget error fix)
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خرابی: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C7A43),
        title: const Text(
          'وصولی درج کریں',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildTabButton('عبدالغفور', 1)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTabButton('محمد ارشد', 2)),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    'کسٹمر منتخب کریں',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 6),

                  // Searchable Dropdown with Safe Field Lookup
                  FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('customers')
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (snapshot.hasError || !snapshot.hasData) {
                        return const Text(
                          'کسٹمرز کا ڈیٹا لوڈ کرنے میں مسئلہ ہے۔',
                        );
                      }

                      // محفوظ طریقہ: ہر ڈاکومنٹ کا ڈیٹا میپ چیک کریں تاکہ 'name' نہ ہونے پر کریش نہ ہو
                      final List<String> customers = snapshot.data!.docs
                          .map((doc) {
                            final data = doc.data() as Map<String, dynamic>?;
                            if (data != null && data.containsKey('name')) {
                              return data['name'].toString().trim();
                            }
                            return ""; // اگر نام نہیں ہے تو خالی چھوڑیں
                          })
                          .where((name) => name.isNotEmpty) // خالی نام نکال دیں
                          .toSet() // ڈپلیکیٹ نام ختم کرنے کے لیے
                          .toList();

                      if (customers.isEmpty) {
                        return const Text('کوئی کسٹمر موجود نہیں ہے۔');
                      }

                      // اگر منتخب کردہ کسٹمر اب لسٹ میں نہیں ہے تو ویلیو نل کر دیں
                      if (_selectedCustomer != null &&
                          !customers.contains(_selectedCustomer)) {
                        _selectedCustomer = null;
                      }

                      return DropdownButtonFormField<String>(
                        value: _selectedCustomer,
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
                          setState(() {
                            _selectedCustomer = value;
                          });
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    'آج وصولی رقم',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 6),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F9F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'رقم لکھیں...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveReceipt,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0C7A43),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'محفوظ کریں',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, int index) {
    return GestureDetector(
      onTap: () => setState(() => activeTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: activeTab == index
              ? const Color(0xFF0C7A43)
              : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: activeTab == index ? Colors.white : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }
}
