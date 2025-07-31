import 'package:http/http.dart' as http;

class NetworkService {
  Future<String?> fetchEvent(String ip) async {
    try {
      final response = await http.get(Uri.parse('http://$ip/event'));
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        return response.body;
      }
    } catch (_) {}
    return null;
  }
}
