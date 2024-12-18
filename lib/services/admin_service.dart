import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api_constants.dart';
import '../models/user.dart';

class AdminService {
  final String token;

  AdminService({required this.token});

  Map<String, dynamic> _processResponse(http.Response response) {
    try {
      final decodedResponse = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return decodedResponse;
      } else {
        return {
          'success': false,
          'data': decodedResponse['data'] ?? 'Error en la solicitud.',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al procesar la respuesta.',
        'statusCode': response.statusCode,
      };
    }
  }

  Future<bool> activateUser(int userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/activate'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'id': userId}),
    );

    final result = _processResponse(response);
    return result['success'] == true; // Devuelve true si 'success' es true
  }

  Future<bool> deactivateUser(int userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/deactivate'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'id': userId}),
    );

    final result = _processResponse(response);
    return result['success'] == true; // Devuelve true si 'success' es true
  }

  // Obtener todos los usuarios
  Future<List<User>> getUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> data = responseData['data'];
          return data.map((userJson) => User.fromJson(userJson)).toList();
        } else {
          throw Exception(responseData['message'] ?? 'Error retrieving users.');
        }
      } else {
        throw Exception('Failed to fetch users: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  // Eliminar usuario
  Future<bool> deleteUser(int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/deleteUser'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: jsonEncode({'id': userId}),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        return true;
      } else {
        throw Exception(responseBody['message'] ?? 'Could not delete user.');
      }
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

//UPdate user
  Future<Map<String, dynamic>> updateUser(int userId, String name) async {
    final response = await http.post(
      Uri.parse('$baseUrl/updateUser'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'id': userId,
        'name': name,
      }),
    );

    return _processResponse(response);
  }
}
