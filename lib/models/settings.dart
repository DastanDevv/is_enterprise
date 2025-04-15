class Settings {
  final String language;
  final bool darkMode;
  final bool notificationsEnabled;
  final String userName;
  final String userPosition;
  final String userAvatar;

  Settings({
    required this.language,
    required this.darkMode,
    required this.notificationsEnabled,
    required this.userName,
    required this.userPosition,
    this.userAvatar = '',
  });

  // Конвертация в Map для сохранения
  Map<String, dynamic> toMap() {
    return {
      'language': language,
      'darkMode': darkMode,
      'notificationsEnabled': notificationsEnabled,
      'userName': userName,
      'userPosition': userPosition,
      'userAvatar': userAvatar,
    };
  }

  // Создание из Map
  factory Settings.fromMap(Map<String, dynamic> map) {
    return Settings(
      language: map['language'] ?? 'Русский',
      darkMode: map['darkMode'] ?? false,
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      userName: map['userName'] ?? 'Администратор',
      userPosition: map['userPosition'] ?? 'Менеджер',
      userAvatar: map['userAvatar'] ?? '',
    );
  }

  // Создание копии с изменениями
  Settings copyWith({
    String? language,
    bool? darkMode,
    bool? notificationsEnabled,
    String? userName,
    String? userPosition,
    String? userAvatar,
  }) {
    return Settings(
      language: language ?? this.language,
      darkMode: darkMode ?? this.darkMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      userName: userName ?? this.userName,
      userPosition: userPosition ?? this.userPosition,
      userAvatar: userAvatar ?? this.userAvatar,
    );
  }

  // Дефолтные настройки
  factory Settings.defaultSettings() {
    return Settings(
      language: 'Русский',
      darkMode: false,
      notificationsEnabled: true,
      userName: 'Администратор',
      userPosition: 'Менеджер',
      userAvatar: '',
    );
  }
}
