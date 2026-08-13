import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/finance/withdrawal.dart';
import '../../models/store/bank_account.dart';
import '../../providers/seller_finance_provider.dart';
import '../../providers/store_settings_provider.dart';
import '../../services/seller_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/currency_formatter.dart';

/// Cerminan `Platform:WithdrawalAdminFee` di backend — biaya flat, dipakai buat
/// pratinjau rincian real-time sebelum submit (backend yang jadi sumber kebenaran akhir).
const kWithdrawalAdminFee = 2500;

/// Halaman **Pencairan Dana** — desain terpilih: **Bold & Colorful**
/// (lihat `design/assets/pencairan-seller-bold-colorful.png`).
class WithdrawalScreen extends ConsumerStatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  ConsumerState<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends ConsumerState<WithdrawalScreen> {
  final _amountController = TextEditingController();
  String? _selectedBankAccountId;
  bool _submitting = false;
  bool _changed = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  BankAccount? _resolveSelected(List<BankAccount> accounts) {
    if (accounts.isEmpty) return null;
    return accounts.where((a) => a.id == _selectedBankAccountId).firstOrNull ??
        accounts.where((a) => a.isDefault).firstOrNull ??
        accounts.first;
  }

  Future<void> _pickBankAccount(List<BankAccount> accounts) async {
    final chosen = await showModalBottomSheet<BankAccount>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text('Pilih Rekening', style: Theme.of(context).textTheme.titleMedium),
            ),
            for (final account in accounts)
              ListTile(
                leading: const Icon(Icons.account_balance_outlined, color: AppColors.primary),
                title: Text(account.bankName),
                subtitle: Text('${account.accountNumber} · ${account.accountHolderName}'),
                onTap: () => Navigator.of(context).pop(account),
              ),
          ],
        ),
      ),
    );
    if (chosen != null) setState(() => _selectedBankAccountId = chosen.id);
  }

  Future<void> _submit(int availableBalance) async {
    final amount = int.tryParse(_amountController.text) ?? 0;
    final accounts = ref.read(bankAccountsProvider).items;
    final bankAccount = _resolveSelected(accounts);

    if (bankAccount == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tambahkan rekening bank dulu.')));
      return;
    }
    if (amount <= 0 || amount > availableBalance) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Jumlah pencairan tidak valid.')));
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref
          .read(sellerFinanceApiServiceProvider)
          .requestWithdrawal(bankAccountId: bankAccount.id, amount: amount);
      _changed = true;
      _amountController.clear();
      ref.invalidate(withdrawalsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pencairan diajukan, menunggu diproses.')));
    } on SellerException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final balanceAsync = ref.watch(storeBalanceProvider);
    final bankAccountState = ref.watch(bankAccountsProvider);
    final withdrawalsAsync = ref.watch(withdrawalsProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Cairkan Dana')),
        body: balanceAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              Center(child: TextButton(onPressed: () => ref.invalidate(storeBalanceProvider), child: const Text('Coba lagi'))),
          data: (balance) {
            final accounts = bankAccountState.items;
            final selected = _resolveSelected(accounts);
            final amount = int.tryParse(_amountController.text) ?? 0;
            final netAmount = amount > kWithdrawalAdminFee ? amount - kWithdrawalAdminFee : 0;

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Saldo bisa dicairkan', style: TextStyle(color: AppColors.textSecondary)),
                      Text(
                        formatRupiah(balance.availableBalance),
                        style: const TextStyle(color: AppColors.primary, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Jumlah Pencairan', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 6),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    prefixText: 'Rp ',
                    suffixIcon: TextButton(
                      onPressed: () => setState(
                        () => _amountController.text = '${balance.availableBalance}',
                      ),
                      child: const Text('Cairkan semua'),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Minimal Rp50.000 · maksimal 3x pencairan per hari',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Rekening Tujuan', style: Theme.of(context).textTheme.titleMedium),
                    if (accounts.length > 1)
                      TextButton(onPressed: () => _pickBankAccount(accounts), child: const Text('Ubah')),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                if (selected == null)
                  const Text('Belum ada rekening bank. Tambah rekening dulu di Profil Toko.')
                else
                  _BankAccountCard(account: selected),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    children: [
                      const Text('Rincian', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: AppSpacing.sm),
                      _rincianRow('Jumlah pencairan', formatRupiah(amount)),
                      _rincianRow('Biaya admin bank', '- ${formatRupiah(kWithdrawalAdminFee)}'),
                      const Divider(height: AppSpacing.lg),
                      _rincianRow('Diterima', formatRupiah(netAmount), bold: true, color: AppColors.success),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Dana masuk 1-2 hari kerja. Pencairan di atas jam 15.00 diproses besok.',
                          style: TextStyle(color: Colors.blue, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : () => _submit(balance.availableBalance),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                          )
                        : const Text('Ajukan Pencairan'),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('Riwayat Pencairan', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                withdrawalsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => const Text('Gagal memuat riwayat pencairan.'),
                  data: (withdrawals) => withdrawals.isEmpty
                      ? const Text('Belum ada riwayat pencairan.', style: TextStyle(color: AppColors.textSecondary))
                      : Column(
                          children: [for (final w in withdrawals) _WithdrawalTile(withdrawal: w)],
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _rincianRow(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: bold ? AppColors.textPrimary : AppColors.textSecondary)),
          Text(
            value,
            style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

class _BankAccountCard extends StatelessWidget {
  final BankAccount account;

  const _BankAccountCard({required this.account});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            child: const Icon(Icons.account_balance_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${account.bankName} · ${account.accountNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(account.accountHolderName, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                if (account.isVerified)
                  const Row(
                    children: [
                      Icon(Icons.check_circle, size: 12, color: AppColors.success),
                      SizedBox(width: 2),
                      Text('Rekening sudah terverifikasi', style: TextStyle(color: AppColors.success, fontSize: 11)),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WithdrawalTile extends StatelessWidget {
  final Withdrawal withdrawal;

  const _WithdrawalTile({required this.withdrawal});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (withdrawal.status) {
      'Completed' => ('Berhasil', AppColors.success),
      'Processing' => ('Diproses', AppColors.warning),
      'Rejected' => ('Ditolak', AppColors.error),
      _ => ('Menunggu', AppColors.warning),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.account_balance_outlined, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formatRupiah(withdrawal.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  '${_formatDate(withdrawal.requestedAt)} - ${withdrawal.bankName} ${withdrawal.accountNumberMasked}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
            child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '$day ${months[local.month - 1]} ${local.year}';
  }
}
