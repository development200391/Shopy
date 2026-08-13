import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/review/seller_review.dart';
import '../../providers/seller_review_provider.dart';
import '../../services/seller_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

const _tabs = [
  (label: 'Semua', filter: null),
  (label: 'Belum Dibalas', filter: 'belum-dibalas'),
  (label: '5 Bintang', filter: '5'),
  (label: '4 Bintang', filter: '4'),
  (label: '3 Bintang', filter: '3'),
  (label: '2 Bintang', filter: '2'),
  (label: '1 Bintang', filter: '1'),
];

/// Halaman **Ulasan Produk** — desain terpilih: **Bold & Colorful**
/// (lihat `design/assets/ulasan-seller-bold-colorful.png`).
class ReviewListScreen extends ConsumerStatefulWidget {
  const ReviewListScreen({super.key});

  @override
  ConsumerState<ReviewListScreen> createState() => _ReviewListScreenState();
}

class _ReviewListScreenState extends ConsumerState<ReviewListScreen> {
  String? _filter;

  void _refreshAll() {
    ref.invalidate(sellerReviewSummaryProvider);
    ref.invalidate(sellerReviewsProvider(_filter));
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(sellerReviewSummaryProvider);
    final reviewsAsync = ref.watch(sellerReviewsProvider(_filter));

    return Scaffold(
      appBar: AppBar(title: const Text('Ulasan Produk')),
      body: RefreshIndicator(
        onRefresh: () async => _refreshAll(),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            summaryAsync.when(
              loading: () => const Center(
                child: Padding(padding: EdgeInsets.all(AppSpacing.lg), child: CircularProgressIndicator()),
              ),
              error: (error, _) => _ErrorState(onRetry: () => ref.invalidate(sellerReviewSummaryProvider)),
              data: (summary) => _SummaryCard(summary: summary),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _tabs.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final tab = _tabs[index];
                  final active = tab.filter == _filter;
                  final label = tab.filter == 'belum-dibalas'
                      ? '${tab.label} ${summaryAsync.value?.unrepliedCount ?? ''}'.trim()
                      : tab.label;
                  return ChoiceChip(
                    label: Text(label),
                    selected: active,
                    onSelected: (_) => setState(() => _filter = tab.filter),
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(color: active ? AppColors.onPrimary : AppColors.textPrimary),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                    side: BorderSide.none,
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            reviewsAsync.when(
              loading: () => const Center(
                child: Padding(padding: EdgeInsets.all(AppSpacing.lg), child: CircularProgressIndicator()),
              ),
              error: (error, _) => _ErrorState(onRetry: () => ref.invalidate(sellerReviewsProvider(_filter))),
              data: (reviews) => reviews.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                      child: Center(child: Text('Belum ada ulasan di kategori ini.')),
                    )
                  : Column(
                      children: [for (final r in reviews) _ReviewCard(review: r, onChanged: _refreshAll)],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Gagal memuat data', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final SellerReviewSummary summary;

  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            children: [
              Text(
                summary.average.toStringAsFixed(1),
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 5; i++)
                    Icon(
                      i < summary.average.round() ? Icons.star : Icons.star_border,
                      size: 14,
                      color: Colors.amber,
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text('${summary.totalCount} ulasan', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              children: [for (final item in summary.distribution) _DistributionRow(item: item)],
            ),
          ),
        ],
      ),
    );
  }
}

class _DistributionRow extends StatelessWidget {
  final RatingDistributionItem item;

  const _DistributionRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('${item.stars}', style: const TextStyle(fontSize: 11)),
          const Icon(Icons.star, size: 10, color: Colors.amber),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: item.percent / 100,
                minHeight: 6,
                backgroundColor: AppColors.divider,
                color: Colors.amber,
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 32,
            child: Text('${item.percent}%', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends ConsumerStatefulWidget {
  final SellerReview review;
  final VoidCallback onChanged;

  const _ReviewCard({required this.review, required this.onChanged});

  @override
  ConsumerState<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends ConsumerState<_ReviewCard> {
  bool _replying = false;
  bool _submitting = false;
  final _replyController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _submitReply() async {
    if (_replyController.text.trim().isEmpty) return;

    setState(() => _submitting = true);
    try {
      await ref.read(sellerReviewApiServiceProvider).reply(widget.review.id, _replyController.text.trim());
      widget.onChanged();
    } on SellerException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '$day ${months[local.month - 1]} ${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final review = widget.review;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: review.buyerAvatarUrl == null ? null : NetworkImage(review.buyerAvatarUrl!),
                child: review.buyerAvatarUrl == null
                    ? const Icon(Icons.person_outline, color: AppColors.primary)
                    : null,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.buyerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [for (var i = 0; i < 5; i++) Icon(i < review.rating ? Icons.star : Icons.star_border, size: 14, color: Colors.amber)],
                    ),
                  ],
                ),
              ),
              Text(_formatDate(review.createdAt), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(review.productName, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(review.comment!),
          ],
          const SizedBox(height: AppSpacing.sm),
          if (review.isReplied)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.reply, size: 14, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text('Balasan Penjual', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(review.sellerReply!),
                  const SizedBox(height: 4),
                  Text(
                    'Dibalas ${_formatDate(review.sellerRepliedAt!)}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            )
          else if (_replying)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _replyController,
                  maxLines: 2,
                  decoration: const InputDecoration(hintText: 'Tulis balasan...'),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    TextButton(onPressed: () => setState(() => _replying = false), child: const Text('Batal')),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _submitting ? null : _submitReply,
                      child: _submitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                            )
                          : const Text('Kirim'),
                    ),
                  ],
                ),
              ],
            )
          else
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => setState(() => _replying = true),
                  icon: const Icon(Icons.reply, size: 16),
                  label: const Text('Balas Ulasan'),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                  child: const Text('Belum dibalas', style: TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
