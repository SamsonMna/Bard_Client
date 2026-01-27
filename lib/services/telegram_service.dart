import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../models/telegram_message.dart';

class TelegramService {
  final String botToken;
  final Dio _dio = Dio();
  int _lastUpdateId = 0;

  TelegramService({required this.botToken});

  String get _baseUrl => 'https://api.telegram.org/bot$botToken';

  Future<List<TelegramMessage>> getChannelUpdates(
      String channelUsername) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/getUpdates?offset=${_lastUpdateId + 1}&timeout=30'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ok'] == true) {
          final updates = data['result'] as List;
          final messages = <TelegramMessage>[];

          for (var update in updates) {
            _lastUpdateId = update['update_id'];

            if (update['channel_post'] != null) {
              final message = TelegramMessage.fromJson(update['channel_post']);
              messages.add(message);
            }
          }

          return messages;
        }
      }
      return [];
    } catch (e) {
      print('Error getting Telegram updates: $e');
      return [];
    }
  }

  Future<TelegramFile?> getFile(String fileId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/getFile?file_id=$fileId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ok'] == true) {
          return TelegramFile.fromJson(data['result']);
        }
      }
      return null;
    } catch (e) {
      print('Error getting file info: $e');
      return null;
    }
  }

  Future<String?> downloadFile(String fileId, String fileName) async {
    try {
      final fileInfo = await getFile(fileId);
      if (fileInfo == null || fileInfo.filePath == null) {
        return null;
      }

      final fileUrl =
          'https://api.telegram.org/file/bot$botToken/${fileInfo.filePath}';
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';

      await _dio.download(fileUrl, filePath);
      return filePath;
    } catch (e) {
      print('Error downloading file: $e');
      return null;
    }
  }

  Future<String?> downloadPhoto(TelegramPhoto photo) async {
    final fileName = 'photo_${photo.fileUniqueId}.jpg';
    return await downloadFile(photo.fileId, fileName);
  }

  Future<String?> downloadVideo(TelegramVideo video) async {
    final extension = video.mimeType?.split('/').last ?? 'mp4';
    final fileName = 'video_${video.fileUniqueId}.$extension';
    return await downloadFile(video.fileId, fileName);
  }

  Future<Map<String, dynamic>?> getBotInfo() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/getMe'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ok'] == true) {
          return data['result'];
        }
      }
      return null;
    } catch (e) {
      print('Error getting bot info: $e');
      return null;
    }
  }

  Future<bool> setWebhook(String url) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/setWebhook'),
        body: {'url': url},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['ok'] == true;
      }
      return false;
    } catch (e) {
      print('Error setting webhook: $e');
      return false;
    }
  }

  Future<bool> deleteWebhook() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/deleteWebhook'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['ok'] == true;
      }
      return false;
    } catch (e) {
      print('Error deleting webhook: $e');
      return false;
    }
  }

  void resetUpdateId() {
    _lastUpdateId = 0;
  }
}
