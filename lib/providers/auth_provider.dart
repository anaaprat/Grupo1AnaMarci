import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService apiService = ApiService();
  bool _isLoading = false;
  String? _errorMessage;
  String? _token;
  String? _role;
  String? _email;
  int? _id;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get token => _token;
  String? get role => _role;
  String? get email => _email;
  int? get id => _id;

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiService.login(email, password);

      if (response['success'] == true) {
        _token = response['data']['token'];
        _role = response['data']['role'];
        _email = email;
        _errorMessage = null;
      } else {
        _errorMessage = response['data']?['error'] ??
            response['message'] ??
            'Unknown error occurred.';
      }
    } catch (e) {
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
