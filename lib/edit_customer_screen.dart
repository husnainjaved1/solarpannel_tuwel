import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditCustomerScreen extends StatefulWidget {
  final String currentName; // Is customer ka data load karne ke liye

  const EditCustomerScreen({super.key, required this.currentName});

  @override
  State<EditCustomerScreen> createState() => _EditCustomerScreenState();
}

class _EditCustomerScreenState extends State<EditCustomerScreen> {
  String _activeCustomerName = "";
  bool _isNameChanged = false;

  @override
  void initState() {
    super.initState();
    _activeCustomerName = widget.currentName;
  }

  // کسٹمر کی پروفائل (نام، فون، ایڈریس) ایڈٹ کرنے کا ڈائیلاگ باکس
  void _editCustomerProfileDialog() async {
    final nameController = TextEditingController(text: _activeCustomerName);
    final phoneController = TextEditingController();
    final addressController = TextEditingController();

    // 1. سب سے پہلے مین customers کلیکشن سے موجودہ ڈیٹا لے کر آئیں گے
    // ignore: unused_local_variable
    String? foundCustomerDocId; // کسٹمر کا ڈاک آئی ڈی محفوظ کریں گے
    try {
      final customerQuery = await FirebaseFirestore.instance
          .collection('customers')
          .where('name', isEqualTo: _activeCustomerName)
          .get();

      if (customerQuery.docs.isNotEmpty) {
        foundCustomerDocId = customerQuery.docs.first.id;
        var data = customerQuery.docs.first.data();
        if (data['mobile'] != null)
          phoneController.text = data['mobile'].toString();
        if (data['address'] != null)
          addressController.text = data['address'].toString();
      } else {
        // اگر کسٹمر کلیکشن میں نہ ملے تو بیک اپ کے طور پر entries سے ڈیٹا اٹھا لو
        final entryQuery = await FirebaseFirestore.instance
            .collection('entries')
            .where('customer_name', isEqualTo: _activeCustomerName)
            .get();

        for (var doc in entryQuery.docs) {
          var data = doc.data();
          if (data['customer_phone'] != null && phoneController.text.isEmpty) {
            phoneController.text = data['customer_phone'].toString();
          }
          if (data['customer_address'] != null &&
              addressController.text.isEmpty) {
            addressController.text = data['customer_address'].toString();
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching profile details: $e');
    }

    showDialog(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'کسٹمر پروفائل تبدیل کریں',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0C7A43),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'کسٹمر کا نام',
                        prefixIcon: Icon(
                          Icons.person_outline,
                          color: Color(0xFF0C7A43),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'موبائل نمبر',
                        prefixIcon: Icon(
                          Icons.phone_android,
                          color: Color(0xFF0C7A43),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: addressController,
                      decoration: const InputDecoration(
                        labelText: 'ایڈریس / پتہ',
                        prefixIcon: Icon(
                          Icons.location_on_outlined,
                          color: Color(0xFF0C7A43),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('کینسل'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0C7A43),
                  ),
                  onPressed: () async {
                    final String newName = nameController.text.trim();
                    final String newPhone = phoneController.text.trim();
                    final String newAddress = addressController.text.trim();

                    if (newName.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('نام لکھنا لازمی ہے!')),
                      );
                      return;
                    }

                    Navigator.pop(dialogContext);

                    try {
                      WriteBatch batch = FirebaseFirestore.instance.batch();

                      // === 1. پہلے customers کلیکشن کو اپڈیٹ یا بنائیں ===
                      final customerQuery = await FirebaseFirestore.instance
                          .collection('customers')
                          .where('name', isEqualTo: _activeCustomerName)
                          .get();

                      if (customerQuery.docs.isNotEmpty) {
                        // موجودہ customer کو اپڈیٹ کریں
                        for (var doc in customerQuery.docs) {
                          batch.update(doc.reference, {
                            'name': newName,
                            'mobile': newPhone,
                            'address': newAddress,
                          });
                        }
                      } else {
                        // اگر customer موجود نہیں ہے تو نیا بنائیں
                        DocumentReference newCustomerRef = FirebaseFirestore
                            .instance
                            .collection('customers')
                            .doc();
                        batch.set(newCustomerRef, {
                          'name': newName,
                          'mobile': newPhone,
                          'address': newAddress,
                          'created_at': Timestamp.now(),
                        });
                      }

                      // === 2. entries کلیکشن کی تمام انٹریز میں نام اور موبائل اپڈیٹ کریں ===
                      final entryQuery = await FirebaseFirestore.instance
                          .collection('entries')
                          .where(
                            'customer_name',
                            isEqualTo: _activeCustomerName,
                          )
                          .get();

                      for (var doc in entryQuery.docs) {
                        batch.update(doc.reference, {
                          'customer_name': newName,
                          'customer_phone': newPhone,
                          'customer_address': newAddress,
                        });
                      }

                      // === 3. receipts کلیکشن میں بھی نام تبدیل کریں ===
                      final receiptQuery = await FirebaseFirestore.instance
                          .collection('receipts')
                          .where(
                            'customer_name',
                            isEqualTo: _activeCustomerName,
                          )
                          .get();

                      for (var doc in receiptQuery.docs) {
                        batch.update(doc.reference, {'customer_name': newName});
                      }

                      // تمام تبدیلیاں ایک ساتھ فائر بیس پر بھیجیں
                      await batch.commit();

                      // لوکل اسٹیٹ اپڈیٹ کریں تاکہ اسکرین پر فورا نیا نام نظر آئے
                      setState(() {
                        _activeCustomerName = newName;
                        _isNameChanged = true;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'کسٹمر لسٹ اور تمام ریکارڈز کامیابی سے اپڈیٹ ہو گئے ہیں۔',
                          ),
                        ),
                      );
                    } catch (e) {
                      debugPrint('Error updating customer profile: $e');
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('خرابی: $e')));
                    }
                  },
                  child: const Text(
                    'محفوظ کریں',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Specific Entry (Hours/Minutes) ko edit karne ka dialog auto-calculation aur editable rate ke sath
  // Specific Entry کو ایڈٹ کرنے کا ڈائیلاگ - اب یہ کسٹمر کلیکشن کو بھی ساتھ اپڈیٹ کرے گا
  void _editEntryDialog(DocumentSnapshot doc, Map<String, dynamic> data) {
    // پرانا نام محفوظ کر رہے ہیں تاکہ فائر بیس میں میچنگ کے لیے استعمال ہو سکے
    final String originalCustomerName =
        data['customer_name'] ?? _activeCustomerName;

    final nameController = TextEditingController(text: originalCustomerName);
    final phoneController = TextEditingController(
      text: (data['customer_phone'] ?? '').toString(),
    );

    final hoursController = TextEditingController(
      text: (data['hours'] ?? '0').toString(),
    );
    final minutesController = TextEditingController(
      text: (data['minutes'] ?? '0').toString(),
    );
    final amountController = TextEditingController(
      text: (data['total_amount'] ?? '0').toString(),
    );

    double initialHours = double.tryParse(hoursController.text) ?? 0.0;
    double initialMinutes = double.tryParse(minutesController.text) ?? 0.0;
    double initialAmount = double.tryParse(amountController.text) ?? 0.0;
    double totalHoursDecimal = initialHours + (initialMinutes / 60.0);

    double calculatedRate = totalHoursDecimal > 0
        ? (initialAmount / totalHoursDecimal)
        : 1000.0;

    final rateController = TextEditingController(
      text: calculatedRate.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            void updateCalculatedPrice() {
              double hours = double.tryParse(hoursController.text) ?? 0.0;
              double minutes = double.tryParse(minutesController.text) ?? 0.0;
              double currentRate = double.tryParse(rateController.text) ?? 0.0;

              double totalHours = hours + (minutes / 60.0);
              double finalAmount = totalHours * currentRate;

              amountController.text = finalAmount.toStringAsFixed(0);
            }

            return AlertDialog(
              title: const Text(
                'انٹری اور کسٹمر ڈیٹا تبدیل کریں',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0C7A43),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // کسٹمر کا نام اور فون نمبر انٹری کے اندر بھی ایڈٹ کرنے کے لیے فیلڈز
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'کسٹمر کا نام',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'موبائل نمبر',
                        prefixIcon: Icon(Icons.phone),
                      ),
                    ),
                    const Divider(height: 30, thickness: 1),
                    TextField(
                      controller: hoursController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'گھنٹے',
                        suffixText: 'گھنٹہ',
                      ),
                      onChanged: (val) =>
                          setDialogState(() => updateCalculatedPrice()),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: minutesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'منٹ',
                        suffixText: 'منٹ',
                      ),
                      onChanged: (val) =>
                          setDialogState(() => updateCalculatedPrice()),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: rateController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'فی گھنٹہ ریٹ',
                        suffixText: 'روپے',
                      ),
                      onChanged: (val) =>
                          setDialogState(() => updateCalculatedPrice()),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'کل رقم (آٹو اپڈیٹ)',
                        prefixIcon: Icon(Icons.calculate, color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('کینسل'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0C7A43),
                  ),
                  onPressed: () async {
                    final String newName = nameController.text.trim();
                    final String newPhone = phoneController.text.trim();
                    final double finalHours =
                        double.tryParse(hoursController.text) ?? 0.0;
                    final double finalMinutes =
                        double.tryParse(minutesController.text) ?? 0.0;
                    final double finalAmount =
                        double.tryParse(amountController.text) ?? 0.0;

                    if (newName.isEmpty) return;

                    Navigator.pop(dialogContext);

                    try {
                      WriteBatch batch = FirebaseFirestore.instance.batch();

                      // 1. موجودہ انٹری ڈاکومنٹ کو اپڈیٹ کریں
                      batch.update(doc.reference, {
                        'customer_name': newName,
                        'customer_phone': newPhone,
                        'hours': finalHours,
                        'minutes': finalMinutes,
                        'total_amount': finalAmount,
                      });

                      // 2. 'customers' کلیکشن میں تلاش کریں اور اپڈیٹ کریں یا بنائیں
                      final customerQuery = await FirebaseFirestore.instance
                          .collection('customers')
                          .where('name', isEqualTo: originalCustomerName)
                          .get();

                      if (customerQuery.docs.isNotEmpty) {
                        // موجودہ customer کو اپڈیٹ کریں
                        for (var customerDoc in customerQuery.docs) {
                          batch.update(customerDoc.reference, {
                            'name': newName,
                            'mobile': newPhone,
                          });
                        }
                      } else {
                        // اگر customer موجود نہیں ہے تو نیا بنائیں
                        DocumentReference newCustomerRef = FirebaseFirestore
                            .instance
                            .collection('customers')
                            .doc();
                        batch.set(newCustomerRef, {
                          'name': newName,
                          'mobile': newPhone,
                          'address': '',
                          'created_at': Timestamp.now(),
                        });
                      }

                      // 3. اس کسٹمر کی باقی تمام انٹریز (entries) میں بھی نام اور فون اپڈیٹ کر دیں
                      final allEntriesQuery = await FirebaseFirestore.instance
                          .collection('entries')
                          .where(
                            'customer_name',
                            isEqualTo: originalCustomerName,
                          )
                          .get();

                      for (var entryDoc in allEntriesQuery.docs) {
                        // یہ چیک اس لیے ہے تاکہ موجودہ ڈاکومنٹ دوبارہ بیچ میں ایڈ نہ ہو (کیونکہ وہ اوپر ہو چکا ہے)
                        if (entryDoc.id != doc.id) {
                          batch.update(entryDoc.reference, {
                            'customer_name': newName,
                            'customer_phone': newPhone,
                          });
                        }
                      }

                      // 4. اس کسٹمر کی تمام وصولیوں (receipts) میں بھی نام اپڈیٹ کریں
                      final receiptQuery = await FirebaseFirestore.instance
                          .collection('receipts')
                          .where(
                            'customer_name',
                            isEqualTo: originalCustomerName,
                          )
                          .get();

                      for (var receiptDoc in receiptQuery.docs) {
                        batch.update(receiptDoc.reference, {
                          'customer_name': newName,
                        });
                      }

                      // تمام تبدیلیاں ایک ساتھ فائر بیس پر بھیجیں
                      await batch.commit();

                      if (!mounted) return;

                      // اگر نام تبدیل ہوا ہے تو مین اسکرین کی اسٹیٹ بھی اپڈیٹ کر دیں
                      if (newName != originalCustomerName) {
                        setState(() {
                          _activeCustomerName = newName;
                          _isNameChanged = true;
                        });
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'انٹری اور کسٹمر لسٹ کامیابی سے اپڈیٹ ہو گئی ہے!',
                          ),
                        ),
                      );

                      // Dialog کو بند کریں
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      debugPrint('Error syncing data from entry dialog: $e');
                      if (mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('خرابی: $e')));
                      }
                    }
                  },
                  child: const Text(
                    'اپڈیٹ کریں',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Specific Wasooli (Receipt) ko edit karne ka dialog
  void _editReceiptDialog(DocumentSnapshot doc, Map<String, dynamic> data) {
    final amountController = TextEditingController(
      text: (data['today_received'] ?? '0').toString(),
    );

    showDialog(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('وصولی رقم تبدیل کریں'),
          content: TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'وصول شدہ رقم (روپے)'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('کینسل'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0C7A43),
              ),
              onPressed: () async {
                final double finalAmount =
                    double.tryParse(amountController.text.trim()) ?? 0.0;
                Navigator.pop(dialogContext);
                try {
                  await doc.reference.update({'today_received': finalAmount});
                } catch (e) {
                  debugPrint('Error updating receipt: $e');
                }
              },
              child: const Text(
                'اپڈیٹ کریں',
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
    if (_activeCustomerName.isEmpty) {
      _activeCustomerName = widget.currentName;
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: WillPopScope(
        onWillPop: () async {
          Navigator.pop(context, _isNameChanged ? _activeCustomerName : null);
          return false;
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFF7FBF6),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0C7A43),
            title: const Text(
              'کسٹمر ڈیٹا ایڈٹ کریں',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(
                  context,
                  _isNameChanged ? _activeCustomerName : null,
                );
              },
            ),
          ),
          body: Column(
            children: [
              // ================= CUSTOMER PROFILE EDIT CARD =================
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.account_circle,
                          color: Color(0xFF0C7A43),
                          size: 40,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'کسٹمر کا نام',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              _activeCustomerName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: _editCustomerProfileDialog,
                      icon: const Icon(
                        Icons.edit,
                        size: 16,
                        color: Color(0xFF0C7A43),
                      ),
                      label: const Text(
                        'ایڈٹ کریں',
                        style: TextStyle(
                          color: Color(0xFF0C7A43),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        backgroundColor: const Color(
                          0xFF0C7A43,
                        ).withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'تمام ریکارڈز کی تفصیل (ایڈٹ کرنے کے لیے کلک کریں)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E4620),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Real-time Entries & Receipts List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('entries')
                      .where('customer_name', isEqualTo: _activeCustomerName)
                      .snapshots(),
                  builder: (context, entrySnapshot) {
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('receipts')
                          .where(
                            'customer_name',
                            isEqualTo: _activeCustomerName,
                          )
                          .snapshots(),
                      builder: (context, receiptSnapshot) {
                        if (!entrySnapshot.hasData ||
                            !receiptSnapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF0C7A43),
                            ),
                          );
                        }

                        List<DocumentSnapshot> allDocs = [];
                        allDocs.addAll(entrySnapshot.data!.docs);
                        allDocs.addAll(receiptSnapshot.data!.docs);

                        allDocs.sort((a, b) {
                          Timestamp tA =
                              (a.data() as Map<String, dynamic>)['date'] ??
                              Timestamp.now();
                          Timestamp tB =
                              (b.data() as Map<String, dynamic>)['date'] ??
                              Timestamp.now();
                          return tB.compareTo(tA);
                        });

                        if (allDocs.isEmpty) {
                          return const Center(
                            child: Text(
                              'ایڈٹ کرنے کے لیے کوئی ریکارڈ موجود نہیں ہے۔',
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: allDocs.length,
                          itemBuilder: (context, index) {
                            DocumentSnapshot doc = allDocs[index];
                            var data = doc.data() as Map<String, dynamic>;

                            bool isEntry = doc.reference.path.contains(
                              'entries',
                            );

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isEntry
                                            ? 'ٹیوب ویل وقت'
                                            : 'رقم وصولی (${data['collector'] ?? ''})',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isEntry
                                              ? Colors.black87
                                              : Colors.green.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        isEntry
                                            ? '${data['hours'] ?? 0} گھنٹے ${data['minutes'] ?? 0} منٹ'
                                            : 'وصول شدہ',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        '${isEntry ? data['total_amount'] : data['today_received']} روپے',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit_note,
                                          color: Color(0xFF0C7A43),
                                          size: 28,
                                        ),
                                        onPressed: () {
                                          if (isEntry) {
                                            _editEntryDialog(doc, data);
                                          } else {
                                            _editReceiptDialog(doc, data);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
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
      ),
    );
  }
}
