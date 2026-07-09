import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:solarpannel_tuwel/homescreen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true, // Offline cache enable karne ke liye
    cacheSizeBytes: Settings
        .CACHE_SIZE_UNLIMITED, // Cache ki size unlimited rakhne ke liye (Tension free)
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: const HomeScreen(),
      ),
    );
  }
}

// Global Bottom Navigation Bar Helper
// ignore: unused_element
Widget _buildBottomNav(BuildContext context, int currentIndex) {
  return BottomNavigationBar(
    currentIndex: currentIndex,
    type: BottomNavigationBarType.fixed,
    selectedItemColor: const Color(0xFF0C7A43),
    unselectedItemColor: Colors.grey,
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: 'تقسیم'),
      BottomNavigationBarItem(icon: Icon(Icons.trending_up), label: 'رپورٹ'),
      BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'وصولیاں'),
      BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'کھاتہ'),
      BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ہوم'),
    ],
  );
}
