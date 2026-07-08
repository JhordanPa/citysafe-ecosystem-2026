import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/incident.dart';
import '../models/user.dart';

class ApiService {
  final String baseUrl = "http://127.0.0.1:8000";

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;
  String? _role;

  void setToken(String? token) {
    _token = token;
  }

  bool get isAuthenticated => _token != null;
  String get role => _role ?? 'ciudadano';

  // Cargar token desde el almacenamiento persistente
  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _role = prefs.getString('auth_role');
  }

  // Cerrar sesión y limpiar almacenamiento
  Future<void> logout() async {
    _token = null;
    _role = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_role');
  }

  // Login
  Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'username': username, 'password': password},
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        _token = jsonResponse['access_token'];

        await fetchCurrentUser();

        // Guardar token y rol persistentemente
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('auth_role', _role ?? 'ciudadano');

        return true;
      } else {
        return false;
      }
    } catch (e) {
      throw Exception('Error al conectar con el servidor CitySafe: $e');
    }
  }

  Future<void> fetchCurrentUser() async {
    if (_token == null) return;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/usuarios/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _role = data['rol'];
      }
    } catch (e) {
      debugPrint('Error obteniendo usuario actual: $e');
    }
  }

  // Register
  Future<User> register(
    String username,
    String password, {
    String rol = 'ciudadano',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/usuarios/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
          'rol': rol,
        }),
      );

      if (response.statusCode == 200) {
        return User.fromJson(json.decode(response.body));
      } else {
        throw Exception('Error al registrar usuario: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error al conectar con el servidor CitySafe: $e');
    }
  }

  // Obtener incidentes
  Future<List<Incident>> fetchIncidents() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/incidentes/'));

      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        return jsonResponse.map((data) => Incident.fromJson(data)).toList();
      } else {
        throw Exception('Error al cargar incidentes');
      }
    } catch (e) {
      throw Exception('Error al conectar con el servidor CitySafe: $e');
    }
  }

  // Crear incidente
  Future<Incident> createIncident(
    String tipo,
    double latitud,
    double longitud,
    int nivelUrgencia,
    String? descripcion,
  ) async {
    if (_token == null) {
      throw Exception('Debe iniciar sesión para crear un incidente');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/incidentes/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode({
          'tipo': tipo,
          'latitud': latitud,
          'longitud': longitud,
          'nivel_urgencia': nivelUrgencia,
          'descripcion': descripcion,
        }),
      );

      if (response.statusCode == 200) {
        return Incident.fromJson(json.decode(response.body));
      } else {
        throw Exception('Error al crear incidente: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error al conectar con el servidor CitySafe: $e');
    }
  }

  // Eliminar incidente
  Future<void> deleteIncident(int id) async {
    if (_token == null) {
      throw Exception('Debe iniciar sesión para eliminar un incidente');
    }

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/incidentes/$id'),
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode != 200) {
        throw Exception('Error al eliminar incidente: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error al conectar con el servidor CitySafe: $e');
    }
  }
}
