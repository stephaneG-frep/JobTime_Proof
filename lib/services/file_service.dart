import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../models/app_settings.dart';
import '../models/job_proof.dart';
import '../models/job_session.dart';

class FileService {
  final ImagePicker _imagePicker = ImagePicker();

  Future<String?> pickImageFromGallery() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return null;
    return _persistPickedFile(
      originalPath: picked.path,
      bytes: null,
      fileName: picked.name,
      extensionFallback: 'jpg',
    );
  }

  Future<String?> pickImageFromCamera() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (picked == null) return null;
    return _persistPickedFile(
      originalPath: picked.path,
      bytes: null,
      fileName: picked.name,
      extensionFallback: 'jpg',
    );
  }

  Future<String?> pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final selected = result.files.single;
    return _persistPickedFile(
      originalPath: selected.path,
      bytes: selected.bytes,
      fileName: selected.name,
      extensionFallback: 'pdf',
    );
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

  Future<String> _persistPickedFile({
    required String? originalPath,
    required Uint8List? bytes,
    required String? fileName,
    required String extensionFallback,
  }) async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final proofsDir = Directory('${documentsDir.path}/proofs');
    if (!await proofsDir.exists()) {
      await proofsDir.create(recursive: true);
    }

    final safeName = (fileName != null && fileName.trim().isNotEmpty)
        ? fileName.trim()
        : 'proof_${DateTime.now().millisecondsSinceEpoch}.$extensionFallback';
    final targetPath =
        '${proofsDir.path}/${DateTime.now().microsecondsSinceEpoch}_$safeName';
    final targetFile = File(targetPath);

    if (bytes != null && bytes.isNotEmpty) {
      await targetFile.writeAsBytes(bytes, flush: true);
      return targetPath;
    }

    if (originalPath != null && originalPath.trim().isNotEmpty) {
      final source = File(originalPath);
      if (await source.exists()) {
        await source.copy(targetPath);
        return targetPath;
      }
    }

    throw Exception('Impossible de récupérer le fichier sélectionné.');
  }
}
