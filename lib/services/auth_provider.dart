import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService apiService = ApiService();
  bool _isLoading = false;
  String? _errorMessage;
  String? _token;
  String? _role;
  String? _email; // Añadimos esta variable para almacenar el email del usuario

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get token => _token;
  String? get role => _role;
  String? get email => _email; // Añadimos el getter para email

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiService.loginUser(email, password);

      print("Response from server: $response");

      if (response['success'] == true) {
        _token = response['data']['token'];
        _role = response['data']['role'];
        _email = email; // Guardamos el email del usuario al hacer login
        _errorMessage = null;
      } else {
        _errorMessage = response['data']?['error'] ??
            response['message'] ??
            'Invalid login credentials.';
      }
    } catch (e) {
      print("Error during login: $e");
      _errorMessage = 'An error occurred while logging in.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
