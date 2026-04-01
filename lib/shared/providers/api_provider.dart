import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

// Este provider se sobreescribe en main.dart con la URL correcta
// Android: http://10.0.2.2:8080
// Windows: http://localhost:8080
final apiServiceProvider = Provider<ApiService>((ref) {
  throw UnimplementedError(
    'apiServiceProvider debe sobreescribirse en main.dart',
  );
});
