import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;

  LoggerService._internal();

  Directory? _logDir;

  Future<void> _ensureDir() async {
    if (_logDir != null) return;
    // Try to create and prefer writing logs into the local workspace `logs/` folder
    try {
      final workspacePath = '/home/rabin/projects/fursal_mobile/logs';
      final workspaceDir = Directory(workspacePath);
      if (!(await workspaceDir.exists())) {
        // attempt to create; this may fail on devices but will work on the development host
        await workspaceDir.create(recursive: true);
      }
      if (await workspaceDir.exists()) {
        _logDir = workspaceDir;
        return;
      }
    } catch (_) {
      // ignore and fallback to application documents directory
    }

    final dir = await getApplicationDocumentsDirectory();
    final logs = Directory('${dir.path}/logs');
    if (!(await logs.exists())) {
      await logs.create(recursive: true);
    }
    _logDir = logs;
  }

  Future<File> _file(String name) async {
    await _ensureDir();
    return File('${_logDir!.path}/$name');
  }

  Future<void> _append(String fileName, Map<String, dynamic> entry) async {
    try {
      final file = await _file(fileName);
      final line = jsonEncode(entry);
      await file.writeAsString('$line\n', mode: FileMode.append, flush: true);
    } catch (_) {
      // Swallow errors to avoid cascading failures in logging.
    }
  }

  Future<void> info(String message, {Map<String, dynamic>? meta}) async {
    final entry = <String, dynamic>{
      'ts': DateTime.now().toIso8601String(),
      'level': 'info',
      'message': message,
      if (meta != null) 'meta': meta,
    };
    // Also print to console so Flutter logs/tunnel show entries in your terminal/device logs
    try {
      debugPrint(jsonEncode(entry));
    } catch (_) {}
    await _append('info.log', entry);
  }

  Future<void> error(String message, {Map<String, dynamic>? meta}) async {
    final entry = <String, dynamic>{
      'ts': DateTime.now().toIso8601String(),
      'level': 'error',
      'message': message,
      if (meta != null) 'meta': meta,
    };
    try {
      debugPrint(jsonEncode(entry));
    } catch (_) {}
    await _append('error.log', entry);
  }
}
