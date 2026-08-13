import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/chat/chat_message.dart';
import '../../models/chat/chat_room.dart';
import '../../providers/chat_provider.dart';
import '../../services/api_client.dart';
import '../../services/chat_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/currency_formatter.dart';

/// Halaman **Ruang Chat** sisi pembeli — versi ringan (teks + gambar saja,
/// tanpa lampiran produk). Realtime cukup polling 5 detik + push FCM saat
/// background, tidak ada SignalR/WebSocket di project ini (TASKSELLER.md Fase 7).
class ChatRoomScreen extends ConsumerStatefulWidget {
  final ChatRoom room;

  const ChatRoomScreen({super.key, required this.room});

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _textController = TextEditingController();
  List<ChatMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _load(showSpinner: true);
    ref.read(chatApiServiceProvider).markRead(widget.room.id);
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _load(showSpinner: false));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _load({required bool showSpinner}) async {
    if (showSpinner) setState(() => _loading = true);
    try {
      final messages = await ref.read(chatApiServiceProvider).getMessages(widget.room.id);
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _loading = false;
      });
      unawaited(ref.read(chatApiServiceProvider).markRead(widget.room.id));
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send({String? body, String? attachmentUrl}) async {
    if ((body == null || body.trim().isEmpty) && attachmentUrl == null) return;

    setState(() => _sending = true);
    try {
      await ref.read(chatApiServiceProvider).sendMessage(widget.room.id, body: body?.trim(), attachmentUrl: attachmentUrl);
      _textController.clear();
      await _load(showSpinner: false);
    } on ChatException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    setState(() => _sending = true);
    try {
      final url = await ref.read(uploadsApiServiceProvider).uploadFile(picked.path, 'chat');
      await _send(attachmentUrl: url);
    } on ChatException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.error));
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: widget.room.storeLogoUrl == null
                  ? null
                  : NetworkImage('${resolveApiBaseUrl()}${widget.room.storeLogoUrl}'),
              child: widget.room.storeLogoUrl == null
                  ? const Icon(Icons.storefront_outlined, color: AppColors.primary, size: 18)
                  : null,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(widget.room.storeName, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? const Center(child: Text('Belum ada pesan.', style: TextStyle(color: AppColors.textSecondary)))
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) => _MessageBubble(message: _messages[index]),
                  ),
          ),
          DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _sending ? null : _pickImage,
                      icon: const Icon(Icons.image_outlined, color: AppColors.textSecondary),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: const InputDecoration(hintText: 'Tulis pesan...', border: InputBorder.none),
                        onSubmitted: (value) => _send(body: value),
                      ),
                    ),
                    IconButton.filled(
                      onPressed: _sending ? null : () => _send(body: _textController.text),
                      style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                      icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final mine = message.isMine;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        child: Column(
          crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: mine ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: mine ? null : Border.all(color: AppColors.divider),
              ),
              child: message.product != null
                  ? _ProductAttachment(product: message.product!, mine: mine)
                  : message.attachmentUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        '${resolveApiBaseUrl()}${message.attachmentUrl}',
                        width: 180,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Text(message.body ?? '', style: TextStyle(color: mine ? Colors.white : AppColors.textPrimary)),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_formatTime(message.createdAt), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                if (mine) ...[
                  const SizedBox(width: 2),
                  Icon(
                    Icons.done_all,
                    size: 14,
                    color: message.readAt != null ? AppColors.primary : AppColors.textSecondary,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductAttachment extends StatelessWidget {
  final ChatProductAttachment product;
  final bool mine;

  const _ProductAttachment({required this.product, required this.mine});

  @override
  Widget build(BuildContext context) {
    final textColor = mine ? Colors.white : AppColors.textPrimary;

    return SizedBox(
      width: 200,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 48,
              height: 48,
              child: product.imageUrl == null
                  ? Container(color: Colors.white.withValues(alpha: 0.2))
                  : Image.network('${resolveApiBaseUrl()}${product.imageUrl}', fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                Text('${formatRupiah(product.price)} - stok ${product.stock}', style: TextStyle(color: textColor, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
