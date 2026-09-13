import 'dart:convert';
import 'package:http/http.dart' as http;

class CapsuleService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  static Future<List<dynamic>> getCapsules(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/capsules'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 401) {
      throw Exception('Authentication expired');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load capsules: ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw Exception('Invalid capsules response');
    }

    return data;
  }
}