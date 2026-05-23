import 'package:hive/hive.dart';

class AppSettings {
  AppSettings({
    required this.weeklyGoalHours,
    required this.customPlatforms,
    required this.otherPlatformWebUrl,
    required this.otherPlatformAppScheme,
    required this.darkModeEnabled,
    required this.createdAt,
    required this.updatedAt,
  });

  final int weeklyGoalHours;
  final List<String> customPlatforms;
  final String otherPlatformWebUrl;
  final String otherPlatformAppScheme;
  final bool darkModeEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppSettings copyWith({
    int? weeklyGoalHours,
    List<String>? customPlatforms,
    String? otherPlatformWebUrl,
    String? otherPlatformAppScheme,
    bool? darkModeEnabled,
  }) {
    return AppSettings(
      weeklyGoalHours: weeklyGoalHours ?? this.weeklyGoalHours,
      customPlatforms: customPlatforms ?? this.customPlatforms,
      otherPlatformWebUrl: otherPlatformWebUrl ?? this.otherPlatformWebUrl,
      otherPlatformAppScheme:
          otherPlatformAppScheme ?? this.otherPlatformAppScheme,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  factory AppSettings.initial() {
    final now = DateTime.now();
    return AppSettings(
      weeklyGoalHours: 10,
      customPlatforms: const [],
      otherPlatformWebUrl: '',
      otherPlatformAppScheme: '',
      darkModeEnabled: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, dynamic> toJson() => {
    'weeklyGoalHours': weeklyGoalHours,
    'customPlatforms': customPlatforms,
    'otherPlatformWebUrl': otherPlatformWebUrl,
    'otherPlatformAppScheme': otherPlatformAppScheme,
    'darkModeEnabled': darkModeEnabled,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    weeklyGoalHours: (json['weeklyGoalHours'] as int?) ?? 10,
    customPlatforms:
        ((json['customPlatforms'] as List<dynamic>?) ?? const <dynamic>[])
            .cast<String>(),
    otherPlatformWebUrl: (json['otherPlatformWebUrl'] as String?) ?? '',
    otherPlatformAppScheme: (json['otherPlatformAppScheme'] as String?) ?? '',
    darkModeEnabled: (json['darkModeEnabled'] as bool?) ?? false,
    createdAt:
        DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
        DateTime.now(),
    updatedAt:
        DateTime.tryParse((json['updatedAt'] as String?) ?? '') ??
        DateTime.now(),
  );
}

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 3;

  @override
  AppSettings read(BinaryReader reader) {
    final fields = <int, dynamic>{
      for (int i = 0; i < reader.readByte(); i++)
        reader.readByte(): reader.read(),
    };

    final now = DateTime.now();
    final rawPlatforms = fields[1] as List?;
    return AppSettings(
      weeklyGoalHours: (fields[0] as int?) ?? 10,
      customPlatforms: (rawPlatforms ?? const <dynamic>[]).cast<String>(),
      otherPlatformWebUrl: (fields[2] as String?) ?? '',
      otherPlatformAppScheme: (fields[3] as String?) ?? '',
      darkModeEnabled: (fields[6] as bool?) ?? false,
      createdAt: (fields[4] as DateTime?) ?? now,
      updatedAt: (fields[5] as DateTime?) ?? now,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.weeklyGoalHours)
      ..writeByte(1)
      ..write(obj.customPlatforms)
      ..writeByte(2)
      ..write(obj.otherPlatformWebUrl)
      ..writeByte(3)
      ..write(obj.otherPlatformAppScheme)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.darkModeEnabled);
  }
}
