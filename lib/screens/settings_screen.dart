import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/log_service.dart';

class SettingsScreen extends StatefulWidget {
  final ApiService apiService;
  final LogService logService;

  const SettingsScreen({
    super.key,
    required this.apiService,
    required this.logService,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _urlController;
  bool _isSaving = false;
  bool _saved = false;

  String _errorLogContent = '';
  int _errorLogSize = 0;
  String _queryLogContent = '';
  int _queryLogSize = 0;
  bool _loadingLogs = true;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.apiService.apiUrl);
    _loadAllLogs();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadAllLogs() async {
    setState(() => _loadingLogs = true);
    final errContent = await widget.logService.readLogs(LogType.error);
    final errSize = await widget.logService.logSizeBytes(LogType.error);
    final qContent = await widget.logService.readLogs(LogType.query);
    final qSize = await widget.logService.logSizeBytes(LogType.query);
    if (mounted) {
      setState(() {
        _errorLogContent = errContent;
        _errorLogSize = errSize;
        _queryLogContent = qContent;
        _queryLogSize = qSize;
        _loadingLogs = false;
      });
    }
  }

  Future<void> _save() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _isSaving = true;
      _saved = false;
    });

    await widget.apiService.setApiUrl(url);

    setState(() {
      _isSaving = false;
      _saved = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saved = false);
    });
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Configuracion'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0053E2),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),

            // --- URL Config Section ---
            _buildCard(
              icon: Icons.dns_outlined,
              title: 'URL del Servidor',
              subtitle: 'Direccion del servidor API',
              child: Column(
                children: [
                  TextField(
                    controller: _urlController,
                    keyboardType: TextInputType.url,
                    style: const TextStyle(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'https://ticket-services.favric.cl',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF0053E2),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: _saved
                          ? const Icon(Icons.check, size: 20)
                          : const Icon(Icons.save, size: 20),
                      label: Text(
                        _saved ? 'Guardado' : 'Guardar',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _saved
                            ? Colors.green.shade600
                            : const Color(0xFF0053E2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- Query Log Section ---
            _buildLogSection(
              icon: Icons.cloud_outlined,
              title: 'Log de Consultas',
              emptyText: 'Sin consultas registradas',
              logContent: _queryLogContent,
              logSize: _queryLogSize,
              logType: LogType.query,
              textColor: Colors.cyanAccent,
            ),

            const SizedBox(height: 20),

            // --- Error Log Section ---
            _buildLogSection(
              icon: Icons.bug_report_outlined,
              title: 'Log de Errores',
              emptyText: 'Sin errores registrados',
              logContent: _errorLogContent,
              logSize: _errorLogSize,
              logType: LogType.error,
              textColor: Colors.redAccent.shade100,
            ),

            const SizedBox(height: 20),

            // Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0053E2).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: const Color(0xFF0053E2).withValues(alpha: 0.7),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Los logs se recortan automaticamente al superar 2 MB.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogSection({
    required IconData icon,
    required String title,
    required String emptyText,
    required String logContent,
    required int logSize,
    required LogType logType,
    required Color textColor,
  }) {
    return _buildCard(
      icon: icon,
      title: title,
      subtitle: _loadingLogs
          ? 'Cargando...'
          : logContent.isEmpty
              ? emptyText
              : 'Tamaño: ${_formatBytes(logSize)}',
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 200,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _loadingLogs
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white54,
                      strokeWidth: 2,
                    ),
                  )
                : SingleChildScrollView(
                    reverse: true,
                    child: Text(
                      logContent.isEmpty ? emptyText : logContent,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 11,
                        fontFamily: 'monospace',
                        height: 1.5,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: logContent.isEmpty
                      ? null
                      : () async {
                          await widget.logService.shareLogs(logType);
                        },
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text(
                    'Compartir',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0053E2),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(
                      color: logContent.isEmpty
                          ? Colors.grey.shade300
                          : const Color(0xFF0053E2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: logContent.isEmpty
                      ? null
                      : () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Limpiar log'),
                              content: const Text(
                                '¿Seguro que desea eliminar todos los registros?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancelar'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade600,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Eliminar'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await widget.logService.clearLogs(logType);
                            await _loadAllLogs();
                          }
                        },
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text(
                    'Limpiar',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(
                      color: logContent.isEmpty
                          ? Colors.grey.shade300
                          : Colors.red.shade400,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
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
          Row(
            children: [
              Icon(icon, size: 22, color: const Color(0xFF0053E2)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2e2f32),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
