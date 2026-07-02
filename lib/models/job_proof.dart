import 'package:hive/hive.dart';

enum JobProofType { image, pdf, url, note }

class JobProof {
  JobProof({
    required this.id,
    required this.sessionId,
    required this.title,
    required this.type,
    this.filePath,
    this.url,
    this.description,
    this.didApply = false,
    required this.createdAt,
  });

  final String id;
  final String sessionId;
  final String title;
  final JobProofType type;
  final String? filePath;
  final String? url;
  final String? description;
  final bool didApply;
  final DateTime createdAt;

  JobProof copyWith({
    String? id,
    String? sessionId,
    String? title,
    JobProofType? type,
    String? filePath,
    String? url,
    String? description,
    bool? didApply,
    DateTime? createdAt,
  }) {
    return JobProof(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      title: title ?? this.title,
      type: type ?? this.type,
      filePath: filePath ?? this.filePath,
      url: url ?? this.url,
      description: description ?? this.description,
      didApply: didApply ?? this.didApply,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionId': sessionId,
    'title': title,
    'type': type.name,
    'filePath': filePath,
    'url': url,
    'description': description,
    'didApply': didApply,
    'createdAt': createdAt.toIso8601String(),
  };

  factory JobProof.fromJson(Map<String, dynamic> json) => JobProof(
    id: json['id'] as String,
    sessionId: json['sessionId'] as String,
    title: json['title'] as String,
    type: JobProofType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => JobProofType.note,
    ),
    filePath: json['filePath'] as String?,
    url: json['url'] as String?,
    description: json['description'] as String?,
    didApply: (json['didApply'] as bool?) ?? false,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

class JobProofTypeAdapter extends TypeAdapter<JobProofType> {
  @override
  final int typeId = 0;

  @override
  JobProofType read(BinaryReader reader) =>
      JobProofType.values[reader.readByte()];

  @override
  void write(BinaryWriter writer, JobProofType obj) =>
      writer.writeByte(obj.index);
}

class JobProofAdapter extends TypeAdapter<JobProof> {
  @override
  final int typeId = 1;

  @override
  JobProof read(BinaryReader reader) {
    final fields = <int, dynamic>{
      for (int i = 0; i < reader.readByte(); i++)
        reader.readByte(): reader.read(),
    };

    return JobProof(
      id: fields[0] as String,
      sessionId: fields[1] as String,
      title: fields[2] as String,
      type: fields[3] as JobProofType,
      filePath: fields[4] as String?,
      url: fields[5] as String?,
      description: fields[6] as String?,
      didApply: (fields[8] as bool?) ?? false,
      createdAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, JobProof obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.sessionId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.filePath)
      ..writeByte(5)
      ..write(obj.url)
      ..writeByte(6)
      ..write(obj.description)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.didApply);
  }
}
