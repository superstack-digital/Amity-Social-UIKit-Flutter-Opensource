import 'package:amity_uikit_beta_service/model/amity_notification_model.dart';
import 'package:dio/dio.dart';

import 'noti_repo.dart';

class AmityNotificationRepoImp implements AmityNotificationRepo {
  String? accessToken;

  @override
  void initRepo(String accessToken) {
    this.accessToken = accessToken;
  }

  @override
  Future<void> fetchNotification(
      Function(AmityNotifications? notifications, String? error)
          callback) async {
    var dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ));
    try {
      final response = await dio.get(
        "https://beta.amity.services/notifications/history",
        options: Options(
          headers: {
            "Authorization": "Bearer $accessToken" // set content-length
          },
        ),
      );

      if (response.statusCode == 200) {
        var amityPushNotification = AmityNotifications.fromJson(response.data);
        callback(amityPushNotification, null);
      } else {
        callback(
          null,
          response.data["message"],
        );
      }
    } catch (e) {
      // Timeout / network error: surface via callback instead of hanging or
      // throwing uncaught on the notification-load path.
      callback(null, e.toString());
    }
  }

  @override
  Future<void> markLastRead(Function(String? data, String? errpr) callback) {
    // TODO: implement markLastRead
    throw UnimplementedError();
  }

  @override
  Future<void> readNotification(
      {String? targetId,
      String? targetGroup,
      required Function(String? data, String? errpr) callback}) {
    // TODO: implement readNotification
    throw UnimplementedError();
  }
}
