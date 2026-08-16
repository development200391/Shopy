import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/moderation/admin_review.dart';
import '../../providers/admin_product_provider.dart';
import '../../providers/admin_review_list_state.dart';
import '../../providers/admin_review_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class ReviewSearchScreen extends ConsumerStatefulWidget {
  const ReviewSearchScreen({super.key});

  @override
  ConsumerState<ReviewSearchScreen> createState() => _ReviewSearchScreenState();
}

class _ReviewSearchScreenState extends ConsumerState<ReviewSearchScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirmTakedown(BuildContext context, WidgetRef ref, AdminReviewListItem review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Takedown Ulasan'),
        content: Text('Ulasan dari "${review.buyerName}" untuk produk "${review.productName}" akan dihapus. Lanjutkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Takedown'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(adminModerationApiServiceProvider).takedownReview(review.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ulasan berhasil di-takedown.')));
      ref.read(adminReviewListProvider.notifier).reload();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(adminReviewListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        // Lihat catatan sama di `product_search_screen.dart`.
        centerTitle: false,
        title: TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Cari produk atau pembeli...',
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
            prefixIconConstraints: BoxConstraints(minWidth: 32),
          ),
          onSubmitted: (value) => ref.read(adminReviewListProvider.notifier).setSearch(value.trim()),
        ),
      ),
      body: _ReviewListBody(list: list, onTakedown: (review) => _confirmTakedown(context, ref, review)),
    );
  }
}

class _ReviewListBody extends ConsumerWidget {
  final AdminReviewListState list;
  final void Function(AdminReviewListItem) onTakedown;

  const _ReviewListBody({required this.list, required this.onTakedown});

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
            const Text('Gagal memuat daftar ulasan', style: TextStyle(color: AppColors.textSecondary)),
            TextButton(
              onPressed: () => ref.read(adminReviewListProvider.notifier).reload(),
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }

    if (list.items.isEmpty) {
      return const Center(
        child: Text('Tidak ada ulasan ditemukan.', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(adminReviewListProvider.notifier).reload(),
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
                        onPressed: () => ref.read(adminReviewListProvider.notifier).loadMore(),
                        child: const Text('Muat Lebih Banyak'),
                      ),
              ),
            );
          }

          final review = list.items[index];
          return _ReviewCard(review: review, onTakedown: () => onTakedown(review));
        },
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final AdminReviewListItem review;
  final VoidCallback onTakedown;

  const _ReviewCard({required this.review, required this.onTakedown});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.productName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _RatingBadge(rating: review.rating),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${review.buyerName}${review.storeName != null ? ' · ${review.storeName}' : ''}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(review.comment!, maxLines: 3, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: onTakedown,
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Takedown'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  final int rating;

  const _RatingBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    final color = rating <= 2 ? AppColors.error : (rating == 3 ? AppColors.warning : AppColors.success);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: Colors.white, size: 12),
          const SizedBox(width: 2),
          Text('$rating', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
