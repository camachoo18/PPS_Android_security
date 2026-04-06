import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/models/imc_record.dart';

class APIService {
  static const String baseUrl = 'http://localhost:3000';

  /// Obtener registros de IMC del usuario autenticado
  static Future<List<IMCRecord>> getRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('No hay sesión activa');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/records'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // ✅ IMPORTANTE: Acceder correctamente a 'records'
        if (data['success'] == true && data['records'] != null) {
          final records = (data['records'] as List)
              .map((r) => IMCRecord.fromJson(r))
              .toList();
          return records;
        } else {
          return [];
        }
      } else if (response.statusCode == 401) {
        throw Exception('Sesión expirada');
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener registros: $e');
    }
  }
}