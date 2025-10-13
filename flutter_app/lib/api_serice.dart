// --- api_service.dart ---
// FIXED: Added a clean HTTP client for FastAPI backend.

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;

  ApiService(this.baseUrl);

  /// Get available columns
  Future<List<String>> getColumns() async {
    final url = Uri.parse('$baseUrl/columns');
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return List<String>.from(data['columns']);
    } else {
      throw Exception('Failed to fetch columns: ${res.statusCode}');
    }
  }

  /// Post filters and get results
  Future<List<dynamic>> filterData({
    required String column,
    required String value,
    int limit = 100,
    int threshold = 60,
  }) async {
    final url = Uri.parse('$baseUrl/filter');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'column': column,
        'value': value,
        'limit': limit,
        'threshold': threshold,
      }),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['results'] ?? [];
    } else {
      throw Exception('Error ${res.statusCode}: ${res.body}');
    }
  }
}
