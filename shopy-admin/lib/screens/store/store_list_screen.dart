import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/store/admin_store.dart';
import '../../providers/admin_store_list_state.dart';
import '../../providers/admin_store_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'store_detail_screen.dart';

const _statusChips = [
  (label: 'Semua', status: null),
  (label: 'Menunggu', status: AdminStoreStatus.pending),
  (label: 'Aktif', status: AdminStoreStatus.active),
  (label: 'Ditangguhkan', status: AdminStoreStatus.suspended),
  (label: 'Ditolak', status: AdminStoreStatus.rejected),
];

class StoreListScreen extends ConsumerStatefulWidget {
  const StoreListScreen({super.key});

  @override
  ConsumerState<StoreListScreen> createState() => _StoreListScreenState();
}

class _StoreListScreenState extends ConsumerState<StoreListScreen> {
  bool _searching = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(adminStoreListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Cari nama toko...', border: InputBorder.none),
                onSubmitted: (value) => ref.read(adminStoreListProvider.notifier).setSearch(value.trim()),
              )
            : const Text('Verifikasi Toko'),
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) {
                _searchController.clear();
                ref.read(adminStoreListProvider.notifier).setSearch('');
              }
            }),
          ),
        ],
      ),
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
                    onSelected: (_) => ref.read(adminStoreListProvider.notifier).setStatusFilter(chip.status),
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(color: active ? Colors.white : AppColors.textPrimary),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.06),
                    side: BorderSide.none,
                  );
                },
              ),
            ),
          ),
          Expanded(child: _StoreListBody(list: list)),
        ],
      ),
    );
  }
}

class _StoreListBody extends ConsumerWidget {
  final AdminStoreListState list;

  const _StoreListBody({required this.list});

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
            const Text('Gagal memuat daftar toko', style: TextStyle(color: AppColors.textSecondary)),
            TextButton(
              onPressed: () => ref.read(adminStoreListProvider.notifier).reload(),
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }

    if (list.items.isEmpty) {
      return const Center(
        child: Text('Tidak ada toko di kategori ini.', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(adminStoreListProvider.notifier).reload(),
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
                        onPressed: () => ref.read(adminStoreListProvider.notifier).loadMore(),
                        child: const Text('Muat Lebih Banyak'),
                      ),
              ),
            );
          }

          final store = list.items[index];
          return _StoreCard(
            store: store,
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => StoreDetailScreen(storeId: store.id))).then((_) {
              ref.read(adminStoreListProvider.notifier).reload();
            }),
          );
        },
      ),
    );
  }
}

class _StoreCard extends StatelessWidget {
  final AdminStoreListItem store;
  final VoidCallback onTap;

  const _StoreCard({required this.store, required this.onTap});

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
              child: const Icon(Icons.storefront_outlined, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(store.name, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    '${store.ownerName} · ${store.productCount} produk',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            _StatusBadge(status: store.status),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final AdminStoreStatus status;

  const _StatusBadge({required this.status});

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
