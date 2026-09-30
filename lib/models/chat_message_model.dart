import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/safe_convert.dart';

/// Represents a single message bubble inside a chat channel.
class ChatMessageModel {
  final String id;
  final String senderId;
  final String senderRole; // 'customer' | 'admin' | 'super_admin'
  final String senderName;
  final String text;
  final String type; // 'text' | 'image' | 'system'
  final String? imageUrl;
  final DateTime createdAt;
  final List<String> readBy;

  ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.senderName,
    required this.text,
    this.type = 'text',
    this.imageUrl,
    DateTime? createdAt,
    List<String>? readBy,
  })  : createdAt = createdAt ?? DateTime.now(),
        readBy = readBy ?? [senderId];

  bool get isCustomer => senderRole == 'customer';
  bool get isAdmin => senderRole == 'admin' || senderRole == 'super_admin';
  bool get isSystem => type == 'system';
  bool get isImage => type == 'image';
  bool isReadBy(String uid) => readBy.contains(uid);

  ChatMessageModel copyWith({
    String? id,
    String? senderId,
    String? senderRole,
    String? senderName,
    String? text,
    String? type,
    String? imageUrl,
    DateTime? createdAt,
    List<String>? readBy,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderRole: senderRole ?? this.senderRole,
      senderName: senderName ?? this.senderName,
      text: text ?? this.text,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      readBy: readBy ?? this.readBy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderRole': senderRole,
      'senderName': senderName,
      'text': text,
      'type': type,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'readBy': readBy,
    };
  }

  Map<String, dynamic> toMap() => toJson();

  factory ChatMessageModel.fromMap(Map<String, dynamic> map, [String? id]) =>
      ChatMessageModel.fromJson(map, id);

  factory ChatMessageModel.fromJson(Map<String, dynamic> json, [String? docId]) {
    List<String> readByList = [];
    if (json['readBy'] is List) {
      readByList = (json['readBy'] as List).map((e) => e.toString()).toList();
    }

    return ChatMessageModel(
      id: docId ?? json['id']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      senderRole: json['senderRole']?.toString() ?? 'customer',
      senderName: json['senderName']?.toString() ?? 'User',
      text: json['text']?.toString() ?? '',
      type: json['type']?.toString() ?? 'text',
      imageUrl: json['imageUrl']?.toString(),
      createdAt: SafeConvert.toDateTime(json['createdAt']),
      readBy: readByList,
    );
  }
}
