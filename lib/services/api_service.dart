import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../api_constants.dart';

class ApiService {
  // Registro de usuario
  Future<Map<String, dynamic>> registerUser(String name, String email,
      String password, String cPassword, String role) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'c_password': cPassword,
          'role': role,
        }),
      );
      return _processResponse(response);
    } catch (e) {
      print("Error al realizar la solicitud de registro: $e");
      return {
        'success': false,
        'message': 'Error al realizar la solicitud de registro.'
      };
    }
  }

  // Login de usuario
  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    return _processResponse(response);
  }

  // Cambiar estado del usuario (activar/desactivar)
  Future<Map<String, dynamic>> changeUserStatus(
      String token, int userId, bool isActive) async {
    final endpoint = isActive ? '/activate' : '/deactivate'; // Cambiado
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
      body: jsonEncode({'id': userId}), // Se envía el id del usuario
    );
    return _processResponse(response); // Manejo de la respuesta de la API
  }

  // Obtener todos los usuarios
  Future<List<User>?> getUsers(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body)['data'];
      return data.map((userJson) => User.fromJson(userJson)).toList();
    } else {
      print('Error al obtener usuarios: ${response.statusCode}');
      return null;
    }
  }

  // Eliminar usuario
  Future<Map<String, dynamic>> deleteUser(String token, int userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/deleteUser'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
      body: jsonEncode({'id': userId}),
    );
    return _processResponse(response);
  }

  // Editar usuario
  Future<Map<String, dynamic>> updateUser(
      String token, int userId, Map<String, dynamic> updatedData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/updateUser'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'id': userId,
        ...updatedData,
      }),
    );
    return _processResponse(response);
  }

  // Procesar respuesta de la API
  Map<String, dynamic> _processResponse(http.Response response) {
    try {
      final decodedResponse = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return decodedResponse;
      } else {
        return {
          'success': false,
          'message': decodedResponse['message'] ?? 'Error en la solicitud.',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print("Error al procesar la respuesta: $e");
      return {
        'success': false,
        'message': 'Error al procesar la respuesta.',
        'statusCode': response.statusCode,
      };
    }
  }
}
