import 'package:dio/dio.dart';
import '../constants/app_constants.dart';

class NetworkManager {
  static NetworkManager? _instance;
  static NetworkManager get instance {
    _instance ??= NetworkManager._init();
    return _instance!;
  }

  late final Dio dio;

  NetworkManager._init() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );
  }
}