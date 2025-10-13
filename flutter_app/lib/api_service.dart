// api_service.dart
// Handles all communication between Flutter and FastAPI backend.

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;

  ApiService(this.baseUrl);

  // Get all available column names
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

  // Get unique values for a specific column
  Future<List<String>> getUniqueValues(String column) async {
    final url = Uri.parse('$baseUrl/unique-values?column=$column');
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return List<String>.from(data['values']);
    } else {
      throw Exception('Failed to fetch unique values: ${res.statusCode}');
    }
  }

  // Send multiple filters (column → value mapping)
Future<List<dynamic>> filterData({
  required Map<String, String> filters,
  int limit = 100,
  int threshold = 60,
}) async {
  final url = Uri.parse('$baseUrl/filter');
  final res = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'filters': filters,
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
