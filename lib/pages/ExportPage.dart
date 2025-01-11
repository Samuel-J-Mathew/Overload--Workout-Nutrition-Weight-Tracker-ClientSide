import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gymapp/data/hive_database.dart';
import 'package:path_provider/path_provider.dart';

class ExportPage extends StatelessWidget {
  final HiveDatabase database = HiveDatabase();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
        backgroundColor: Colors.grey[900],
      ),
      backgroundColor: Colors.grey[850],
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white, backgroundColor: Colors.blue[900], // Button text color
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () async {
            try {
              // Export data and get the file path
              String filePath = await database.exportDataToExcel();
              File file = File(filePath);
              if (!file.existsSync()) {
                throw Exception('File does not exist at $filePath');
              }
              // Show success message with file path
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Data exported to: $filePath')),
              );

              // Provide an option to open the file using url_launcher
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Export Successful'),
                  content: Text('Data exported to: $filePath'),
                  actions: [
                    TextButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        // Open the file using the system's file viewer
                        await database.openFile(filePath);
                      },
                      child: const Text('Open File'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            } catch (e) {
              // Show error message in case of failure
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to export data: $e')),
              );
            }
          },
          child: const Text(
            'Export Data to Excel',
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
