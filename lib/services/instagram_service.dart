import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import '../models/instagram_post.dart';

class InstagramService {
  final String accessToken;
  final String businessAccountId;
  final Dio _dio = Dio();

  InstagramService({
    required this.accessToken,
    required this.businessAccountId,
  });

  String get _baseUrl => 'https://graph.facebook.com/v18.0';

  Future<String?> uploadMediaToPublicUrl(String localFilePath) async {
    // IMPORTANT: You need to implement this method to upload files to a public URL
    // 
    // Option 1: Use Cloudinary (recommended)
    // Uncomment the code below and add your Cloudinary credentials:
    /*
    final uploader = CloudinaryUploader(
      cloudName: 'YOUR_CLOUD_NAME',
      uploadPreset: 'YOUR_UPLOAD_PRESET',
    );
    return await uploader.uploadFile(localFilePath);
    */
    
    // Option 2: Use AWS S3, Firebase Storage, or any other CDN
    // Implement your own upload logic here
    
    // For now, this is a placeholder that returns null
    print('Warning: You need to upload $localFilePath to a public URL');
    print('Instagram API requires media to be accessible via public HTTPS URL');
    print('Please implement uploadMediaToPublicUrl() method');
    print('See SETUP_GUIDE.md for instructions');
    return null;
  }

  Future<InstagramMediaContainer?> createMediaContainer({
    required String mediaUrl,
    required MediaType mediaType,
    String? caption,
    String? thumbnailUrl,
  }) async {
    try {
      final params = {
        'access_token': accessToken,
        if (mediaType == MediaType.image) 'image_url': mediaUrl,
        if (mediaType == MediaType.video) 'video_url': mediaUrl,
        if (mediaType == MediaType.video && thumbnailUrl != null)
          'thumb_offset': '0',
        'media_type': mediaType.value,
        if (caption != null && caption.isNotEmpty) 'caption': caption,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/$businessAccountId/media'),
        body: params,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return InstagramMediaContainer.fromJson(data);
      } else {
        print('Error creating media container: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error creating media container: $e');
      return null;
    }
  }

  Future<bool> checkMediaContainerStatus(String containerId) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/$containerId?fields=status_code&access_token=$accessToken'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status_code'] == 'FINISHED';
      }
      return false;
    } catch (e) {
      print('Error checking media container status: $e');
      return false;
    }
  }

  Future<InstagramPublishResponse?> publishMediaContainer(
      String containerId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/$businessAccountId/media_publish'),
        body: {
          'creation_id': containerId,
          'access_token': accessToken,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return InstagramPublishResponse.fromJson(data);
      } else {
        print('Error publishing media: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error publishing media: $e');
      return null;
    }
  }

  Future<String?> postToInstagram({
    required String mediaUrl,
    required MediaType mediaType,
    String? caption,
    String? thumbnailUrl,
  }) async {
    try {
      // Step 1: Create media container
      final container = await createMediaContainer(
        mediaUrl: mediaUrl,
        mediaType: mediaType,
        caption: caption,
        thumbnailUrl: thumbnailUrl,
      );

      if (container == null) {
        print('Failed to create media container');
        return null;
      }

      // Step 2: Wait for media to be processed (for videos)
      if (mediaType == MediaType.video) {
        print('Waiting for video to be processed...');
        int attempts = 0;
        const maxAttempts = 30;
        while (attempts < maxAttempts) {
          await Future.delayed(const Duration(seconds: 10));
          final isReady = await checkMediaContainerStatus(container.id);
          if (isReady) {
            break;
          }
          attempts++;
        }

        if (attempts >= maxAttempts) {
          print('Video processing timeout');
          return null;
        }
      }

      // Step 3: Publish the media
      final publishResponse = await publishMediaContainer(container.id);
      if (publishResponse != null) {
        print('Successfully posted to Instagram: ${publishResponse.id}');
        return publishResponse.id;
      }

      return null;
    } catch (e) {
      print('Error posting to Instagram: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getAccountInfo() async {
    try {
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/$businessAccountId?fields=id,username,name,profile_picture_url&access_token=$accessToken'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error getting account info: $e');
      return null;
    }
  }

  Future<bool> validateAccessToken() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/me?access_token=$accessToken'),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error validating access token: $e');
      return false;
    }
  }
}
