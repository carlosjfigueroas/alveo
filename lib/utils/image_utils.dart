import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImageUtils {
  /// Compresses the given [bytes] into a JPEG format.
  /// If the image is larger than [maxDimension], it will be resized.
  /// It iteratively reduces quality until the size is under [targetSizeKb].
  static Future<Uint8List> compressImage(
    Uint8List bytes, {
    int maxDimension = 1200,
    int targetSizeKb = 250,
  }) async {
    final decodedImage = img.decodeImage(bytes);
    if (decodedImage == null) return bytes;

    // Resize if too large
    img.Image resized = decodedImage;
    if (decodedImage.width > maxDimension || decodedImage.height > maxDimension) {
      resized = img.copyResize(
        decodedImage,
        width: decodedImage.width > decodedImage.height ? maxDimension : null,
        height: decodedImage.height > decodedImage.width ? maxDimension : null,
      );
    }

    int quality = 85;
    Uint8List compressed = Uint8List.fromList(img.encodeJpg(resized, quality: quality));

    // Iteratively reduce quality if still over targetSizeKb
    while (compressed.length > targetSizeKb * 1024 && quality > 10) {
      quality -= 10;
      compressed = Uint8List.fromList(img.encodeJpg(resized, quality: quality));
    }

    return compressed;
  }
}
