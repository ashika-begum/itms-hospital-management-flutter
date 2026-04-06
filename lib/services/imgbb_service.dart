import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ImgbbService {
  static const String _apiKey = '21283b072a0672a7c91e74deb2f56615';

  /// Upload raw image bytes to imgbb
  /// Returns public image URL
  static Future<String> uploadBytes(Uint8List bytes) async {
    final base64Image = base64Encode(bytes);

    final uri = Uri.parse(
      'https://api.imgbb.com/1/upload?key=$_apiKey',
    );

    final response = await http.post(
      uri,
      body: {
        'image': base64Image,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Imgbb upload failed: ${response.body}');
    }

    final decoded = jsonDecode(response.body);

    if (decoded['success'] != true) {
      throw Exception('Imgbb error: ${decoded['error']}');
    }

    return decoded['data']['url'];
  }
}
