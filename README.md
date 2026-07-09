# Solar Panel & Tubewell Management System ☀️🚜

An advanced and user-friendly Flutter application designed to manage tubewell operations, customer logs, entries, and financial receipts (wasooliyan) efficiently. Powered by Firebase Firestore for real-time tracking and calculations.

## 🚀 Features

- **Real-time Synchronization:** Fully integrated with Cloud Firestore for instant data updates across devices.
- **Automated Calculations:** Automatically calculates the total amount based on hours, minutes, and rate per hour as you type.
- **Customer Management:** Dynamic customer selection with features to add or edit client details on the go.
- **Wasooliyan (Receipts) Ledger:** Tab-based separation for different collectors (e.g., عبدالغفور and محمد ارشد) with individual summaries and local sorting for quick load times.
- **Clean RTL UI:** Tailored with an elegant Right-to-Left (RTL) interface optimized for local language users.

## 🛠️ Project Structure

Key screens included in this project:
- **`NewEntryScreen.dart`**: Handles time-based entries (hours/minutes), calculates totals dynamically, and links them securely to customer profiles.
- **`WasooliyanOverviewScreen.dart`**: Provides a real-time summary of total received amounts and lists all historical receipts sorted by date.
- **`AddCustomerScreen.dart` & `EditCustomerScreen.dart`**: Dedicated screens for handling customer registration and database updates using Firestore Batch writes.

## 📋 Prerequisites

Before running this project, ensure you have:
- Flutter SDK installed (Latest Stable Version)
- Android Studio / VS Code
- A Firebase Project configured

## 🔧 Setup & Installation

