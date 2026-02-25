import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ticket.dart';
import 'log_service.dart';

class ApiService {
  static const String _apiUrlKey = 'api_url';
  static const String _apiKeyStorageKey = 'api_key_secure';
  static const String defaultApiUrl = 'https://ticket-services.favric.cl';
  static const String _defaultApiKey =
      'fvx_1LfOlEEufTFNO3wE_wlo0SeK7b_T1hjGPdFmNMn5REH848Bn5yCvWg';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LogService logService;

  String _apiUrl = defaultApiUrl;
  String _apiKey = '';

  String get apiUrl => _apiUrl;

  ApiService({required this.logService});

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _apiUrl = prefs.getString(_apiUrlKey) ?? defaultApiUrl;

    // Load API key from secure storage, or set default on first run
    _apiKey = await _secureStorage.read(key: _apiKeyStorageKey) ?? '';
    if (_apiKey.isEmpty) {
      _apiKey = _defaultApiKey;
      await _secureStorage.write(key: _apiKeyStorageKey, value: _apiKey);
    }
  }

  Future<void> setApiUrl(String url) async {
    _apiUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiUrlKey, _apiUrl);
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'x-api-key': _apiKey,
      };

  /// Escanea y canjea un ticket usando POST /api/redeem-ticket/
  /// Retorna ScanResult con el ticket y si fue recién canjeado
  Future<ScanResult> lookupTicket(String ticketNumber) async {
    final trimmed = ticketNumber.trim();
    final url = '$_apiUrl/api/redeem-ticket/';

    try {
      final reqBody = jsonEncode({'ticket_number': trimmed});
      await logService.logQuery('→ POST $url\n  Body: $reqBody');

      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: reqBody,
      );

      final respPreview = response.body.length > 500
          ? '${response.body.substring(0, 500)}...'
          : response.body;
      await logService.logQuery(
        '← ${response.statusCode} POST $url\n  Response: $respPreview',
      );

      if (response.statusCode == 401) {
        await logService.log('POST $url → 401 Unauthorized (API Key inválida)');
        throw Exception('API Key inválida o inactiva');
      }

      final data = jsonDecode(response.body);

      if (data['ticket'] != null && data['ticket'] is Map<String, dynamic>) {
        final ticket = Ticket.fromJson(data['ticket']);
        return ScanResult(
          ticket: ticket,
          justRedeemed: data['success'] == true,
          warning: data['warning'],
        );
      }

      final msg = data['error'] ?? data['message'] ?? 'Ticket no encontrado';
      await logService.log('POST $url → $msg');
      throw Exception(msg);
    } on http.ClientException catch (e) {
      await logService.log('POST $url → ClientException: $e');
      await logService.logQuery('✖ POST $url → ClientException: $e');
      throw Exception('Error de conexion: $e');
    } on FormatException catch (e) {
      await logService.log('POST $url → FormatException: $e');
      await logService.logQuery('✖ POST $url → FormatException: $e');
      throw Exception('Respuesta invalida del servidor');
    } catch (e) {
      if (e is Exception) rethrow;
      await logService.log('POST $url → $e');
      await logService.logQuery('✖ POST $url → $e');
      throw Exception('Error inesperado: $e');
    }
  }
}
