import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// نیلے رنگ کا ایرر ختم کرنے کے لیے اپنی کسٹمر اسکرین کا صحیح پاتھ امپورٹ کریں
import 'add_customer_screen.dart';

class NewEntryScreen extends StatefulWidget {
  const NewEntryScreen({super.key});

  @override
  State<NewEntryScreen> createState() => _NewEntryScreenState();
}

class _NewEntryScreenState extends State<NewEntryScreen> {
  final _mobileController = TextEditingController();
  final _hoursController = TextEditingController(text: '02');
  final _minutesController = TextEditingController(text: '45');
  final _rateController = TextEditingController(text: '1000');
  final _noteController = TextEditingController();

  String? selectedCustomer;
  double totalAmount = 2750.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Controllers me badlav aane par automatic calculation ke liye listeners
    _hoursController.addListener(_calculateTotal);
    _minutesController.addListener(_calculateTotal);
    _rateController.addListener(_calculateTotal);
  }

  void _calculateTotal() {
    double hours = double.tryParse(_hoursController.text) ?? 0.0;
    double minutes = double.tryParse(_minutesController.text) ?? 0.0;
    double rate = double.tryParse(_rateController.text) ?? 0.0;

    double totalHours = hours + (minutes / 60.0);
    setState(() {
      totalAmount = totalHours * rate;
    });
  }

  Future<void> _saveEntry() async {
    if (selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('براہ کرم کسٹمر منتخب کریں')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('entries').add({
        'customer_name': selectedCustomer,
        'customer_phone': _mobileController.text.trim(),
        'hours': double.tryParse(_hoursController.text) ?? 0.0,
        'minutes': double.tryParse(_minutesController.text) ?? 0.0,
        'rate': double.tryParse(_rateController.text) ?? 0.0,
        'total_amount': totalAmount,
        'note': _noteController.text.trim(),
        'date': Timestamp.now(),
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اندراج کامیابی سے محفوظ ہو گیا')),
      );
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
  void dispose() {
    _mobileController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    _rateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String displayHours = _hoursController.text.padLeft(2, '0');
    String displayMinutes = _minutesController.text.padLeft(2, '0');

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7FBF6),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0C7A43),
          elevation: 0,
          title: const Text(
            'نیا اندراج',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ٹاپ رو (Row) جس میں کسٹمر معلومات اور پلس کا بٹن ایک ساتھ آئیں گے
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'کسٹمر معلومات',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E4620),
                          ),
                        ),
                        // نیا کسٹمر ایڈ کرنے کا خوبصورت ٹیکسٹ بٹن (جیسا پہلے تھا)
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddCustomerScreen(),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.person_add_alt_1,
                            size: 18,
                            color: Color(0xFF0C7A43),
                          ),
                          label: const Text(
                            'نیا کسٹمر شامل کریں',
                            style: TextStyle(
                              color: Color(0xFF0C7A43),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'کسٹمر کا نام',
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 6),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('customers')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError || !snapshot.hasData) {
                          return const Text('ڈیٹا لوڈ کرنے میں کوئی مسئلہ ہے۔');
                        }

                        // محفوظ فیلڈ لوک اپ تاکہ 'name' نہ ہونے پر کریش نہ ہو
                        final List<String> customerItems = snapshot.data!.docs
                            .map((doc) {
                              final data = doc.data() as Map<String, dynamic>?;
                              if (data != null && data.containsKey('name')) {
                                return data['name'].toString().trim();
                              }
                              return "";
                            })
                            .where((name) => name.isNotEmpty)
                            .toSet() // ڈپلیکیٹ نام ختم کرنے کے لیے
                            .toList();

                        if (customerItems.isEmpty) {
                          return const Text('کوئی کسٹمر موجود نہیں ہے۔');
                        }

                        if (selectedCustomer != null &&
                            !customerItems.contains(selectedCustomer)) {
                          selectedCustomer = null;
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: selectedCustomer,
                            hint: const Text('کسٹمر منتخب کریں'),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              suffixIcon: Icon(
                                Icons.person_outline,
                                color: Colors.grey,
                              ),
                            ),
                            icon: const SizedBox.shrink(),
                            items: customerItems.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                selectedCustomer = newValue;
                              });

                              // کسٹمر کا موبائل نمبر آٹو فل کرنے کے لیے لاجک
                              if (newValue != null) {
                                try {
                                  final customerDocs = snapshot.data!.docs
                                      .where((doc) {
                                        final data =
                                            doc.data() as Map<String, dynamic>?;
                                        return data != null &&
                                            data['name']?.toString().trim() ==
                                                newValue.trim();
                                      })
                                      .toList();

                                  if (customerDocs.isNotEmpty) {
                                    final cData =
                                        customerDocs.first.data()
                                            as Map<String, dynamic>?;
                                    if (cData != null &&
                                        cData.containsKey('mobile') &&
                                        cData['mobile'] != null) {
                                      _mobileController.text = cData['mobile']
                                          .toString()
                                          .trim();
                                    } else {
                                      _mobileController.clear();
                                    }
                                  } else {
                                    _mobileController.clear();
                                  }
                                } catch (e) {
                                  debugPrint('Error loading mobile: $e');
                                  _mobileController.clear();
                                }
                              }
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'موبائل نمبر',
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: TextFormField(
                        controller: _mobileController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: '03xxxxxxxxx',
                          border: InputBorder.none,
                          suffixIcon: Icon(
                            Icons.phone_outlined,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'وقت کا اندراج',
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Center(
                                child: Text(
                                  'گھنٹے',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFE0E0E0),
                                  ),
                                ),
                                child: TextFormField(
                                  controller: _hoursController,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    prefixIcon: Icon(
                                      Icons.access_time,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Center(
                                child: Text(
                                  'منٹ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFE0E0E0),
                                  ),
                                ),
                                child: TextFormField(
                                  controller: _minutesController,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    prefixIcon: Icon(
                                      Icons.access_time,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'کل وقت',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$displayHours گھنٹے $displayMinutes منٹ',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E4620),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'ریٹ فی گھنٹہ',
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: TextFormField(
                        controller: _rateController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'ریٹ لکھیں',
                          border: InputBorder.none,
                          prefixIcon: Padding(
                            padding: EdgeInsets.symmetric(vertical: 14.0),
                            child: Text(
                              'روپے',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'کل رقم',
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFC8E6C9)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'روپے',
                            style: TextStyle(
                              color: Color(0xFF0C7A43),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            totalAmount.toStringAsFixed(0),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'نوٹ (اختیاری)',
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: TextFormField(
                        controller: _noteController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'کوئی نوٹ لکھیں...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
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
                  onPressed: _isLoading ? null : _saveEntry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0C7A43),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'محفوظ کریں',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
