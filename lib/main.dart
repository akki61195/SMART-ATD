import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image/image.as' as img; // Alias to avoid naming conflicts with Widgets
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const OheAtdApp());
}

class OheAtdApp extends StatelessWidget {
  const OheAtdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OHE ATD Smart Tool',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050a0f),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00d4ff),
          secondary: Color(0xFF00ff41),
        ),
      ),
      home: const AtdHomeScreen(),
    );
  }
}

class AtdHomeScreen extends StatefulWidget {
  const AtdHomeScreen({super.key});

  @override
  State<AtdHomeScreen> createState() => _AtdHomeScreenState();
}

class _AtdHomeScreenState extends State<AtdHomeScreen> {
  // Controllers & States
  final TextEditingController _lengthController = TextEditingController(text: "750.0");
  final TextEditingController _tempController = TextEditingController(text: "35.0");
  final TextEditingController _structController = TextEditingController(text: "101/A");
  
  String _areaName = "Manual Mode / Section A";

  // Calculation Logic
  double get _tensionLength => double.tryParse(_lengthController.text) ?? 750.0;
  double get _temperature => double.tryParse(_tempController.text) ?? 35.0;

  double get _delta => _tensionLength * 0.000017 * (35 - _temperature) * 1000;
  double get _xVal => 1300 + _delta;
  double get _yVal => 2300 + (3 * _delta);

  // --- 3K RESOLUTION IMAGE GENERATOR & STORAGE ---
  Future<void> _generateAndSaveImage(BuildContext context) async {
    // Check & Request Storage Permission
    var status = await Permission.storage.request();
    if (!status.isGranted && Platform.isAndroid) {
      // For Android 11+, manage external storage or app-specific dir works fine
      await Permission.manageExternalStorage.request();
    }

    // IST Time Format
    final istTime = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    String currDt = DateFormat('dd-MMM-yyyy hh:mm:ss a').format(istTime);

    int scale = 3;
    int width = 900 * scale;
    int height = 550 * scale;

    // Create Image Buffer using 'image' package
    img.Image image = img.Image(width: width, height: height);
    img.fill(image, color: img.ColorRgb8(5, 10, 15)); // background #050a0f

    // Draw Outer Border (#00d4ff)
    img.fillRect(image, x1: 20 * scale, y1: 20 * scale, x2: width - (20 * scale), y2: 20 * scale + (5 * scale), color: img.ColorRgb8(0, 212, 255));
    img.fillRect(image, x1: 20 * scale, y1: height - (25 * scale), x2: width - (20 * scale), y2: height - (20 * scale), color: img.ColorRgb8(0, 212, 255));
    img.fillRect(image, x1: 20 * scale, y1: 20 * scale, x2: 25 * scale, y2: height - (20 * scale), color: img.ColorRgb8(0, 212, 255));
    img.fillRect(image, x1: width - (25 * scale), y1: 20 * scale, x2: width - (20 * scale), y2: height - (20 * scale), color: img.ColorRgb8(0, 212, 255));

    // Save PNG to local application documents or downloads folder
    try {
      final bytes = img.encodePng(image);
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      String fileName = "ATD_Record_${DateFormat('yyyyMMdd_HHmmss').format(istTime)}.png";
      final file = File('${directory!.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Image Saved Successfully in Downloads!\nPath: ${file.path}'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error Saving Image: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OHE ATD Smart Tool', style: TextStyle(color: Color(0xFF00d4ff), fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1c2128),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Active Section Box
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF1c2128),
                border: Border.all(color: const Color(0xFF00d4ff), width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text('📡 ACTIVE SECTION', style: TextStyle(color: Color(0xFF00d4ff), fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(_areaName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
                ],
              ),
            ),
            const SizedBox(height: 15),

            // Structure No Input
            TextField(
              controller: _structController,
              decoration: const InputDecoration(
                labelText: 'Structure No',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.architecture, color: Color(0xFF00d4ff)),
              ),
            ),
            const SizedBox(height: 15),

            // Tension Length Input & Display
            TextField(
              controller: _lengthController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Tension Length (L) in meters',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.straighten, color: Color(0xFF00ff41)),
              ),
              onChanged: (val) => setState(() {}),
            ),
            const SizedBox(height: 15),

            // Temperature Input
            TextField(
              controller: _tempController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Current Temperature (°C)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.thermostat, color: Color(0xFF00d4ff)),
              ),
              onChanged: (val) => setState(() {}),
            ),
            const SizedBox(height: 20),

            // Results Display Cards
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1c2128),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF00ff41)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('X (Pulley Gap)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 5),
                        Text('${_xVal.toString_fixed_safe(1)} mm', style: const TextStyle(color: Color(0xFF00ff41), fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1c2128),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF00ff41)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Y (Weight Height)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 5),
                        Text('${_yVal.toString_fixed_safe(1)} mm', style: const TextStyle(color: Color(0xFF00ff41), fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Save Image Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF002b49),
                foregroundColor: const Color(0xFFccff00),
                side: const BorderSide(color: Color(0xFF00d4ff), width: 2),
                minimumSize: const Size.fromHeight(55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.save, color: Color(0xFFccff00)),
              label: const Text('💾 SAVE HD IMAGE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              onPressed: () => _generateAndSaveImage(context),
            ),
            const SizedBox(height: 40),

            // Footer
            const Center(
              child: Text(
                'DEVELOPED BY: A.K.MULCHANDANI JE/TRD',
                style: TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 1.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on double {
  String toString_fixed_safe(int fractionDigits) {
    return toStringAsFixed(fractionDigits);
  }
}
