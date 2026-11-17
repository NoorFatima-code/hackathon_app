class TeamChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime sentAt;

  const TeamChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.sentAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'senderId': senderId,
    'senderName': senderName,
    'text': text,
    'sentAt': sentAt.toIso8601String(),
  };

  factory TeamChatMessage.fromJson(Map<String, dynamic> json) =>
      TeamChatMessage(
        id: json['id'] as String,
        senderId: json['senderId'] as String,
        senderName: json['senderName'] as String,
        text: json['text'] as String,
        sentAt: DateTime.parse(json['sentAt'] as String),
      );
}
