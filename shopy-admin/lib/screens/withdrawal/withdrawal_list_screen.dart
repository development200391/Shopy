import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/withdrawal/admin_withdrawal.dart';
import '../../providers/admin_withdrawal_list_state.dart';
import '../../providers/admin_withdrawal_provider.dart';
import '../../services/admin_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/currency_formatter.dart';

const _statusChips = [
  (label: 'Semua', status: null),
  (label: 'Menunggu', status: AdminWithdrawalStatus.pending),
  (label: 'Diproses', status: AdminWithdrawalStatus.processing),
  (label: 'Selesai', status: AdminWithdrawalStatus.completed),
  (label: 'Ditolak', status: AdminWithdrawalStatus.rejected),
];

/// Tidak ada halaman detail terpisah — daftar pencairan sudah cukup ringkas
/// buat ditampilkan sekaligus, jadi aksi (proses/selesaikan/tolak) dibuka
/// lewat bottom sheet dari kartu list-nya langsung.
class WithdrawalListScreen extends ConsumerStatefulWidget {
  const WithdrawalListScreen({super.key});

  @override
  ConsumerState<WithdrawalListScreen> createState() => _WithdrawalListScreenState();
}

class _WithdrawalListScreenState extends ConsumerState<WithdrawalListScreen> {
  Future<void> _openActions(AdminWithdrawalListItem withdrawal) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _WithdrawalActionsSheet(withdrawal: withdrawal),
    );
    ref.read(adminWithdrawalListProvider.notifier).reload();
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(adminWithdrawalListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Pencairan Dana')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _statusChips.length,
                separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final chip = _statusChips[index];
                  final active = chip.status == list.statusFilter;
                  return ChoiceChip(
                    label: Text(chip.label),
                    selected: active,
                    onSelected: (_) => ref.read(adminWithdrawalListProvider.notifier).setStatusFilter(chip.status),
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(color: active ? Colors.white : AppColors.textPrimary),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.06),
                    side: BorderSide.none,
                  );
                },
              ),
            ),
          ),
          Expanded(child: _WithdrawalListBody(list: list, onTap: _openActions)),
        ],
      ),
    );
  }
}

class _WithdrawalListBody extends ConsumerWidget {
  final AdminWithdrawalListState list;
  final void Function(AdminWithdrawalListItem) onTap;

  const _WithdrawalListBody({required this.list, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (list.loading && list.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (list.error != null && list.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Gagal memuat daftar pencairan', style: TextStyle(color: AppColors.textSecondary)),
            TextButton(
              onPressed: () => ref.read(adminWithdrawalListProvider.notifier).reload(),
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }

    if (list.items.isEmpty) {
      return const Center(
        child: Text('Tidak ada pencairan di kategori ini.', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(adminWithdrawalListProvider.notifier).reload(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: list.items.length + (list.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= list.items.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(
                child: list.loading
                    ? const CircularProgressIndicator()
                    : OutlinedButton(
                        onPressed: () => ref.read(adminWithdrawalListProvider.notifier).loadMore(),
                        child: const Text('Muat Lebih Banyak'),
                      ),
              ),
            );
          }

          final withdrawal = list.items[index];
          return _WithdrawalCard(withdrawal: withdrawal, onTap: () => onTap(withdrawal));
        },
      ),
    );
  }
}

class _WithdrawalCard extends StatelessWidget {
  final AdminWithdrawalListItem withdrawal;
  final VoidCallback onTap;

  const _WithdrawalCard({required this.withdrawal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.payments_outlined, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(withdrawal.storeName, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    '${withdrawal.bankName} ${withdrawal.accountNumberMasked}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(formatRupiah(withdrawal.netAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                _StatusBadge(status: withdrawal.status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final AdminWithdrawalStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      AdminWithdrawalStatus.pending => AppColors.warning,
      AdminWithdrawalStatus.processing => AppColors.primary,
      AdminWithdrawalStatus.completed => AppColors.success,
      AdminWithdrawalStatus.rejected => AppColors.error,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(status.label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _WithdrawalActionsSheet extends ConsumerStatefulWidget {
  final AdminWithdrawalListItem withdrawal;

  const _WithdrawalActionsSheet({required this.withdrawal});

  @override
  ConsumerState<_WithdrawalActionsSheet> createState() => _WithdrawalActionsSheetState();
}

class _WithdrawalActionsSheetState extends ConsumerState<_WithdrawalActionsSheet> {
  bool _busy = false;

  Future<void> _process() => _updateStatus(AdminWithdrawalStatus.processing);

  Future<void> _complete() => _updateStatus(AdminWithdrawalStatus.completed);

  Future<void> _reject() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tolak Pencairan'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Alasan (wajib diisi)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              Navigator.of(context).pop(text);
            },
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
    if (reason == null) return;
    await _updateStatus(AdminWithdrawalStatus.rejected, reason: reason);
  }

  Future<void> _updateStatus(AdminWithdrawalStatus status, {String? reason}) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(adminWithdrawalApiServiceProvider)
          .updateStatus(widget.withdrawal.id, status, reason: reason);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on AdminException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.error));
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.withdrawal;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(w.storeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: AppSpacing.sm),
          _Row(label: 'Jumlah diajukan', value: formatRupiah(w.amount)),
          _Row(label: 'Biaya admin', value: formatRupiah(w.adminFee)),
          _Row(label: 'Diterima seller', value: formatRupiah(w.netAmount)),
          _Row(label: 'Bank tujuan', value: '${w.bankName} ${w.accountNumberMasked}'),
          _Row(label: 'Status', value: w.status.label),
          const SizedBox(height: AppSpacing.md),
          if (w.status == AdminWithdrawalStatus.pending) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : _reject,
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
                    child: const Text('Tolak'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _busy ? null : _process,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                    child: _busy
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Proses'),
                  ),
                ),
              ],
            ),
          ] else if (w.status == AdminWithdrawalStatus.processing) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _busy ? null : _complete,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
                child: _busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Tandai Selesai'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
