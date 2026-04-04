import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class LoanDocument {
  final String id;
  final String loanId;
  final String name;
  final String type; // 'Agreement', 'Sanction Letter', 'Schedule', 'Other'
  final String base64Data;
  final DateTime uploadedAt;
  final int sizeBytes;

  const LoanDocument({
    required this.id,
    required this.loanId,
    required this.name,
    required this.type,
    required this.base64Data,
    required this.uploadedAt,
    required this.sizeBytes,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'loanId': loanId, 'name': name, 'type': type,
    'base64Data': base64Data, 'uploadedAt': uploadedAt.toIso8601String(),
    'sizeBytes': sizeBytes,
  };

  factory LoanDocument.fromMap(Map<String, dynamic> m) => LoanDocument(
    id: m['id'], loanId: m['loanId'], name: m['name'], type: m['type'],
    base64Data: m['base64Data'], uploadedAt: DateTime.parse(m['uploadedAt']),
    sizeBytes: m['sizeBytes'] as int,
  );
}

// ── Provider ──────────────────────────────────────────────────────────────────

final documentsProvider = StreamProvider.family<List<LoanDocument>, String>((ref, loanId) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value([]);
  return FirebaseFirestore.instance
      .collection('users').doc(uid).collection('documents')
      .where('loanId', isEqualTo: loanId)
      .snapshots()
      .map((s) => s.docs.map((d) => LoanDocument.fromMap(d.data())).toList());
});

// ── Screen ────────────────────────────────────────────────────────────────────

class DocumentVaultScreen extends ConsumerStatefulWidget {
  final String loanId;
  final String loanName;
  const DocumentVaultScreen({super.key, required this.loanId, required this.loanName});

  @override
  ConsumerState<DocumentVaultScreen> createState() => _DocumentVaultScreenState();
}

class _DocumentVaultScreenState extends ConsumerState<DocumentVaultScreen> {
  bool _uploading = false;
  String _selectedType = 'Agreement';
  static const _types = ['Agreement', 'Sanction Letter', 'Schedule', 'Other'];

  Future<void> _upload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    final file = result.files.single;
    final bytes = file.bytes!;

    if (bytes.length > 700000) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('File too large. Please use files under 700KB.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
      return;
    }

    setState(() => _uploading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return; // session expired
      final docId = const Uuid().v4();
      final doc = LoanDocument(
        id: docId, loanId: widget.loanId,
        name: file.name, type: _selectedType,
        base64Data: base64Encode(bytes),
        uploadedAt: DateTime.now(), sizeBytes: bytes.length,
      );
      await FirebaseFirestore.instance
          .collection('users').doc(uid).collection('documents')
          .doc(docId).set(doc.toMap());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Document uploaded'), behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Upload failed: $e'), backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _delete(LoanDocument doc) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return; // session expired
    await FirebaseFirestore.instance
        .collection('users').doc(uid).collection('documents')
        .doc(doc.id).delete();
  }

  @override
  Widget build(BuildContext context) {
    final docsAsync = ref.watch(documentsProvider(widget.loanId));

    return Scaffold(
      appBar: AppBar(title: Text('${widget.loanName} — Docs')),
      body: Column(
        children: [
          // Upload bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).cardTheme.color,
            child: Row(children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (v) => setState(() => _selectedType = v!),
                  decoration: InputDecoration(
                    labelText: 'Document Type',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _uploading ? null : _upload,
                icon: _uploading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.upload_file_outlined, size: 18),
                label: const Text('Upload'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ]),
          ),
          const Divider(height: 1),
          Expanded(
            child: docsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (docs) => docs.isEmpty
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.folder_open_outlined, size: 56, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
                        SizedBox(height: 12),
                        Text('No documents yet', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55))),
                        SizedBox(height: 4),
                        Text('Upload PDFs or images (max 700KB)', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38))),
                      ]),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: docs.length,
                      separatorBuilder: (ctx, index) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) => _DocTile(doc: docs[i], onDelete: () => _delete(docs[i])),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocTile extends StatelessWidget {
  final LoanDocument doc;
  final VoidCallback onDelete;
  const _DocTile({required this.doc, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final sizeKb = (doc.sizeBytes / 1024).toStringAsFixed(0);
    final date = DateFormat('dd MMM yyyy').format(doc.uploadedAt);
    final isPdf = doc.name.toLowerCase().endsWith('.pdf');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: (isPdf ? AppColors.error : AppColors.primary).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
              color: isPdf ? AppColors.error : AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(doc.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('${doc.type} · ${sizeKb}KB · $date', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55))),
        ])),
        IconButton(
          icon: Icon(Icons.delete_outline, size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
          onPressed: onDelete,
        ),
      ]),
    );
  }
}
