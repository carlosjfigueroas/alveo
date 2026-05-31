class InstructionalVideo {
  final String id;
  final String title;
  final String? description;
  final String videoUrl;
  final String? coverUrl;
  final int orderIndex;
  final DateTime createdAt;

  InstructionalVideo({
    required this.id,
    required this.title,
    this.description,
    required this.videoUrl,
    this.coverUrl,
    required this.orderIndex,
    required this.createdAt,
  });

  factory InstructionalVideo.fromJson(Map<String, dynamic> json) {
    return InstructionalVideo(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      videoUrl: json['video_url'] ?? '',
      coverUrl: json['cover_url'],
      orderIndex: json['order_index'] ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'video_url': videoUrl,
      'cover_url': coverUrl,
      'order_index': orderIndex,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

