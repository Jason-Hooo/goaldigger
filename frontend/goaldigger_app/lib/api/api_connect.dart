

part of '../main.dart';


class ApiConnect {
  String token = '';
  

String get baseUrl {
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    if (Platform.isIOS) return 'http://127.0.0.1:8000';
    return 'http://localhost:8000';
  }

//Login 帳號密碼呼叫
Future<String> fetchLogin(String username, String password) async {
  //先假設username和password是固定的，實際上應該從使用者輸入獲取
  //username = 'test';
  //password = '1234';
final response = await http.post(
    Uri.parse('$baseUrl/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'username': username,
      'password': password,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if(data['status'] == 'fail')
    {
      print('Login failed: ${data['message']}');
      return 'Login failed: ${data['message']}';
    }
    else
    {
      // 登入成功後呼叫
      if (data['status'] == 'ok') {
        await saveToken(data['token']);  // 存起來
      }
      print('Login successful, token: ${data['token']}');
      return 'ok';
    }
    //拿到後端丟過來的資料
  }

  return 'Login failed with status code: ${response.statusCode}';
}

Future<void> saveToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('token', token);
}

}