import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:open_filex/open_filex.dart';

class InvoicePreviewScreen extends StatefulWidget {
  final Uint8List pdfBytes;
  final String fileName;

  const InvoicePreviewScreen({
    super.key,
    required this.pdfBytes,
    required this.fileName,
  });

  @override
  State<InvoicePreviewScreen> createState() => _InvoicePreviewScreenState();
}

class _InvoicePreviewScreenState extends State<InvoicePreviewScreen> {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _notificationsPlugin.initialize(initSettings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Preview'),
      ),
      body: PdfPreview(
        build: (format) => widget.pdfBytes,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        actions: [
          PdfPreviewAction(
            icon: const Icon(Icons.download),
            onPressed: _saveFile,
          ),
        ],
      ),
    );
  }

  Future<void> _saveFile(BuildContext context, LayoutCallback build,
      PdfPageFormat pageFormat) async {
    try {
      String? filePath;

      if (Platform.isAndroid) {
        // Android Logic
        if (await _requestPermission()) {
          final directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }

          final file = File('${directory.path}/${widget.fileName}');
          await file.writeAsBytes(widget.pdfBytes);
          filePath = file.path;
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Storage permission denied')),
            );
          }
          return;
        }
      } else {
        // iOS Logic
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/${widget.fileName}');
        await file.writeAsBytes(widget.pdfBytes);
        filePath = file.path;
      }

      await _showNotification(filePath);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to $filePath'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () => OpenFilex.open(filePath!),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving file: $e')),
        );
      }
    }
  }

  Future<bool> _requestPermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;

      // Request notification permission for Android 13+
      if (androidInfo.version.sdkInt >= 33) {
        await _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      }

      if (androidInfo.version.sdkInt >= 33) {
        // Android 13+ doesn't need WRITE_EXTERNAL_STORAGE for app-specific or public downloads if using MediaStore,
        // but writing directly to /storage/emulated/0/Download might still be restricted.
        // However, for this simple implementation, we'll assume it works or user grants access.
        // Actually, on Android 13, we might need to use Manage External Storage if we want raw access,
        // but that's restricted.
        // Let's try without permission first as some devices allow writing to Downloads.
        return true;
      } else {
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    }
    return true;
  }

  Future<void> _showNotification(String filePath) async {
    const androidDetails = AndroidNotificationDetails(
      'downloads_channel',
      'Downloads',
      channelDescription: 'Notifications for downloaded files',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notificationsPlugin.show(
      0,
      'Download Complete',
      'Invoice saved to Downloads',
      details,
    );
  }
}
