import 'package:agenix/agenix.dart';
import 'package:flutter/widgets.dart';

class CustomDataStore extends ChangeNotifier implements DataStore {
  Map<String, List<Conversation>> conversations = {};
  Map<String, List<AgentMessage>> messages = {};

  @override
  Future<void> deleteConversation(String conversationId, {Object? metaData}) {
    throw UnimplementedError();
  }

  @override
  Future<List<Conversation>> getConversations(
    String convoId, {
    Object? metaData,
  }) {
    return Future.value(conversations[convoId] ?? []);
  }

  @override
  Future<List<AgentMessage>> getMessages(
    String conversationId, {
    Object? metaData,
  }) {
    final msgs = messages[conversationId];
    return Future.value(msgs ?? []);
  }

  @override
  Future<void> saveMessage(
    String convoId,
    AgentMessage msg, {
    Object? metaData,
  }) {
    messages[convoId] ??= [];
    messages[convoId]!.add(msg);
    notifyListeners();
    return Future.value();
  }
}
