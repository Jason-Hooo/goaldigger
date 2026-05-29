part of '../main.dart';

class ApiConnect {
  String token = '';

  String get baseUrl {
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    if (Platform.isIOS) return 'http://127.0.0.1:8000';
    return 'http://localhost:8000';
  }

  //用token登入
  Future<String> tokenLogin() {
    String? token = getToken() as String?;
    if (token != null) {
      return Future.value(token);
    } else {
      print('No token found');
      return Future.error('No token found');
    }
  }

  //一般Login
  Future<String> fetchLogin(String username, String password) async {
    //先假設username和password是固定的，實際上應該從使用者輸入獲取
    //username = 'test';
    //password = '1234';
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'fail') {
        print('Login failed: ${data['message']}');
        return 'Login failed: ${data['message']}';
      } else {
        // 登入成功後呼叫
        if (data['status'] == 'ok') {
          await saveToken(data['token']); // 存起來
        }
        print('Login successful, token: ${data['token']}');
        return 'ok';
      }
      //拿到後端丟過來的資料
    }

    return 'Login failed with status code: ${response.statusCode}';
  }

  //登出，刪除token
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  //儲存token到SharedPreferences
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  //從SharedPreferences取出token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token'); // 取不到會回傳 null
  }


}
