import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/store/admin_store.dart';
import '../../providers/admin_store_provider.dart';
import '../../services/admin_exception.dart';
import '../../services/api_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class StoreDetailScreen extends ConsumerStatefulWidget {
  final String storeId;

  const StoreDetailScreen({super.key, required this.storeId});

  @override
  ConsumerState<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends ConsumerState<StoreDetailScreen> {
  bool _busy = false;

  Future<void> _approve() async {
    setState(() => _busy = true);
    try {
      await ref.read(adminStoreApiServiceProvider).approve(widget.storeId);
      ref.invalidate(adminStoreDetailProvider(widget.storeId));
    } on AdminException catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject() async {
    final reason = await _promptReason(title: 'Tolak Toko', requireReason: true);
    if (reason == null) return;

    setState(() => _busy = true);
    try {
      await ref.read(adminStoreApiServiceProvider).reject(widget.storeId, reason);
      ref.invalidate(adminStoreDetailProvider(widget.storeId));
    } on AdminException catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _suspend() async {
    final reason = await _promptReason(title: 'Suspend Toko', requireReason: false);
    if (reason == null) return;

    setState(() => _busy = true);
    try {
      await ref.read(adminStoreApiServiceProvider).suspend(widget.storeId, reason.isEmpty ? null : reason);
      ref.invalidate(adminStoreDetailProvider(widget.storeId));
    } on AdminException catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _activate() async {
    setState(() => _busy = true);
    try {
      await ref.read(adminStoreApiServiceProvider).activate(widget.storeId);
      ref.invalidate(adminStoreDetailProvider(widget.storeId));
    } on AdminException catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _promptReason({required String title, required bool requireReason}) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: requireReason ? 'Alasan (wajib diisi)' : 'Alasan (opsional)',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              if (requireReason && text.isEmpty) return;
              Navigator.of(context).pop(text);
            },
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: AppColors.error));
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(adminStoreDetailProvider(widget.storeId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Detail Toko')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Gagal memuat toko', style: TextStyle(color: AppColors.textSecondary)),
              TextButton(
                onPressed: () => ref.invalidate(adminStoreDetailProvider(widget.storeId)),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
        data: (store) => _StoreDetailBody(
          store: store,
          busy: _busy,
          onApprove: _approve,
          onReject: _reject,
          onSuspend: _suspend,
          onActivate: _activate,
        ),
      ),
    );
  }
}

class _StoreDetailBody extends StatelessWidget {
  final AdminStoreDetail store;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onSuspend;
  final VoidCallback onActivate;

  const _StoreDetailBody({
    required this.store,
    required this.busy,
    required this.onApprove,
    required this.onReject,
    required this.onSuspend,
    required this.onActivate,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: store.logoUrl == null
                  ? null
                  : NetworkImage('${resolveApiBaseUrl()}${store.logoUrl}'),
              child: store.logoUrl == null
                  ? const Icon(Icons.storefront_outlined, color: AppColors.primary, size: 28)
                  : null,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(store.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text('/${store.slug}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  _StatusChip(status: store.status),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (store.moderationReason != null && store.moderationReason!.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Alasan Moderasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.error)),
                const SizedBox(height: 4),
                Text(store.moderationReason!, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        _InfoCard(store: store),
        const SizedBox(height: AppSpacing.md),
        const Text('Dokumen Verifikasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: AppSpacing.sm),
        if (store.documents.isEmpty)
          const Text('Belum ada dokumen diunggah.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))
        else
          for (final doc in store.documents) _DocumentTile(document: doc),
        const SizedBox(height: AppSpacing.lg),
        _ActionButtons(
          status: store.status,
          busy: busy,
          onApprove: onApprove,
          onReject: onReject,
          onSuspend: onSuspend,
          onActivate: onActivate,
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final AdminStoreDetail store;

  const _InfoCard({required this.store});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(label: 'Pemilik', value: '${store.ownerName} (${store.ownerEmail})'),
          _InfoRow(label: 'Telepon', value: store.phoneNumber ?? '-'),
          _InfoRow(label: 'Produk', value: '${store.productCount}'),
          _InfoRow(label: 'Pengikut', value: '${store.followerCount}'),
          _InfoRow(label: 'Rating', value: '${store.ratingAverage.toStringAsFixed(1)} (${store.ratingCount})'),
          if (store.description != null && store.description!.isNotEmpty)
            _InfoRow(label: 'Deskripsi', value: store.description!),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 84, child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  final AdminStoreDocument document;

  const _DocumentTile({required this.document});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: GestureDetector(
              onTap: () => showDialog(
                context: context,
                builder: (context) => Dialog(
                  child: Image.network('${resolveApiBaseUrl()}${document.fileUrl}'),
                ),
              ),
              child: SizedBox(
                width: 48,
                height: 48,
                child: Image.network('${resolveApiBaseUrl()}${document.fileUrl}', fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(document.type, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(document.status, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final AdminStoreStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      AdminStoreStatus.pending => AppColors.warning,
      AdminStoreStatus.active => AppColors.success,
      AdminStoreStatus.suspended => AppColors.error,
      AdminStoreStatus.closed => AppColors.textSecondary,
      AdminStoreStatus.rejected => AppColors.error,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(status.label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final AdminStoreStatus status;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onSuspend;
  final VoidCallback onActivate;

  const _ActionButtons({
    required this.status,
    required this.busy,
    required this.onApprove,
    required this.onReject,
    required this.onSuspend,
    required this.onActivate,
  });

  @override
  Widget build(BuildContext context) {
    if (status == AdminStoreStatus.pending) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: busy ? null : onReject,
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
              child: const Text('Tolak'),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: ElevatedButton(
              onPressed: busy ? null : onApprove,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
              child: busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Setujui'),
            ),
          ),
        ],
      );
    }

    if (status == AdminStoreStatus.active) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: busy ? null : onSuspend,
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
          child: const Text('Suspend Toko'),
        ),
      );
    }

    if (status == AdminStoreStatus.suspended) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: busy ? null : onActivate,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
          child: busy
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Aktifkan Kembali'),
        ),
      );
    }

    // Rejected/Closed — status final, tidak ada aksi lanjutan lewat app ini.
    return const SizedBox.shrink();
  }
}
