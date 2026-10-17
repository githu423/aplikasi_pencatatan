import 'dart:io';
import 'package:flutter/material.dart';

/// Dialog pratinjau foto layar penuh dengan dukungan pinch to zoom
class PhotoViewerDialog extends StatelessWidget {
  final String imagePath;
  final String? title;

  const PhotoViewerDialog({
    super.key,
    required this.imagePath,
    this.title,
  });

  static void show(BuildContext context, String imagePath, {String? title}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PhotoViewerDialog(imagePath: imagePath, title: title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final file = File(imagePath);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.6),
        foregroundColor: Colors.white,
        title: Text(title ?? 'Foto Bukti Transaksi'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: file.existsSync()
            ? InteractiveViewer(
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.8,
                maxScale: 4.0,
                child: Image.file(
                  file,
                  fit: BoxFit.contain,
                ),
              )
            : const Text(
                'File foto tidak ditemukan atau telah dihapus',
                style: TextStyle(color: Colors.white70),
              ),
      ),
    );
  }
}
