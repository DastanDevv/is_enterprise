import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings.dart';

class SettingsService {
  static const String _settingsKey = 'app_settings';

  // Получение настроек
  Future<Settings> getSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);

      if (settingsJson != null) {
        final settingsMap = jsonDecode(settingsJson) as Map<String, dynamic>;
        return Settings.fromMap(settingsMap);
      }
    } catch (e) {
      print('Ошибка при загрузке настроек: $e');
    }

    // Если настройки не найдены или произошла ошибка, возвращаем дефолтные
    return Settings.defaultSettings();
  }

  // Сохранение настроек
  Future<bool> saveSettings(Settings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = jsonEncode(settings.toMap());
      return await prefs.setString(_settingsKey, settingsJson);
    } catch (e) {
      print('Ошибка при сохранении настроек: $e');
      return false;
    }
  }

  // Обновление отдельных настроек
  Future<bool> updateSettings({
    String? language,
    bool? darkMode,
    bool? notificationsEnabled,
    String? userName,
    String? userPosition,
    String? userAvatar,
  }) async {
    try {
      final currentSettings = await getSettings();
      final updatedSettings = currentSettings.copyWith(
        language: language,
        darkMode: darkMode,
        notificationsEnabled: notificationsEnabled,
        userName: userName,
        userPosition: userPosition,
        userAvatar: userAvatar,
      );

      return await saveSettings(updatedSettings);
    } catch (e) {
      print('Ошибка при обновлении настроек: $e');
      return false;
    }
  }

  // Сброс настроек до дефолтных
  Future<bool> resetSettings() async {
    try {
      return await saveSettings(Settings.defaultSettings());
    } catch (e) {
      print('Ошибка при сбросе настроек: $e');
      return false;
    }
  }
}
