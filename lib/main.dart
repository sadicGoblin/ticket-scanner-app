import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'services/log_service.dart';
import 'screens/scanner_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final logService = LogService();
  final apiService = ApiService(logService: logService);
  await apiService.init();
  runApp(TicketScannerApp(apiService: apiService, logService: logService));
}

class TicketScannerApp extends StatelessWidget {
  final ApiService apiService;
  final LogService logService;

  const TicketScannerApp({super.key, required this.apiService, required this.logService});

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
      home: ScannerScreen(apiService: apiService, logService: logService),
    );
  }
}
