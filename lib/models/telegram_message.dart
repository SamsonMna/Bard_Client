class TelegramMessage {
  final int messageId;
  final int chatId;
  final String? text;
  final String? caption;
  final DateTime date;
  final List<TelegramPhoto>? photos;
  final TelegramVideo? video;
  final TelegramDocument? document;

  TelegramMessage({
    required this.messageId,
    required this.chatId,
    this.text,
    this.caption,
    required this.date,
    this.photos,
    this.video,
    this.document,
  });

  factory TelegramMessage.fromJson(Map<String, dynamic> json) {
    return TelegramMessage(
      messageId: json['message_id'],
      chatId: json['chat']['id'],
      text: json['text'],
      caption: json['caption'],
      date: DateTime.fromMillisecondsSinceEpoch(json['date'] * 1000),
      photos: json['photo'] != null
          ? (json['photo'] as List)
              .map((p) => TelegramPhoto.fromJson(p))
              .toList()
          : null,
      video: json['video'] != null ? TelegramVideo.fromJson(json['video']) : null,
      document: json['document'] != null
          ? TelegramDocument.fromJson(json['document'])
          : null,
    );
  }

  bool hasMedia() {
    return photos != null || video != null || document != null;
  }

  String? getCaption() {
    return caption ?? text;
  }
}

class TelegramPhoto {
  final String fileId;
  final String fileUniqueId;
  final int width;
  final int height;
  final int? fileSize;

  TelegramPhoto({
    required this.fileId,
    required this.fileUniqueId,
    required this.width,
    required this.height,
    this.fileSize,
  });

  factory TelegramPhoto.fromJson(Map<String, dynamic> json) {
    return TelegramPhoto(
      fileId: json['file_id'],
      fileUniqueId: json['file_unique_id'],
      width: json['width'],
      height: json['height'],
      fileSize: json['file_size'],
    );
  }
}

class TelegramVideo {
  final String fileId;
  final String fileUniqueId;
  final int width;
  final int height;
  final int duration;
  final String? mimeType;
  final int? fileSize;

  TelegramVideo({
    required this.fileId,
    required this.fileUniqueId,
    required this.width,
    required this.height,
    required this.duration,
    this.mimeType,
    this.fileSize,
  });

  factory TelegramVideo.fromJson(Map<String, dynamic> json) {
    return TelegramVideo(
      fileId: json['file_id'],
      fileUniqueId: json['file_unique_id'],
      width: json['width'],
      height: json['height'],
      duration: json['duration'],
      mimeType: json['mime_type'],
      fileSize: json['file_size'],
    );
  }
}

class TelegramDocument {
  final String fileId;
  final String fileUniqueId;
  final String? fileName;
  final String? mimeType;
  final int? fileSize;

  TelegramDocument({
    required this.fileId,
    required this.fileUniqueId,
    this.fileName,
    this.mimeType,
    this.fileSize,
  });

  factory TelegramDocument.fromJson(Map<String, dynamic> json) {
    return TelegramDocument(
      fileId: json['file_id'],
      fileUniqueId: json['file_unique_id'],
      fileName: json['file_name'],
      mimeType: json['mime_type'],
      fileSize: json['file_size'],
    );
  }
}

class TelegramFile {
  final String fileId;
  final String? filePath;
  final int? fileSize;

  TelegramFile({
    required this.fileId,
    this.filePath,
    this.fileSize,
  });

  factory TelegramFile.fromJson(Map<String, dynamic> json) {
    return TelegramFile(
      fileId: json['file_id'],
      filePath: json['file_path'],
      fileSize: json['file_size'],
    );
  }
}
