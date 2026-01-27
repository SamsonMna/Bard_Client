import 'dart:io';
import 'package:dio/dio.dart';

class CloudinaryUploader {
  final String cloudName;
  final String uploadPreset;
  final Dio _dio = Dio();

  CloudinaryUploader({
    required this.cloudName,
    required this.uploadPreset,
  });

  Future<String?> uploadFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        print('File does not exist: $filePath');
        return null;
      }

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: file.path.split('/').last,
        ),
        'upload_preset': uploadPreset,
      });

      final response = await _dio.post(
        'https://api.cloudinary.com/v1_1/$cloudName/auto/upload',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200) {
        final secureUrl = response.data['secure_url'];
        print('File uploaded successfully: $secureUrl');
        return secureUrl;
      } else {
        print('Upload failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error uploading file to Cloudinary: $e');
      return null;
    }
  }

  Future<String?> uploadImage(String imagePath) async {
    return await uploadFile(imagePath);
  }

  Future<String?> uploadVideo(String videoPath) async {
    return await uploadFile(videoPath);
  }
}
