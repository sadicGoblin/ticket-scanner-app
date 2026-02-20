import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'screens/scanner_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final apiService = ApiService();
  await apiService.init();
  runApp(TicketScannerApp(apiService: apiService));
}

class TicketScannerApp extends StatelessWidget {
  final ApiService apiService;

  const TicketScannerApp({super.key, required this.apiService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ticket Scanner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0053E2),
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: ScannerScreen(apiService: apiService),
    );
  }
}
