import 'package:hive/hive.dart';

class AppSettings {
  AppSettings({
    required this.weeklyGoalHours,
    required this.customPlatforms,
    required this.otherPlatformWebUrl,
    required this.otherPlatformAppScheme,
    required this.darkModeEnabled,
    required this.aiProvider,
    required this.aiModel,
    this.lastAutoBackupAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final int weeklyGoalHours;
  final List<String> customPlatforms;
  final String otherPlatformWebUrl;
  final String otherPlatformAppScheme;
  final bool darkModeEnabled;
  final String aiProvider;
  final String aiModel;
  final DateTime? lastAutoBackupAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppSettings copyWith({
    int? weeklyGoalHours,
    List<String>? customPlatforms,
    String? otherPlatformWebUrl,
    String? otherPlatformAppScheme,
    bool? darkModeEnabled,
    String? aiProvider,
    String? aiModel,
    DateTime? lastAutoBackupAt,
  }) {
    return AppSettings(
      weeklyGoalHours: weeklyGoalHours ?? this.weeklyGoalHours,
      customPlatforms: customPlatforms ?? this.customPlatforms,
      otherPlatformWebUrl: otherPlatformWebUrl ?? this.otherPlatformWebUrl,
      otherPlatformAppScheme:
          otherPlatformAppScheme ?? this.otherPlatformAppScheme,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      aiProvider: aiProvider ?? this.aiProvider,
      aiModel: aiModel ?? this.aiModel,
      lastAutoBackupAt: lastAutoBackupAt ?? this.lastAutoBackupAt,
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
      aiProvider: 'openai',
      aiModel: 'gpt-4.1-mini',
      lastAutoBackupAt: null,
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
    'aiProvider': aiProvider,
    'aiModel': aiModel,
    'lastAutoBackupAt': lastAutoBackupAt?.toIso8601String(),
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
    aiProvider: (json['aiProvider'] as String?) ?? 'openai',
    aiModel:
        (json['aiModel'] as String?) ??
        (json['openAiModel'] as String?) ??
        'gpt-4.1-mini',
    lastAutoBackupAt: DateTime.tryParse(
      (json['lastAutoBackupAt'] as String?) ?? '',
    ),
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
    final f2 = fields[2];
    final f3 = fields[3];
    final f4 = fields[4];
    final f5 = fields[5];
    final f6 = fields[6];
    final f7 = fields[7];
    final f8 = fields[8];
    final f9 = fields[9];

    // Backward compatibility:
    // - legacy format stored createdAt/updatedAt in fields 2/3
    // - newer format stores custom "Autre" URLs in 2/3 and dates in 4/5
    final legacyCreatedAt = f2 is DateTime ? f2 : null;
    final legacyUpdatedAt = f3 is DateTime ? f3 : null;
    final modernCreatedAt = f4 is DateTime ? f4 : null;
    final modernUpdatedAt = f5 is DateTime ? f5 : null;

    return AppSettings(
      weeklyGoalHours: (fields[0] as int?) ?? 10,
      customPlatforms: (rawPlatforms ?? const <dynamic>[]).cast<String>(),
      otherPlatformWebUrl: f2 is String ? f2 : '',
      otherPlatformAppScheme: f3 is String ? f3 : '',
      darkModeEnabled: f6 is bool ? f6 : false,
      aiProvider: f7 is String ? f7 : 'openai',
      aiModel: f8 is String ? f8 : 'gpt-4.1-mini',
      lastAutoBackupAt: f9 is DateTime ? f9 : null,
      createdAt: modernCreatedAt ?? legacyCreatedAt ?? now,
      updatedAt: modernUpdatedAt ?? legacyUpdatedAt ?? now,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(10)
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
      ..write(obj.darkModeEnabled)
      ..writeByte(7)
      ..write(obj.aiProvider)
      ..writeByte(8)
      ..write(obj.aiModel)
      ..writeByte(9)
      ..write(obj.lastAutoBackupAt);
  }
}
