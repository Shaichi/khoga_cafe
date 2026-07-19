import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final loginRes = await http.post(
    Uri.parse('http://localhost:8080/api/v1/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'username': 'manager', 'password': 'Admin@123'}),
  );
  
  final token = jsonDecode(loginRes.body)['data']['token'];
  
  final reportRes = await http.get(
    Uri.parse('http://localhost:8080/api/v1/attendance?from=2026-07-01&to=2026-07-31'),
    headers: {'Authorization': 'Bearer $token'},
  );
  
  print(reportRes.body);
}
