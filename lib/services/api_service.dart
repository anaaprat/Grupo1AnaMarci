import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../api_constants.dart';

class ApiService {
  // Registro de usuario
  Future<Map<String, dynamic>> registerUser(String name, String email,
      String password, String cPassword, String role) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
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

  // Activar usuario
  Future<Map<String, dynamic>> activateUser(String token, int userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/activate'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'id': userId,
        'actived': true,
      }),
    );
    return _processResponse(response);
  }

  // Desactivar usuario
  Future<Map<String, dynamic>> deactivateUser(String token, int userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/activate'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'id': userId,
        'actived': false,
      }),
    );
    return _processResponse(response);
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
      Uri.parse('$baseUrl/activate'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'id': userId,
        'deleted': true, 
      }),
    );
    return _processResponse(response);
  }

  // Editar usuario
  Future<Map<String, dynamic>> updateUser(String token, int userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/updateUser'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
      body: jsonEncode({'id': userId}),
    );
    return _processResponse(response);
  }

  // Procesar respuesta de la API
  Map<String, dynamic> _processResponse(http.Response response) {
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {
        'success': false,
        'message': 'Error en la solicitud: ${response.statusCode}',
      };
    }
  }
}
