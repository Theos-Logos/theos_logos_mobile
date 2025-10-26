class AudioTrack {
  final String id;
  final String title;
  final String fileName;
  final String url;
  final int order;
  final DateTime? dateAdded;
  bool isDownloaded;
  String? localPath;

  AudioTrack({
    required this.id,
    required this.title,
    required this.fileName,
    required this.url,
    required this.order,
    this.dateAdded,
    this.isDownloaded = false,
    this.localPath,
  });

  factory AudioTrack.fromJson(Map<String, dynamic> json) {
    return AudioTrack(
      id: json['id'] as String,
      title: json['title'] as String,
      fileName: json['file_name'] as String,
      url: json['url'] as String,
      order: json['order'] as int,
      dateAdded: json['date_added'] != null 
          ? DateTime.parse(json['date_added'] as String)
          : null,
      isDownloaded: json['is_downloaded'] as bool? ?? false,
      localPath: json['local_path'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'file_name': fileName,
      'url': url,
      'order': order,
      'date_added': dateAdded?.toIso8601String(),
      'is_downloaded': isDownloaded,
      'local_path': localPath,
    };
  }

  AudioTrack copyWith({
    String? id,
    String? title,
    String? fileName,
    String? url,
    int? order,
    DateTime? dateAdded,
    bool? isDownloaded,
    String? localPath,
  }) {
    return AudioTrack(
      id: id ?? this.id,
      title: title ?? this.title,
      fileName: fileName ?? this.fileName,
      url: url ?? this.url,
      order: order ?? this.order,
      dateAdded: dateAdded ?? this.dateAdded,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      localPath: localPath ?? this.localPath,
    );
  }
}
