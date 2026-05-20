import 'user.dart';

class Incident {
  final int id;
  final String tipo;
  final double latitud;
  final double longitud;
  final int nivelUrgencia;
  final String? descripcion;
  final String fechaReporte;
  final User? usuario;

  Incident({
    required this.id,
    required this.tipo,
    required this.latitud,
    required this.longitud,
    required this.nivelUrgencia,
    this.descripcion,
    required this.fechaReporte,
    this.usuario,
  });

  factory Incident.fromJson(Map<String, dynamic> json) {
    return Incident(
      id: json['id'],
      tipo: json['tipo'],
      latitud: json['latitud'],
      longitud: json['longitud'],
      nivelUrgencia: json['nivel_urgencia'],
      descripcion: json['descripcion'],
      fechaReporte: json['fecha_reporte'],
      usuario: json['usuario'] != null ? User.fromJson(json['usuario']) : null,
    );
  }
}