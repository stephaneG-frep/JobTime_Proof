import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../models/app_settings.dart';
import '../models/job_proof.dart';
import '../models/job_session.dart';

class FileService {
  final ImagePicker _imagePicker = ImagePicker();

  Future<String?> pickImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    return picked?.path;
  }

  Future<String?> pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    return result?.files.single.path;
  }

  Future<String?> pickJson() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    return result?.files.single.path;
  }

  Future<String> exportDataToJson({
    required List<JobSession> sessions,
    required AppSettings settings,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final now = DateTime.now();
    final file = File(
      '${directory.path}/jobtime_proof_export_${now.millisecondsSinceEpoch}.json',
    );

    final payload = {
      'exportedAt': now.toIso8601String(),
      'settings': settings.toJson(),
      'sessions': sessions.map((e) => e.toJson()).toList(),
    };

    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
    );
    return file.path;
  }

  Future<(AppSettings, List<JobSession>)> importDataFromJson(
    String path,
  ) async {
    final file = File(path);
    final content = await file.readAsString();
    final map = jsonDecode(content) as Map<String, dynamic>;

    final settings = AppSettings.fromJson(
      Map<String, dynamic>.from(map['settings'] as Map),
    );
    final sessions = (map['sessions'] as List<dynamic>)
        .map((e) => JobSession.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    return (settings, sessions);
  }

  JobProof buildUrlProof({
    required String sessionId,
    required String title,
    required String url,
    String? description,
  }) {
    return JobProof(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      sessionId: sessionId,
      title: title,
      type: JobProofType.url,
      url: url,
      description: description,
      createdAt: DateTime.now(),
    );
  }
}
