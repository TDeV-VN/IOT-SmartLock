import 'package:shared_preferences/shared_preferences.dart';

class LockNotificationManager {
  static const String _prefKeyPrefix = 'notification_subscription_';
  
  // Đăng ký lưu trạng thái đăng ký của thiết bị
  static Future<void> saveSubscriptionStatus(String lockId, bool isSubscribed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefKeyPrefix$lockId', isSubscribed);
  }
  
  // Lấy trạng thái đăng ký của thiết bị
  static Future<bool> getSubscriptionStatus(String lockId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_prefKeyPrefix$lockId') ?? false;
  }
  
  // Lấy tất cả các thiết bị đã đăng ký
  static Future<List<String>> getAllSubscribedLockIds() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    List<String> subscribedLockIds = [];
    
    for (final key in keys) {
      if (key.startsWith(_prefKeyPrefix)) {
        final isSubscribed = prefs.getBool(key) ?? false;
        if (isSubscribed) {
          final lockId = key.substring(_prefKeyPrefix.length);
          subscribedLockIds.add(lockId);
        }
      }
    }
    
    return subscribedLockIds;
  }
  
  // Xóa thông tin đăng ký của một thiết bị
  static Future<void> removeSubscription(String lockId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefKeyPrefix$lockId');
  }
}