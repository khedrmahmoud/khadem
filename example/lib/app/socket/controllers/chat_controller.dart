import 'dart:async';
import 'package:khadem/khadem.dart';

class ChatController extends SocketController {
  @override
  String get namespace => 'chat';

  @override
  void init() {
    onData<Map<String, dynamic>>('join', _onJoin);
    onData<Map<String, dynamic>>('message', _onMessage);
    onData<Map<String, dynamic>>('typing', _onTyping);
  }

  /// Handle user joining a conversation room
  Future<void> _onJoin(SocketContext context, Map<String, dynamic> data) async {
    validate({'conversation_id': 'required|string'});

    final conversationId = data['conversation_id'];
    final room = 'conversation:$conversationId';

    join(room);

    // Notify others in the room
    to(room, 'user_joined', {
      'user_id': context.client.id,
      'timestamp': DateTime.now().toIso8601String(),
    });

    emit('joined', {'room': room, 'status': 'success'});
  }

  /// Handle sending a new message
  Future<void> _onMessage(
      SocketContext context, Map<String, dynamic> data,) async {
    validate({
      'conversation_id': 'required|string',
      'content': 'required|string|min:1',
      'type': 'string',
    });

    final conversationId = data['conversation_id'];
    final content = data['content'];
    final type = data['type'] ?? 'text';
    final room = 'conversation:$conversationId';

    // (Mock) Save message to database
    final message = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'conversation_id': conversationId,
      'sender_id': context.client.id,
      'content': content,
      'type': type,
      'created_at': DateTime.now().toIso8601String(),
    };

    // 1. Broadcast 'message:new' to the room (Updates the Chat View)
    to(room, 'message:new', message);

    // 2. Broadcast 'conversation:updated' to the room (Updates the Conversation List)
    to(room, 'conversation:updated', {
      'conversation_id': conversationId,
      'last_message': {
        'content': type == 'text' ? content : 'Sent an attachment',
        'sender_id': context.client.id,
        'created_at': message['created_at'],
      },
      'unread_count_increment': 1,
    });
  }

  /// Handle typing indicators
  Future<void> _onTyping(
      SocketContext context, Map<String, dynamic> data,) async {
    final conversationId = data['conversation_id'];
    if (conversationId == null) return;

    // Broadcast to others in the room (excluding sender)
    context.client.broadcastTo(
      'conversation:$conversationId',
      'typing',
      {'user_id': context.client.id, 'is_typing': true},
    );
  }
}
