import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/address/address.dart';
import '../../providers/address_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../address/address_form_sheet.dart';

/// Bottom sheet "Pilih Alamat Pengiriman" (mockup Checkout). Return [Address]
/// yang dipilih, atau `null` kalau ditutup tanpa memilih.
Future<Address?> showAddressPickerSheet(BuildContext context, {String? selectedId}) {
  return showModalBottomSheet<Address>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
    builder: (sheetContext) => _AddressPickerSheet(initialSelectedId: selectedId),
  );
}

class _AddressPickerSheet extends ConsumerStatefulWidget {
  final String? initialSelectedId;

  const _AddressPickerSheet({this.initialSelectedId});

  @override
  ConsumerState<_AddressPickerSheet> createState() => _AddressPickerSheetState();
}

class _AddressPickerSheetState extends ConsumerState<_AddressPickerSheet> {
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.initialSelectedId;
  }

  @override
  Widget build(BuildContext context) {
    final addressState = ref.watch(addressProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(3)),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pilih Alamat Pengiriman', style: Theme.of(context).textTheme.titleMedium),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (addressState.loading && addressState.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            ...addressState.items.map(
              (address) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _AddressOption(
                  address: address,
                  selected: address.id == _selectedId,
                  onTap: () => setState(() => _selectedId = address.id),
                ),
              ),
            ),
          OutlinedButton.icon(
            onPressed: () async {
              final saved = await showAddressFormSheet(context);
              if (saved == true) {
                final items = ref.read(addressProvider).items;
                if (items.isNotEmpty && mounted) {
                  setState(() => _selectedId = items.last.id);
                }
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              minimumSize: const Size.fromHeight(48),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Tambah Alamat Baru'),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedId == null
                  ? null
                  : () {
                      final selected = addressState.items.firstWhere((a) => a.id == _selectedId);
                      Navigator.of(context).pop(selected);
                    },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: const Text('Pilih Alamat Ini'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressOption extends StatelessWidget {
  final Address address;
  final bool selected;
  final VoidCallback onTap;

  const _AddressOption({required this.address, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppColors.primary : AppColors.divider, width: selected ? 2 : 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      address.label,
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${address.recipientName}  ${address.phoneNumber}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(address.fullAddress, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(left: AppSpacing.sm),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: selected ? AppColors.primary : AppColors.divider, width: 2),
              ),
              child: selected
                  ? Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
