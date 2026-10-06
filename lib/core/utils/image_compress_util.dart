import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';

// Compresses a picked photo down to a target size (~300 KB) before upload,
// well under both the 5MB app-level limit (kycController.js) and the 1MB
// nginx client_max_body_size default on the production server.
class ImageCompressUtil {
  ImageCompressUtil._();

  static const int _targetBytes = 350 * 1024;

  static Future<File> compress(File file) async {
    final dir = file.parent.path;
    final baseName = DateTime.now().millisecondsSinceEpoch;

    File? lastResult;
    for (var quality = 85; quality >= 30; quality -= 15) {
      final targetPath = '$dir/compressed_${baseName}_$quality.jpg';
      final xfile = await FlutterImageCompress.compressAndGetFile(
        file.path,
        targetPath,
        quality: quality,
        minWidth: 1280,
        minHeight: 1280,
        format: CompressFormat.jpeg,
      );
      if (xfile == null) return file;

      final compressedFile = File(xfile.path);
      if (await compressedFile.length() <= _targetBytes) return compressedFile;
      lastResult = compressedFile;
    }
    return lastResult ?? file;
  }
}
