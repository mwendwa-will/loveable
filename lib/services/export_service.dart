import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:lovely/models/period.dart';

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  /// Export periods to CSV and share the file
  Future<void> exportPeriodsToCSV(List<Period> periods) async {
    final StringBuffer csvBuffer = StringBuffer();

    // Header
    csvBuffer.writeln('Start Date,End Date,Intensity,Notes');

    final dateFormat = DateFormat('yyyy-MM-dd');

    for (final period in periods) {
      final start = dateFormat.format(period.startDate);
      final end = period.endDate != null
          ? dateFormat.format(period.endDate!)
          : 'Ongoing';
      final intensity = period.flowIntensity?.name ?? 'Unknown';

      csvBuffer.writeln('$start,$end,$intensity,""');
    }

    await _shareCSV(csvBuffer.toString(), 'lovely_period_history.csv');
  }

  /// Helper to save and share the CSV file
  Future<void> _shareCSV(String csvContent, String fileName) async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');

      await file.writeAsString(csvContent);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'My Lovely cycle data export');
    } catch (e) {
      rethrow;
    }
  }
}
