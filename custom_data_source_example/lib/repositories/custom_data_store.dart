import 'package:agenix/agenix.dart';

class CustomDataStore extends DataStore {
  final Map<String, List<AgentMessage>> _messagesByConversation = {};
  final Map<String, Conversation> _conversations = {};

  @override
  Future<void> saveMessage(String convoId, AgentMessage msg, {Object? metaData}) async {
    _messagesByConversation.putIfAbsent(convoId, () => []);
    _messagesByConversation[convoId]!.add(msg);
  }

  @override
  Future<List<AgentMessage>> getMessages(String conversationId, {Object? metaData}) async {
    return _messagesByConversation[conversationId] ?? [];
  }

  @override
  Future<void> deleteConversation(String conversationId, {Object? metaData}) async {
    _messagesByConversation.remove(conversationId);
    _conversations.remove(conversationId);
  }

  @override
  Future<List<Conversation>> getConversations(String convoId, {Object? metaData}) async {
    if (convoId.isNotEmpty) {
      final convo = _conversations[convoId];
      return convo != null ? [convo] : [];
    }
    return _conversations.values.toList();
  }

  Future<void> saveConversation(Conversation convo) async {
    _conversations[convo.conversationId] = convo;
  }
}
