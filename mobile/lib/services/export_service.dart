/// ExportService generates and exports Excel mark sheets for MCQ Marker.
///
/// ## Responsibilities
/// - Creates a formatted Excel workbook summarizing test results.
/// - Adds university title, logo, course info, script statistics, and student scores.
/// - Calculates and displays maximum, minimum, and average scores.
/// - Saves the Excel file to device storage (Downloads or Documents).
/// - Handles Android storage permissions and shows user feedback.
/// - Shares the exported file using system share dialogs.
///
/// ## Main Methods
/// - `exportSummary`: Generates and exports the mark sheet Excel file.
///
/// ## Dependencies
/// - [syncfusion_flutter_xlsio]: For Excel file creation.
/// - [path_provider], [permission_handler]: For file storage and permissions.
/// - [share_plus]: For sharing files.
/// - [fluttertoast]: For user notifications.
///
/// ## Usage
/// Call `exportSummary` with test and script data to export results.
/// 
/// Example:
/// ```dart
/// await ExportService().exportSummary(
///   context: context,
///   test: testData,
///   scripts: scriptsList,
///   endNumber: 50,
///   totalScripts: scriptsList.length,
///   averageScore: avg,
///   highestScore: max,
///   lowestScore: min,
/// );
/// ```
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as excel_package;

class ExportService {
  Future<void> exportSummary({
    required BuildContext context,
    required Map<String, dynamic>? test,
    required List scripts,
    required int endNumber,
    required int totalScripts,
    required double averageScore,
    required double highestScore,
    required double lowestScore,
  }) async {
    try {
      if (Platform.isAndroid) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
          if (!status.isGranted) {
            Fluttertoast.showToast(
              msg: "Storage permission required to save file",
              backgroundColor: Colors.red,
              textColor: Colors.white,
            );
            return;
          }
        }
      }

      // Create a new Excel workbook
      final excel_package.Workbook workbook = excel_package.Workbook();
      final excel_package.Worksheet sheet = workbook.worksheets[0];
      sheet.name = 'Mark Sheet';

      int currentRow = 1;

      // Row 1: University title and Examinations :: Mark Sheet
      sheet.getRangeByName('A$currentRow:G$currentRow').merge();
      sheet.getRangeByName('A$currentRow:G$currentRow').rowHeight = 60;
      final excel_package.Range titleRange = sheet.getRangeByName('A$currentRow');
      titleRange.setText(
          'Kwame Nkrumah University of Science and Technology, Kumasi.\nExaminations :: Mark Sheet');
      titleRange.cellStyle.bold = true;
      titleRange.cellStyle.fontSize = 15;
      titleRange.cellStyle.hAlign = excel_package.HAlignType.center;
      titleRange.cellStyle.vAlign = excel_package.VAlignType.center;
      currentRow++;

      // Row 2: KNUST Logo
      sheet.getRangeByName('A$currentRow:G$currentRow').merge();
      try {
        final ByteData logoData =
            await rootBundle.load('assets/images/knust-logo.jpg');
        final Uint8List logoBytes = logoData.buffer.asUint8List();

        final excel_package.Picture picture =
            sheet.pictures.addStream(currentRow, 1, logoBytes);
        picture.height = 50;
        picture.width = 50;

        sheet.getRangeByName('A$currentRow').rowHeight = 50;
      } catch (e) {
        final excel_package.Range imageCell = sheet.getRangeByName('A$currentRow');
        imageCell.setText('[KNUST LOGO]');
        imageCell.cellStyle.fontSize = 10;
      }
      currentRow++;

      // Row 4: Course
      sheet.getRangeByName('A$currentRow:G$currentRow').merge();
      sheet.getRangeByName('A$currentRow').setText(
          'Course: ${test?['course_code'].toUpperCase()} - ${test?['name'].toUpperCase() ?? '_____________________'}');
      sheet.getRangeByName('A$currentRow').cellStyle.fontSize = 11;
      currentRow++;

      // Row 5: No. of Questions
      sheet.getRangeByName('A$currentRow:G$currentRow').merge();
      sheet.getRangeByName('A$currentRow').setText('No. of Questions: $endNumber');
      sheet.getRangeByName('A$currentRow').cellStyle.fontSize = 11;
      currentRow++;

      // Row 6: No. of Scripts
      sheet.getRangeByName('A$currentRow:G$currentRow').merge();
      sheet.getRangeByName('A$currentRow').setText('No. of Scripts: $totalScripts');
      sheet.getRangeByName('A$currentRow').cellStyle.fontSize = 11;
      currentRow++;

      // Row 7: Header row
      List<String> headers = ['Rec#', 'Index No', 'C', 'W', 'U', 'Raw', '100%'];
      for (int i = 0; i < headers.length; i++) {
        final excel_package.Range headerCell = sheet.getRangeByIndex(currentRow, i + 1);
        headerCell.setText(headers[i]);
        headerCell.cellStyle.bold = true;
        headerCell.cellStyle.backColor = '#D3D3D3'; // Light Gray
        headerCell.cellStyle.hAlign = excel_package.HAlignType.center;
        headerCell.cellStyle.vAlign = excel_package.VAlignType.center;
      }
      currentRow++;

