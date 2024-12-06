
import 'package:background_locator_2/location_dto.dart';

class CallbackHandler {
  static Future<void> initCallback(Map<dynamic, dynamic> params) async {
    print('BackgroundLocator: Initialized');
  }

  static Future<void> disposeCallback() async {
    print('BackgroundLocator: Disposed');
  }

  static Future<void> callback(LocationDto locationDto) async {
    print('Location: ${locationDto.latitude}, ${locationDto.longitude}');
  }
}
