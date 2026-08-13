import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/chat/chat_room.dart';
import '../../providers/seller_chat_provider.dart';
import '../../services/api_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'chat_room_screen.dart';

/// Halaman **Daftar Chat** — desain terpilih: **Bold & Colorful**
/// (lihat `design/assets/chat-seller-bold-colorful.png`, versi Ruang Chat).
class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(sellerChatRoomsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: roomsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Gagal memuat chat', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => ref.invalidate(sellerChatRoomsProvider),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
        data: (rooms) => rooms.isEmpty
            ? const Center(
                child: Text('Belum ada percakapan.', style: TextStyle(color: AppColors.textSecondary)),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: rooms.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) => _RoomTile(
                  room: rooms[index],
                  onTap: () async {
                    await Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: (_) => ChatRoomScreen(room: rooms[index])));
                    ref.invalidate(sellerChatRoomsProvider);
                  },
                ),
              ),
      ),
    );
  }
}

class _RoomTile extends StatelessWidget {
  final ChatRoom room;
  final VoidCallback onTap;

  const _RoomTile({required this.room, required this.onTap});

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: room.buyerAvatarUrl == null
                  ? null
                  : NetworkImage('${resolveApiBaseUrl()}${room.buyerAvatarUrl}'),
              child: room.buyerAvatarUrl == null
                  ? const Icon(Icons.person_outline, color: AppColors.primary)
                  : null,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(room.buyerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(
                    room.lastMessagePreview?.isNotEmpty == true ? room.lastMessagePreview! : 'Belum ada pesan',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: room.unreadCount > 0 ? AppColors.textPrimary : AppColors.textSecondary,
                      fontWeight: room.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_formatTime(room.lastMessageAt), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                const SizedBox(height: 4),
                if (room.unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    constraints: const BoxConstraints(minWidth: 18),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                    child: Text(
                      '${room.unreadCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