      List sortedScripts = List.from(scripts);
      sortedScripts.sort((a, b) =>
          a['index_number'].toString().compareTo(b['index_number'].toString()));

      // Student data rows
      int recordNumber = 1;
      for (var script in sortedScripts) {
        if (script['score'] == null) continue;

        sheet.getRangeByIndex(currentRow, 1).setNumber(recordNumber.toDouble());

        sheet.getRangeByIndex(currentRow, 2).setText(script['index_number']?.toString() ?? 'N/A');

        int correct = script['score'] as int? ?? 0;
        int wrong = 0;
        int unanswered = 0;

        if (script['answers'] != null && script['answers'] is List) {
          List answers = script['answers'];
          int totalAnswered =
              answers.where((answer) => answer != null && answer.toString().trim().isNotEmpty).length;
          wrong = totalAnswered - correct;
          unanswered = endNumber - totalAnswered;
        } else {
          wrong = endNumber - correct;
          unanswered = 0;
        }

        sheet.getRangeByIndex(currentRow, 3).setNumber(correct.toDouble());
        sheet.getRangeByIndex(currentRow, 4).setNumber(wrong.toDouble());
        sheet.getRangeByIndex(currentRow, 5).setNumber(unanswered.toDouble());
        sheet.getRangeByIndex(currentRow, 6).setNumber(correct.toDouble());

        double percentage = (correct / endNumber) * 100;
        sheet.getRangeByIndex(currentRow, 7).setText('${percentage.toStringAsFixed(1)}%');

        currentRow++;
        recordNumber++;
      }

      // Maximum row
      sheet.getRangeByName('C$currentRow:D$currentRow').merge();
      sheet.getRangeByName('C$currentRow').setText('Maximum:');
      sheet.getRangeByName('C$currentRow').cellStyle.bold = true;
      sheet.getRangeByIndex(currentRow, 6).setNumber(highestScore);
      double maxPercentage = (highestScore / endNumber) * 100;
      sheet.getRangeByIndex(currentRow, 7).setText('${maxPercentage.toStringAsFixed(1)}%');
      currentRow++;

      // Minimum row
      sheet.getRangeByName('C$currentRow:D$currentRow').merge();
      sheet.getRangeByName('C$currentRow').setText('Minimum:');
      sheet.getRangeByName('C$currentRow').cellStyle.bold = true;
      sheet.getRangeByIndex(currentRow, 6).setNumber(lowestScore);
      double minPercentage = (lowestScore / endNumber) * 100;
      sheet.getRangeByIndex(currentRow, 7).setText('${minPercentage.toStringAsFixed(1)}%');
      currentRow++;

      // Average row
      sheet.getRangeByName('C$currentRow:D$currentRow').merge();
      sheet.getRangeByName('C$currentRow').setText('Average:');
      sheet.getRangeByName('C$currentRow').cellStyle.bold = true;
      sheet.getRangeByIndex(currentRow, 6).setNumber(averageScore);
      double avgPercentage = (averageScore / endNumber) * 100;
      sheet.getRangeByIndex(currentRow, 7).setText('${avgPercentage.toStringAsFixed(1)}%');
      currentRow++;

      // Legend row
      sheet.getRangeByName('A$currentRow:G$currentRow').merge();
      final legendRange = sheet.getRangeByName('A$currentRow');
      legendRange.setText('Legend: C :: Correct, W :: Wrong, U :: UnAnswered');
      legendRange.cellStyle.fontSize = 10;
      legendRange.cellStyle.italic = true;

      // Set column widths
      sheet.getRangeByName('A1:G1').columnWidth = 8.0;
      sheet.getRangeByName('B1:B1').columnWidth = 15.0;
      sheet.getRangeByName('C1:E1').columnWidth = 8.0;
      sheet.getRangeByName('F1:G1').columnWidth = 10.0;

      // Save the file
      Directory? directory;
      final String fileName = (test != null && test.isNotEmpty)
          ? 'MarkSheet ${test['course_code'].toUpperCase()}_${test['class_'].toUpperCase()}.xlsx'
          : 'MarkSheet test.xlsx';

      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!directory.existsSync()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final String filePath = "${directory!.path}/$fileName";
      final File file = File(filePath);

      final List<int> excelBytes = workbook.saveAsStream();
      workbook.dispose();
      await file.writeAsBytes(excelBytes);

      Fluttertoast.showToast(
        msg: Platform.isAndroid
            ? "Mark Sheet saved to Downloads: $fileName"
            : "Mark Sheet saved: $fileName",
        backgroundColor: Colors.green,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );

      await Share.shareXFiles([XFile(filePath)], text: "Mark Sheet");
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Export failed: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }
}