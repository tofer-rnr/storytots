import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportService {
  final SupabaseClient _supa = Supabase.instance.client;

  Future<String> uploadReportAndGetSignedUrl(
    Uint8List bytes, {
    String? suggestedName,
    Duration validFor = const Duration(days: 7),
  }) async {
    final user = _supa.auth.currentUser;
    if (user == null) {
      throw Exception('Not signed in');
    }

    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final base = suggestedName ?? 'StoryTots_Report_${y}-${m}-${d}.pdf';
    final path = '${user.id}/$y/$m/$base';

    // Upload (upsert so the latest replaces previous)
    await _supa.storage
        .from('reports')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'application/pdf',
            upsert: true,
          ),
        );

    // Signed URL
    final url = await _supa.storage
        .from('reports')
        .createSignedUrl(path, validFor.inSeconds);
    return url;
  }

  Future<void> notifyParents({
    required String signedUrl,
    required String childName,
  }) async {
    try {
      await _supa.functions.invoke(
        'notify_report',
        body: {'url': signedUrl, 'childName': childName},
      );
    } catch (_) {
      // Ignore notification errors on client; logging can be added later
    }
  }
}
