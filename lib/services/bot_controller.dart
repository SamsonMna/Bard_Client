import 'dart:async';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bot_config.dart';
import '../models/telegram_message.dart';
import '../models/instagram_post.dart';
import 'telegram_service.dart';
import 'instagram_service.dart';

class BotController {
  final BotConfig config;
  late TelegramService _telegramService;
  late InstagramService _instagramService;
  Timer? _pollingTimer;
  bool _isRunning = false;
  final List<String> _processedMessageIds = [];
  final StreamController<BotEvent> _eventController =
      StreamController<BotEvent>.broadcast();

  BotController({required this.config}) {
    _telegramService = TelegramService(botToken: config.telegramBotToken);
    _instagramService = InstagramService(
      accessToken: config.instagramAccessToken,
      businessAccountId: config.instagramBusinessAccountId,
    );
  }

  Stream<BotEvent> get events => _eventController.stream;

  Future<bool> initialize() async {
    try {
      _addEvent(BotEvent(
        type: BotEventType.info,
        message: 'Initializing bot...',
      ));

      // Verify Telegram bot
      final botInfo = await _telegramService.getBotInfo();
      if (botInfo == null) {
        _addEvent(BotEvent(
          type: BotEventType.error,
          message: 'Failed to connect to Telegram bot',
        ));
        return false;
      }

      _addEvent(BotEvent(
        type: BotEventType.info,
        message: 'Connected to Telegram bot: ${botInfo['username']}',
      ));

      // Verify Instagram account
      final instagramValid =
          await _instagramService.validateAccessToken();
      if (!instagramValid) {
        _addEvent(BotEvent(
          type: BotEventType.error,
          message: 'Invalid Instagram access token',
        ));
        return false;
      }

      final accountInfo = await _instagramService.getAccountInfo();
      if (accountInfo != null) {
        _addEvent(BotEvent(
          type: BotEventType.info,
          message: 'Connected to Instagram account: ${accountInfo['username']}',
        ));
      }

      // Delete any existing webhook to use polling
      await _telegramService.deleteWebhook();

      _addEvent(BotEvent(
        type: BotEventType.info,
        message: 'Bot initialized successfully',
      ));

      return true;
    } catch (e) {
      _addEvent(BotEvent(
        type: BotEventType.error,
        message: 'Initialization error: $e',
      ));
      return false;
    }
  }

  void start() {
    if (_isRunning) {
      _addEvent(BotEvent(
        type: BotEventType.warning,
        message: 'Bot is already running',
      ));
      return;
    }

    _isRunning = true;
    _addEvent(BotEvent(
      type: BotEventType.info,
      message: 'Bot started. Polling every ${config.pollingIntervalSeconds} seconds',
    ));

    _pollingTimer = Timer.periodic(
      Duration(seconds: config.pollingIntervalSeconds),
      (_) => _pollAndProcess(),
    );

    // Run immediately on start
    _pollAndProcess();
  }

  void stop() {
    _pollingTimer?.cancel();
    _isRunning = false;
    _addEvent(BotEvent(
      type: BotEventType.info,
      message: 'Bot stopped',
    ));
  }

  Future<void> _pollAndProcess() async {
    try {
      _addEvent(BotEvent(
        type: BotEventType.info,
        message: 'Polling for new messages...',
      ));

      for (var channelUsername in config.telegramChannelUsernames) {
        final messages =
            await _telegramService.getChannelUpdates(channelUsername);

        for (var message in messages) {
          final messageKey = '${message.chatId}_${message.messageId}';

          if (_processedMessageIds.contains(messageKey)) {
            continue;
          }

          if (message.hasMedia()) {
            await _processMessage(message);
            _processedMessageIds.add(messageKey);

            // Keep only last 1000 processed IDs to prevent memory issues
            if (_processedMessageIds.length > 1000) {
              _processedMessageIds.removeAt(0);
            }
          }
        }
      }
    } catch (e) {
      _addEvent(BotEvent(
        type: BotEventType.error,
        message: 'Polling error: $e',
      ));
    }
  }

  Future<void> _processMessage(TelegramMessage message) async {
    try {
      _addEvent(BotEvent(
        type: BotEventType.info,
        message: 'Processing message ${message.messageId}',
      ));

      String? localFilePath;
      MediaType mediaType;

      // Download media from Telegram
      if (message.photos != null && message.photos!.isNotEmpty) {
        // Get the largest photo
        final photo = message.photos!.reduce(
            (a, b) => (a.fileSize ?? 0) > (b.fileSize ?? 0) ? a : b);
        localFilePath = await _telegramService.downloadPhoto(photo);
        mediaType = MediaType.image;
      } else if (message.video != null) {
        localFilePath = await _telegramService.downloadVideo(message.video!);
        mediaType = MediaType.video;
      } else {
        _addEvent(BotEvent(
          type: BotEventType.warning,
          message: 'Message has no supported media type',
        ));
        return;
      }

      if (localFilePath == null) {
        _addEvent(BotEvent(
          type: BotEventType.error,
          message: 'Failed to download media from Telegram',
        ));
        return;
      }

      _addEvent(BotEvent(
        type: BotEventType.info,
        message: 'Downloaded media to: $localFilePath',
      ));

      // Upload to public URL (you need to implement this)
      final publicUrl =
          await _instagramService.uploadMediaToPublicUrl(localFilePath);

      if (publicUrl == null) {
        _addEvent(BotEvent(
          type: BotEventType.error,
          message:
              'Failed to upload media to public URL. You need to implement uploadMediaToPublicUrl() in InstagramService',
        ));
        // Clean up local file
        try {
          await File(localFilePath).delete();
        } catch (_) {}
        return;
      }

      // Post to Instagram
      final caption = message.getCaption();
      final postId = await _instagramService.postToInstagram(
        mediaUrl: publicUrl,
        mediaType: mediaType,
        caption: caption,
      );

      if (postId != null) {
        _addEvent(BotEvent(
          type: BotEventType.success,
          message: 'Successfully posted to Instagram: $postId',
        ));
      } else {
        _addEvent(BotEvent(
          type: BotEventType.error,
          message: 'Failed to post to Instagram',
        ));
      }

      // Clean up local file
      try {
        await File(localFilePath).delete();
      } catch (e) {
        print('Error deleting local file: $e');
      }
    } catch (e) {
      _addEvent(BotEvent(
        type: BotEventType.error,
        message: 'Error processing message: $e',
      ));
    }
  }

  void _addEvent(BotEvent event) {
    print('[${event.type.name.toUpperCase()}] ${event.message}');
    _eventController.add(event);
  }

  bool get isRunning => _isRunning;

  void dispose() {
    stop();
    _eventController.close();
  }
}

class BotEvent {
  final BotEventType type;
  final String message;
  final DateTime timestamp;

  BotEvent({
    required this.type,
    required this.message,
  }) : timestamp = DateTime.now();
}

enum BotEventType {
  info,
  success,
  warning,
  error,
}
