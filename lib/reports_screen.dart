import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' as intl;

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTimeRange? _selectedDateRange;
  String _selectedCollector = 'سب'; // Options: 'سب', 'عبدالغفور', 'محمد ارشد'

  @override
  Widget build(BuildContext context) {
    // Current Month Filter Default set karne ke liye
    DateTime now = DateTime.now();
    DateTime firstDayCurrentMonth = DateTime(now.year, now.month, 1);
    DateTime lastDayCurrentMonth = DateTime(
      now.year,
      now.month + 1,
      0,
      23,
      59,
      59,
    );

    DateTime start = _selectedDateRange?.start ?? firstDayCurrentMonth;
    DateTime end = _selectedDateRange?.end ?? lastDayCurrentMonth;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7FBF6),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0C7A43),
          elevation: 0,
          title: const Text(
            'وصولیوں کی رپورٹ',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('receipts')
              .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
              .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF0C7A43)),
              );
            }

            double totalGhafoor = 0.0;
            double totalArshad = 0.0;
            List<QueryDocumentSnapshot> filteredDocs = [];

            if (snapshot.hasData) {
              for (var doc in snapshot.data!.docs) {
                var data = doc.data() as Map<String, dynamic>;
                double amount = (data['today_received'] ?? 0.0).toDouble();
                String collector = data['collector'] ?? '';

                // Calculate individual totals first
                if (collector == 'عبدالغفور') {
                  totalGhafoor += amount;
                } else if (collector == 'محمد ارشد') {
                  totalArshad += amount;
                }

                // Dropdown filter ke mutabiq list filter karein
                if (_selectedCollector == 'سب' ||
                    collector == _selectedCollector) {
                  filteredDocs.add(doc);
                }
              }
            }

            double grandTotal = totalGhafoor + totalArshad;

            return Column(
              children: [
                // Filters Section (Date & Collector Dropdown)
                _buildFilterBar(start, end),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary Cards
                        _buildSummarySection(
                          grandTotal,
                          totalGhafoor,
                          totalArshad,
                        ),
                        const SizedBox(height: 24),

                        // Chart/Visual Progress Bars
                        _buildVisualAnalytics(
                          totalGhafoor,
                          totalArshad,
                          grandTotal,
                        ),
                        const SizedBox(height: 24),

                        // Details List Heading
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'تفصیلی ریکارڈ',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E4620),
                              ),
                            ),
                            Text(
                              'کل اندراج: ${filteredDocs.length}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Detailed List View
                        filteredDocs.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 40),
                                  child: Text(
                                    'منتخب کردہ فلٹر کے مطابق کوئی ریکارڈ نہیں ملا۔',
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filteredDocs.length,
                                itemBuilder: (context, index) {
                                  var data =
                                      filteredDocs[index].data()
                                          as Map<String, dynamic>;
                                  return _buildReportItem(data);
                                },
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Filter UI
  Widget _buildFilterBar(DateTime start, DateTime end) {
    String dateRangeText =
        "${intl.DateFormat('dd MMM').format(start)} تا ${intl.DateFormat('dd MMM yyyy').format(end)}";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          // Date Range Picker Button
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: _pickDateRange,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month,
                      size: 20,
                      color: Color(0xFF0C7A43),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        dateRangeText,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Collector Dropdown Filter
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE0E0E0)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCollector,
                  items: const [
                    DropdownMenuItem(value: 'سب', child: Text('سب ریکوری')),
                    DropdownMenuItem(
                      value: 'عبدالغفور',
                      child: Text('عبدالغفور'),
                    ),
                    DropdownMenuItem(
                      value: 'محمد ارشد',
                      child: Text('محمد ارشد'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCollector = val);
                  },
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black,
                    fontFamily: 'UrduFont',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Summary Cards UI
  Widget _buildSummarySection(
    double grandTotal,
    double totalGhafoor,
    double totalArshad,
  ) {
    return Column(
      children: [
        // Main Card (Grand Total)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0C7A43), Color(0xFF1E4620)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'کل جمع شدہ رقم',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 5),
              Text(
                '${grandTotal.toStringAsFixed(0)} روپے',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Individual Collectors Two Cards Row
        Row(
          children: [
            Expanded(
              child: _buildIndividualCard(
                'عبدالغفور',
                totalGhafoor,
                Colors.blue.shade700,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildIndividualCard(
                'محمد ارشد',
                totalArshad,
                Colors.orange.shade800,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIndividualCard(String name, double amount, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEBEBEB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 5, backgroundColor: accentColor),
              const SizedBox(width: 6),
              Text(
                name,
                style: const TextStyle(color: Colors.black54, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${amount.toStringAsFixed(0)} روپے',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }

  // Visual Analytics (Progress Bars comparison)
  Widget _buildVisualAnalytics(double ghafoor, double arshad, double total) {
    double ghafoorPer = total > 0 ? (ghafoor / total) : 0.0;
    double arshadPer = total > 0 ? (arshad / total) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEBEBEB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'وصولیوں کا موازنہ (شیئر %)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 16),
          // Abdul Ghafoor Progress
          Row(
            children: [
              const SizedBox(width: 80, child: Text('عبدالغفور')),
              Expanded(
                child: LinearProgressIndicator(
                  value: ghafoorPer,
                  backgroundColor: Colors.grey.shade100,
                  color: Colors.blue.shade700,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(width: 10),
              Text('${(ghafoorPer * 100).toStringAsFixed(0)}%'),
            ],
          ),
          const SizedBox(height: 12),
          // Muhammad Arshad Progress
          Row(
            children: [
              const SizedBox(width: 80, child: Text('محمد ارشد')),
              Expanded(
                child: LinearProgressIndicator(
                  value: arshadPer,
                  backgroundColor: Colors.grey.shade100,
                  color: Colors.orange.shade800,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(width: 10),
              Text('${(arshadPer * 100).toStringAsFixed(0)}%'),
            ],
          ),
        ],
      ),
    );
  }

  // Detailed Row List Item
  Widget _buildReportItem(Map<String, dynamic> data) {
    double amount = (data['today_received'] ?? 0).toDouble();
    String name = data['customer_name'] ?? 'نامعلوم';
    String collector = data['collector'] ?? 'نامعلوم';
    Timestamp? timestamp = data['date'] as Timestamp?;

    String formattedDate = '';
    if (timestamp != null) {
      formattedDate = intl.DateFormat(
        'dd MMMM yyyy (hh:mm a)',
      ).format(timestamp.toDate());
    }

    Color collectorColor = collector == 'عبدالغفور'
        ? Colors.blue.shade700
        : Colors.orange.shade800;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEBEBEB)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Side: Name and Date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: const TextStyle(fontSize: 12, color: Colors.black38),
                ),
              ],
            ),
          ),
          // Right Side: Amount and Tag
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${amount.toStringAsFixed(0)} روپے',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0C7A43),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: collectorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  collector,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: collectorColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Date Range Picker Picker Function
  Future<void> _pickDateRange() async {
    DateTimeRange? initialRange =
        _selectedDateRange ??
        DateTimeRange(
          start: DateTime(DateTime.now().year, DateTime.now().month, 1),
          end: DateTime.now(),
        );

    DateTimeRange? newRange = await showDateRangePicker(
      context: context,
      initialDateRange: initialRange,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0C7A43),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (newRange != null) {
      setState(() {
        // End date ko din ke aakhri lamhe (23:59:59) par set karein taake us din ka data missing na ho
        _selectedDateRange = DateTimeRange(
          start: newRange.start,
          end: DateTime(
            newRange.end.year,
            newRange.end.month,
            newRange.end.day,
            23,
            59,
            59,
          ),
        );
      });
    }
  }
}
