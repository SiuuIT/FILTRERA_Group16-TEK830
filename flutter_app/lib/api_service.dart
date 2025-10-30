// api_service.dart
// Handles all communication between Flutter and FastAPI backend.

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;

  ApiService(this.baseUrl);

  // Fetch all column names from backend
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

  // Fetch unique values for a specific column
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

  // Send filters and get filtered results
  Future<Map<String, dynamic>> filterData({
    required Map<String, dynamic> filters,
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
      if (data is Map<String, dynamic>) {
        return data;
      } else {
        throw Exception('Unexpected response format from backend.');
      }
    } else {
      throw Exception('Backend error ${res.statusCode}: ${res.body}');
    }
  }
  Future<Map<String, dynamic>?> interpretFilters(String prompt) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ai-interpret-filters'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'prompt': prompt}),
    );

    if(response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print( 'AI interpretation failed:${response.body}');
      return null; 
    }
  }

}
