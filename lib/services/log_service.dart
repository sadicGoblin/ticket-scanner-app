import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

enum LogType { error, query }

class LogService {
  static const int _maxFileSizeBytes = 2 * 1024 * 1024; // 2 MB max

  final Map<LogType, File?> _logFiles = {};

  String _fileNameFor(LogType type) {
    switch (type) {
      case LogType.error:
        return 'error_log.txt';
      case LogType.query:
        return 'query_log.txt';
    }
  }

  String _shareSubjectFor(LogType type) {
    switch (type) {
      case LogType.error:
        return 'Ticket Scanner - Log de errores';
      case LogType.query:
        return 'Ticket Scanner - Log de consultas';
    }
  }

  Future<File> _getLogFile(LogType type) async {
    if (_logFiles[type] != null) return _logFiles[type]!;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${_fileNameFor(type)}');
    if (!await file.exists()) {
      await file.create();
    }
    _logFiles[type] = file;
    return file;
  }

  String _timestamp() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  Future<void> log(String message, {String level = 'ERROR'}) async {
    await _write(LogType.error, '[$level] $message');
  }

  Future<void> logQuery(String message) async {
    await _write(LogType.query, message);
  }

  Future<void> _write(LogType type, String content) async {
    try {
      final file = await _getLogFile(type);
      final entry = '[${_timestamp()}] $content\n';
      await file.writeAsString(entry, mode: FileMode.append);

      final size = await file.length();
      if (size > _maxFileSizeBytes) {
        await _trimLog(file);
      }
    } catch (e) {
      debugPrint('LogService write error: $e');
    }
  }

  Future<void> _trimLog(File file) async {
    try {
      final lines = await file.readAsLines();
      final keep = lines.sublist(lines.length ~/ 2);
      await file.writeAsString(
        '[--- Log recortado automaticamente ---]\n${keep.join('\n')}\n',
      );
    } catch (e) {
      debugPrint('LogService trim error: $e');
    }
  }

  Future<String> readLogs(LogType type) async {
    try {
      final file = await _getLogFile(type);
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (e) {
      debugPrint('LogService read error: $e');
    }
    return '';
  }

  Future<void> clearLogs(LogType type) async {
    try {
      final file = await _getLogFile(type);
      await file.writeAsString('');
    } catch (e) {
      debugPrint('LogService clear error: $e');
    }
  }

  Future<void> shareLogs(LogType type) async {
    try {
      final file = await _getLogFile(type);
      if (await file.exists() && await file.length() > 0) {
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: _shareSubjectFor(type),
        );
      }
    } catch (e) {
      debugPrint('LogService share error: $e');
    }
  }

  Future<int> logSizeBytes(LogType type) async {
    try {
      final file = await _getLogFile(type);
      if (await file.exists()) {
        return await file.length();
      }
    } catch (e) {
      debugPrint('LogService size error: $e');
    }
    return 0;
  }
}
