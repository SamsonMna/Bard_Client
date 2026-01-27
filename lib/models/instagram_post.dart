class InstagramPost {
  final String? caption;
  final String mediaUrl;
  final MediaType mediaType;
  final String? thumbnailUrl;

  InstagramPost({
    this.caption,
    required this.mediaUrl,
    required this.mediaType,
    this.thumbnailUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'caption': caption,
      'media_url': mediaUrl,
      'media_type': mediaType.value,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
    };
  }
}

enum MediaType {
  image('IMAGE'),
  video('VIDEO'),
  carouselAlbum('CAROUSEL_ALBUM');

  final String value;
  const MediaType(this.value);
}

class InstagramMediaContainer {
  final String id;
  final String status;

  InstagramMediaContainer({
    required this.id,
    required this.status,
  });

  factory InstagramMediaContainer.fromJson(Map<String, dynamic> json) {
    return InstagramMediaContainer(
      id: json['id'],
      status: json['status'] ?? 'FINISHED',
    );
  }
}

class InstagramPublishResponse {
  final String id;

  InstagramPublishResponse({required this.id});

  factory InstagramPublishResponse.fromJson(Map<String, dynamic> json) {
    return InstagramPublishResponse(id: json['id']);
  }
}
