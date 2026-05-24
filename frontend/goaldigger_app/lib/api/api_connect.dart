

part of '../main.dart';


class ApiConnect {
  // static Future<String> fetchData() async {
  //   // 模擬 API 呼叫
  //   await Future.delayed(const Duration(seconds: 2));
  //   return 'API 資料已成功獲取！';
  // }
String get baseUrl {
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    if (Platform.isIOS) return 'http://127.0.0.1:8000';
    return 'http://localhost:8000';
  }

Future<void> fetchLogin() async {
  final response = await http.get(
    Uri.parse('${baseUrl}/login'),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    print(data['message']); // Hello from Python!
  }
}
}