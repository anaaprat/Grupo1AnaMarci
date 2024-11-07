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
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      return _processResponse(response);
    } catch (e) {
      print("Error al realizar la solicitud de login: $e");
      return {
        'success': false,
        'message': 'Error al realizar la solicitud de login.'
      };
    }
  }

  // Cambiar estado del usuario (activar/desactivar)
  Future<Map<String, dynamic>> changeUserStatus(
      String token, int userId, bool isActive) async {
    final endpoint = isActive ? '/activate' : '/deactivate';
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
      body: jsonEncode({'id': userId}),
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

  // Obtener un usuario específico usando su email
  Future<Map<String, dynamic>> fetchUserData(
      String token, String userEmail) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['data'] is List) {
          final List users = data['data'];
          final user = users.firstWhere(
            (u) => u['email'] == userEmail,
            orElse: () => null,
          );

          if (user != null) {
            return user;
          } else {
            print('Usuario no encontrado en la lista.');
            return {};
          }
        } else {
          print('Formato inesperado en la respuesta.');
          return {};
        }
      } else {
        print(
            'Error al obtener datos de usuarios. Código: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      print("Error al realizar la solicitud de usuario: $e");
      return {};
    }
  }

  // Obtener la lista de eventos
  Future<List<dynamic>?> fetchEvents(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/events'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['data'] is List) {
          List<dynamic> events = data['data'];

          DateTime now = DateTime.now();
          List<dynamic> upcomingEvents = events.where((event) {
            DateTime eventDate = DateTime.parse(event['start_time']);
            return eventDate.isAfter(now);
          }).toList();

          upcomingEvents.sort((a, b) {
            DateTime dateA = DateTime.parse(a['start_time']);
            DateTime dateB = DateTime.parse(b['start_time']);
            return dateB.compareTo(dateA);
          });

          return upcomingEvents;
        } else {
          print('Formato de datos inesperado.');
          return null;
        }
      } else {
        print('Error al obtener eventos: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error al obtener eventos: $e');
      return null;
    }
  }

  //Filtrar eventos
  Future<List<dynamic>?> fetchCategories(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/categories'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      } else {
        print('Error al obtener categorías: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error al obtener categorías: $e');
      return null;
    }
  }

  Map<String, dynamic> _processResponse(http.Response response) {
    try {
      final decodedResponse = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
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
