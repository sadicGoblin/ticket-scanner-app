import 'package:flutter/material.dart';
import '../models/ticket.dart';
import '../services/api_service.dart';

class ResultScreen extends StatefulWidget {
  final Ticket ticket;
  final ApiService apiService;
  final bool justRedeemed;
  final String? warning;

  const ResultScreen({
    super.key,
    required this.ticket,
    required this.apiService,
    required this.justRedeemed,
    this.warning,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late Ticket _ticket;

  @override
  void initState() {
    super.initState();
    _ticket = widget.ticket;
  }

  Color _statusColor() {
    if (widget.justRedeemed) return Colors.green.shade600;
    if (_ticket.isRedeemed) return Colors.red.shade600;
    if (_ticket.isExpired) return Colors.grey.shade600;
    if (_ticket.isPrinted) return const Color(0xFF0053E2);
    if (_ticket.isPending) return Colors.orange.shade600;
    return Colors.grey;
  }

  IconData _statusIcon() {
    if (widget.justRedeemed) return Icons.check_circle;
    if (_ticket.isRedeemed) return Icons.block;
    if (_ticket.isExpired) return Icons.timer_off;
    if (_ticket.isPrinted) return Icons.print;
    if (_ticket.isPending) return Icons.hourglass_empty;
    return Icons.help_outline;
  }

  String _statusText() {
    if (widget.justRedeemed) return 'CANJEADO EXITOSAMENTE';
    if (_ticket.isRedeemed) return 'TICKET YA COBRADO';
    if (_ticket.isExpired) return 'TICKET EXPIRADO';
    return _ticket.statusLabel.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Detalle del Ticket'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0053E2),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Status hero
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                color: _statusColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _statusColor().withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(_statusIcon(), size: 72, color: _statusColor()),
                  const SizedBox(height: 16),
                  Text(
                    _statusText(),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _statusColor(),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),

            // Warning banner
            if (widget.warning != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.orange.shade700, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.warning!,
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Ticket info card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow('Codigo', _ticket.ticketNumber),
                  const Divider(height: 24),
                  _infoRow('Servicio', _ticket.serviceName),
                  if (_ticket.serviceCode.isNotEmpty) ...[
                    const Divider(height: 24),
                    _infoRow('Codigo Servicio', _ticket.serviceCode),
                  ],
                  if (_ticket.personName != null) ...[
                    const Divider(height: 24),
                    _infoRow('Persona', _ticket.personName!),
                  ],
                  if (_ticket.personDocument != null) ...[
                    const Divider(height: 24),
                    _infoRow('Documento', _ticket.personDocument!),
                  ],
                  if (_ticket.created.isNotEmpty) ...[
                    const Divider(height: 24),
                    _infoRow('Creado', _ticket.created),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Back button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, widget.justRedeemed),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: const Text(
                  'Volver a escanear',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2e2f32),
            ),
          ),
        ),
      ],
    );
  }
}
