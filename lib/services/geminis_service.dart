import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _apiKey = "AIzaSyCFDOnqlzaDw5JDnoPY3RtbcU8lOgVIhQw";

  // Usamos el modelo “gemini-2.5-flash” sin el sufijo “-latest”, que es más estándar.
  static const String _model = "gemini-2.5-flash";
  static const String _baseUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent";

  static Future<String> sendMessage(String message) async {
    final uri = Uri.parse("$_baseUrl?key=$_apiKey");
    try {
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": message},
              ],
            },
          ],
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"];
        return text ?? "No se obtuvo respuesta del modelo.";
      } else {
        // leer posible error del cuerpo de la respuesta
        String errorMsg = "Error del servidor: ${response.statusCode}";
        try {
          final body = jsonDecode(response.body);
          errorMsg += " – ${body["error"]?["message"] ?? ""}";
        } catch (_) {}
        return errorMsg;
      }
    } catch (e) {
      return "Error al conectar con Gemini: $e";
    }
  }
}
