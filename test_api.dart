import 'package:dio/dio.dart';

void main() async {
  final dio = Dio(BaseOptions(baseUrl: 'https://api-staging.suqyarahiq.com/api/v1'));
  try {
    final response = await dio.get('/mosques/miqat');
    print(response.data);
  } catch(e) {
    if (e is DioException) {
      print(e.response?.data);
    } else {
      print(e);
    }
  }
}
