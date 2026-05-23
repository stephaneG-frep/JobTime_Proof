import 'package:hive/hive.dart';

import 'job_proof.dart';

class JobSession {
  JobSession({
    required this.id,
    required this.platform,
    required this.actionType,
    required this.startTime,
    required this.endTime,
    required this.durationSeconds,
    required this.notes,
    required this.proofs,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String platform;
  final String actionType;
  final DateTime startTime;
  final DateTime endTime;
  final int durationSeconds;
  final String notes;
  final List<JobProof> proofs;
  final DateTime createdAt;
  final DateTime updatedAt;

  JobSession copyWith({
    String? platform,
    String? actionType,
    DateTime? startTime,
    DateTime? endTime,
    int? durationSeconds,
    String? notes,
    List<JobProof>? proofs,
  }) {
    return JobSession(
      id: id,
      platform: platform ?? this.platform,
      actionType: actionType ?? this.actionType,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      notes: notes ?? this.notes,
      proofs: proofs ?? this.proofs,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'platform': platform,
    'actionType': actionType,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'durationSeconds': durationSeconds,
    'notes': notes,
    'proofs': proofs.map((e) => e.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory JobSession.fromJson(Map<String, dynamic> json) => JobSession(
    id: json['id'] as String,
    platform: json['platform'] as String,
    actionType: json['actionType'] as String,
    startTime: DateTime.parse(json['startTime'] as String),
    endTime: DateTime.parse(json['endTime'] as String),
    durationSeconds: json['durationSeconds'] as int,
    notes: json['notes'] as String? ?? '',
    proofs: (json['proofs'] as List<dynamic>? ?? [])
        .map((e) => JobProof.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}

class JobSessionAdapter extends TypeAdapter<JobSession> {
  @override
  final int typeId = 2;

  @override
  JobSession read(BinaryReader reader) {
    final fields = <int, dynamic>{
      for (int i = 0; i < reader.readByte(); i++)
        reader.readByte(): reader.read(),
    };

    return JobSession(
      id: fields[0] as String,
      platform: fields[1] as String,
      actionType: fields[2] as String,
      startTime: fields[3] as DateTime,
      endTime: fields[4] as DateTime,
      durationSeconds: fields[5] as int,
      notes: fields[6] as String,
      proofs: (fields[7] as List).cast<JobProof>(),
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, JobSession obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.platform)
      ..writeByte(2)
      ..write(obj.actionType)
      ..writeByte(3)
      ..write(obj.startTime)
      ..writeByte(4)
      ..write(obj.endTime)
      ..writeByte(5)
      ..write(obj.durationSeconds)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.proofs)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt);
  }
}
