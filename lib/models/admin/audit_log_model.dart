/// System Audit Log Model for Super Admin monitoring
class AuditLogModel {
  final String id;
  final String action; // e.g. 'order_status_update', 'admin_created', 'menu_item_deleted', 'coupon_created'
  final String actorName;
  final String actorEmail;
  final String actorRole; // 'super_admin', 'admin', 'system', 'customer'
  final String targetEntity; // 'order', 'menu', 'category', 'coupon', 'admin', 'system'
  final String targetId;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  AuditLogModel({
    required this.id,
    required this.action,
    required this.actorName,
    required this.actorEmail,
    required this.actorRole,
    required this.targetEntity,
    required this.targetId,
    required this.description,
    DateTime? timestamp,
    this.metadata,
  }) : timestamp = timestamp ?? DateTime.now();

  AuditLogModel copyWith({
    String? id,
    String? action,
    String? actorName,
    String? actorEmail,
    String? actorRole,
    String? targetEntity,
    String? targetId,
    String? description,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return AuditLogModel(
      id: id ?? this.id,
      action: action ?? this.action,
      actorName: actorName ?? this.actorName,
      actorEmail: actorEmail ?? this.actorEmail,
      actorRole: actorRole ?? this.actorRole,
      targetEntity: targetEntity ?? this.targetEntity,
      targetId: targetId ?? this.targetId,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': action,
      'actorName': actorName,
      'actorEmail': actorEmail,
      'actorRole': actorRole,
      'targetEntity': targetEntity,
      'targetId': targetId,
      'description': description,
      'timestamp': timestamp.millisecondsSinceEpoch,
      if (metadata != null) 'metadata': metadata,
    };
  }

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: json['id'] ?? '',
      action: json['action'] ?? 'system_action',
      actorName: json['actorName'] ?? 'System',
      actorEmail: json['actorEmail'] ?? '',
      actorRole: json['actorRole'] ?? 'system',
      targetEntity: json['targetEntity'] ?? 'general',
      targetId: json['targetId'] ?? '',
      description: json['description'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int)
          : DateTime.now(),
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
    );
  }

  factory AuditLogModel.fromMap(Map<String, dynamic> map) =>
      AuditLogModel.fromJson(map);

  Map<String, dynamic> toMap() => toJson();
}
