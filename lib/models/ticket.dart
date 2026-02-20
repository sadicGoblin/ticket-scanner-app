class Ticket {
  final int id;
  final String ticketNumber;
  final String serviceName;
  final String serviceCode;
  final String status;
  final String? personName;
  final String? personDocument;
  final String created;
  final String modified;

  Ticket({
    required this.id,
    required this.ticketNumber,
    required this.serviceName,
    required this.serviceCode,
    required this.status,
    this.personName,
    this.personDocument,
    required this.created,
    required this.modified,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    final rawService = json['service'];
    final service = rawService is Map<String, dynamic> ? rawService : <String, dynamic>{};
    return Ticket(
      id: json['id'] ?? 0,
      ticketNumber: json['ticket_number'] ?? '',
      serviceName: service['name'] ?? (rawService is String ? rawService : ''),
      serviceCode: service['code'] ?? '',
      status: json['status'] ?? 'pending',
      personName: json['person_name'] ??
          (json['person'] is Map ? json['person']['full_name'] : null) ??
          (json['person'] is String ? json['person'] : null),
      personDocument: json['person_document'] ??
          (json['person'] is Map ? json['person']['document_number'] : null),
      created: json['created'] ?? '',
      modified: json['modified'] ?? '',
    );
  }

  bool get isPending => status == 'pending';
  bool get isPrinted => status == 'printed';
  bool get isRedeemed => status == 'redeemed';
  bool get isExpired => status == 'expired';

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'printed':
        return 'Impreso';
      case 'redeemed':
        return 'Cobrado';
      case 'expired':
        return 'Expirado';
      default:
        return status;
    }
  }
}

/// Resultado de escanear un ticket
class ScanResult {
  final Ticket ticket;
  final bool justRedeemed;
  final String? warning;

  ScanResult({
    required this.ticket,
    required this.justRedeemed,
    this.warning,
  });
}
