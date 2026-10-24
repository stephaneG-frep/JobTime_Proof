import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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

  static const exportPrefix = 'jobtime_proof_export';
  static const autoBackupPrefix = 'jobtime_proof_autobackup';
  static const zipPrefix = 'jobtime_proof_complete';

  Future<String> exportDataToJson({
    required List<JobSession> sessions,
    required AppSettings settings,
    String prefix = exportPrefix,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final now = DateTime.now();
    final file = File(
      '${directory.path}/${prefix}_${now.millisecondsSinceEpoch}.json',
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

  Future<String> exportCompleteZip({
    required List<JobSession> sessions,
    required AppSettings settings,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final now = DateTime.now();
    final jsonPath = await exportDataToJson(
      sessions: sessions,
      settings: settings,
    );
    final zipPath =
        '${directory.path}/${zipPrefix}_${now.millisecondsSinceEpoch}.zip';
    final encoder = ZipFileEncoder()..create(zipPath);

    await encoder.addFile(File(jsonPath), 'jobtime_proof_export.json');
    for (final session in sessions) {
      for (final proof in session.proofs) {
        final path = proof.filePath?.trim();
        if (path == null || path.isEmpty) continue;
        final file = File(path);
        if (!await file.exists()) continue;
        final safeName = proof.title
            .replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '_')
            .replaceAll(RegExp(r'_+'), '_');
        final extension = file.uri.pathSegments.last.contains('.')
            ? '.${file.uri.pathSegments.last.split('.').last}'
            : '';
        await encoder.addFile(
          file,
          'proofs/${session.id}/${proof.id}_${safeName.isEmpty ? 'preuve' : safeName}$extension',
        );
      }
    }
    await encoder.close();
    await File(jsonPath).delete();
    return zipPath;
  }

  /// Opens the system share sheet so the user can save or send an export
  /// (files in the app documents directory are not reachable otherwise).
  Future<void> shareFile(String path, {String? subject}) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(path)], subject: subject),
    );
  }

  /// Keeps only the [keep] most recent exports whose name starts with [prefix].
  Future<void> pruneExports({required String prefix, required int keep}) async {
    final directory = await getApplicationDocumentsDirectory();
    final files =
        directory
            .listSync()
            .whereType<File>()
            .where((f) => f.uri.pathSegments.last.startsWith('${prefix}_'))
            .toList()
          ..sort((a, b) => b.path.compareTo(a.path));
    for (final file in files.skip(keep)) {
      await file.delete();
    }
  }

  /// Deletes the stored files of [proofs], limited to the app proofs directory
  /// (imported proofs may reference paths the app does not own).
  Future<void> deleteProofFiles(Iterable<JobProof> proofs) async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final proofsDirPath = '${documentsDir.path}/proofs/';
    for (final proof in proofs) {
      final path = proof.filePath?.trim();
      if (path == null || !path.startsWith(proofsDirPath)) continue;
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
  }

  /// Deletes every proof file and every JSON/ZIP export created by the app.
  Future<void> deleteAllLocalFiles() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final proofsDir = Directory('${documentsDir.path}/proofs');
    if (await proofsDir.exists()) await proofsDir.delete(recursive: true);
    for (final prefix in [exportPrefix, autoBackupPrefix, zipPrefix]) {
      await pruneExports(prefix: prefix, keep: 0);
    }
  }

  Future<(AppSettings, List<JobSession>)> importDataFromJson(
    String path,
  ) async {
    final content = await File(path).readAsString();
    try {
      final map = jsonDecode(content) as Map<String, dynamic>;

      final settings = AppSettings.fromJson(
        Map<String, dynamic>.from(map['settings'] as Map),
      );
      final sessions = (map['sessions'] as List<dynamic>)
          .map((e) => JobSession.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      return (settings, sessions);
    } catch (_) {
      throw const FormatException(
        'Fichier invalide : ce n\'est pas un export JobTime Proof.',
      );
    }
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
