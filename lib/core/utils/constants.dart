class AppConstants {
  // URLs base según plataforma (ya se gestiona en main.dart)
  // Estas constantes son para referencia
  static const String baseUrlAndroid = 'http://10.0.2.2:8080';
  static const String baseUrlWindows = 'http://localhost:8080';

  // Estados de pedido
  static const List<String> estadosPedido = [
    'PENDIENTE',
    'PROCESADO',
    'ENVIADO',
    'ENTREGADO',
    'CANCELADO',
  ];

  // Colores por estado de pedido
  static const Map<String, int> coloresEstado = {
    'PENDIENTE': 0xFFFF9800,
    'PROCESADO': 0xFF2196F3,
    'ENVIADO': 0xFF9C27B0,
    'ENTREGADO': 0xFF4CAF50,
    'CANCELADO': 0xFFF44336,
  };
}
