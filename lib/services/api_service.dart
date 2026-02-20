import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ticket.dart';

class ApiService {
  static const String _apiUrlKey = 'api_url';
  static const String defaultApiUrl = 'https://ticket-services.favric.cl';
  static const String _apiKey = 'fvx_1LfOlEEufTFNO3wE_wlo0SeK7b_T1hjGPdFmNMn5REH848Bn5yCvWg';

  String _apiUrl = defaultApiUrl;
  void Function(String)? onLog;

  String get apiUrl => _apiUrl;

  void _log(String msg) {
    debugPrint(msg);
    onLog?.call(msg);
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _apiUrl = prefs.getString(_apiUrlKey) ?? defaultApiUrl;
  }

  Future<void> setApiUrl(String url) async {
    _apiUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiUrlKey, _apiUrl);
  }

  /// Escanea y canjea un ticket usando POST /api/redeem-ticket/
  /// Retorna ScanResult con el ticket y si fue recién canjeado
  Future<ScanResult> lookupTicket(String ticketNumber) async {
    final trimmed = ticketNumber.trim();
    final url = '$_apiUrl/api/redeem-ticket/';
    _log('[scan] POST $url');
    _log('[scan] body: {ticket_number: $trimmed}');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
        },
        body: jsonEncode({'ticket_number': trimmed}),
      );
      _log('[scan] status: ${response.statusCode}');
      _log('[scan] resp: ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}');

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
      throw Exception(msg);
    } on http.ClientException catch (e) {
      _log('[scan] ClientException: $e');
      throw Exception('Error de conexion: $e');
    } on FormatException catch (e) {
      _log('[scan] FormatException: $e');
      throw Exception('Respuesta invalida del servidor');
    }
  }
}
