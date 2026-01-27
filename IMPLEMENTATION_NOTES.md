# Implementation Notes

## Project Overview

This Flutter application provides a complete solution for automatically posting content from Telegram channels to Instagram. The bot monitors specified Telegram channels, downloads media (photos and videos), and posts them to Instagram with their original captions.

## Architecture

### Models (`lib/models/`)

1. **telegram_message.dart**
   - `TelegramMessage`: Main message model with support for text, photos, videos, and documents
   - `TelegramPhoto`: Photo metadata including file ID, dimensions, and size
   - `TelegramVideo`: Video metadata including duration, dimensions, and MIME type
   - `TelegramDocument`: Document metadata
   - `TelegramFile`: File information from Telegram API

2. **instagram_post.dart**
   - `InstagramPost`: Post data model with caption, media URL, and type
   - `MediaType`: Enum for IMAGE, VIDEO, and CAROUSEL_ALBUM
   - `InstagramMediaContainer`: Container ID and status from Instagram API
   - `InstagramPublishResponse`: Response after publishing to Instagram

3. **bot_config.dart**
   - `BotConfig`: Configuration model storing all bot credentials and settings
   - Supports JSON serialization for persistence

### Services (`lib/services/`)

1. **telegram_service.dart**
   - Handles all Telegram Bot API interactions
   - Methods:
     - `getChannelUpdates()`: Polls for new channel messages
     - `getFile()`: Gets file information from Telegram
     - `downloadFile()`: Downloads media files
     - `downloadPhoto()`: Specialized photo download
     - `downloadVideo()`: Specialized video download
     - `getBotInfo()`: Validates bot token
     - `setWebhook()` / `deleteWebhook()`: Webhook management

2. **instagram_service.dart**
   - Handles all Instagram Graph API interactions
   - Methods:
     - `createMediaContainer()`: Creates a media container for posting
     - `checkMediaContainerStatus()`: Checks if video processing is complete
     - `publishMediaContainer()`: Publishes the media to Instagram
     - `postToInstagram()`: Complete posting workflow
     - `getAccountInfo()`: Gets Instagram account information
     - `validateAccessToken()`: Validates the access token
     - `uploadMediaToPublicUrl()`: **MUST BE IMPLEMENTED** - uploads media to public URL

3. **bot_controller.dart**
   - Orchestrates the entire bot workflow
   - Features:
     - Automatic polling with configurable interval
     - Event streaming for real-time updates
     - Message deduplication
     - Error handling and recovery
     - Start/stop controls
   - Methods:
     - `initialize()`: Validates credentials and sets up services
     - `start()`: Begins polling for messages
     - `stop()`: Stops the bot
     - `_pollAndProcess()`: Main polling loop
     - `_processMessage()`: Processes individual messages

4. **cloudinary_uploader.dart**
   - Example implementation for uploading media to Cloudinary
   - Can be adapted for other CDN services
   - Methods:
     - `uploadFile()`: Generic file upload
     - `uploadImage()`: Image-specific upload
     - `uploadVideo()`: Video-specific upload

### UI (`lib/main.dart`)

- **BotHomePage**: Main application interface
- Features:
  - Configuration form for all bot settings
  - Bot initialization and validation
  - Start/Stop controls
  - Real-time event log with color-coded messages
  - Status indicator

## Workflow

1. **Initialization**
   ```
   User enters credentials → Bot validates Telegram token → 
   Bot validates Instagram token → Bot ready
   ```

2. **Polling Loop**
   ```
   Timer triggers → Poll Telegram channels → 
   Check for new messages → Filter media messages → 
   Process each message
   ```

3. **Message Processing**
   ```
   Download media from Telegram → Upload to public URL → 
   Create Instagram media container → Wait for processing (videos) → 
   Publish to Instagram → Clean up local files
   ```

## Critical Implementation Requirements

### 1. Media Upload to Public URL

**MUST IMPLEMENT**: The `uploadMediaToPublicUrl()` method in `instagram_service.dart`

Instagram requires media to be accessible via public HTTPS URLs. You have several options:

#### Option A: Cloudinary (Easiest)
```dart
// In instagram_service.dart
import 'cloudinary_uploader.dart';

Future<String?> uploadMediaToPublicUrl(String localFilePath) async {
  final uploader = CloudinaryUploader(
    cloudName: 'YOUR_CLOUD_NAME',
    uploadPreset: 'YOUR_UPLOAD_PRESET',
  );
  return await uploader.uploadFile(localFilePath);
}
```

#### Option B: AWS S3
1. Add dependency: `aws_s3_upload: ^1.0.0`
2. Configure S3 bucket with public read access
3. Implement upload using AWS SDK

#### Option C: Firebase Storage
1. Add dependency: `firebase_storage: ^11.0.0`
2. Configure Firebase project
3. Set storage rules for public read
4. Implement upload using Firebase SDK

### 2. Environment Variables (Production)

For production deployment, use environment variables instead of hardcoding credentials:

1. Add `flutter_dotenv: ^5.1.0` to `pubspec.yaml`
2. Create `.env` file (copy from `.env.example`)
3. Load environment variables in `main.dart`:
   ```dart
   import 'package:flutter_dotenv/flutter_dotenv.dart';
   
   Future<void> main() async {
     await dotenv.load(fileName: ".env");
     runApp(const MyApp());
   }
   ```

### 3. Persistent Storage

Currently, configuration is entered each time. To persist configuration:

1. Use `shared_preferences` (already added):
   ```dart
   final prefs = await SharedPreferences.getInstance();
   await prefs.setString('bot_config', jsonEncode(config.toJson()));
   ```

2. Load on app start:
   ```dart
   final configJson = prefs.getString('bot_config');
   if (configJson != null) {
     final config = BotConfig.fromJson(jsonDecode(configJson));
   }
   ```

## API Requirements

### Telegram Bot API

- **Base URL**: `https://api.telegram.org/bot{token}/`
- **Methods Used**:
  - `getUpdates`: Long polling for new messages
  - `getFile`: Get file information
  - `getMe`: Validate bot token
  - `setWebhook` / `deleteWebhook`: Webhook management

### Instagram Graph API

- **Base URL**: `https://graph.facebook.com/v18.0/`
- **Endpoints Used**:
  - `POST /{ig-user-id}/media`: Create media container
  - `GET /{ig-container-id}`: Check container status
  - `POST /{ig-user-id}/media_publish`: Publish media
  - `GET /{ig-user-id}`: Get account info

- **Required Permissions**:
  - `instagram_basic`
  - `instagram_content_publish`
  - `pages_read_engagement`

## Rate Limits

### Telegram
- No strict rate limits for receiving messages
- Recommended: < 30 messages/second for sending

### Instagram
- **Content Publishing**: 25 posts per 24 hours per user
- **API Calls**: 200 calls per hour per user
- **Media Processing**: Videos can take 30-60 seconds to process

**Recommendation**: Set polling interval to at least 300 seconds (5 minutes) to stay within limits.

## Error Handling

The bot includes comprehensive error handling:

1. **Network Errors**: Caught and logged, bot continues running
2. **API Errors**: Logged with details, message skipped
3. **File Errors**: Cleanup attempted even on failure
4. **Token Errors**: Bot stops and notifies user

## Security Considerations

1. **Token Storage**: Never commit tokens to version control
2. **Access Control**: Tokens should be stored securely
3. **HTTPS Only**: All API calls use HTTPS
4. **Token Rotation**: Implement regular token refresh
5. **Rate Limiting**: Built-in to prevent API abuse

## Testing Checklist

- [ ] Telegram bot token is valid
- [ ] Bot is added as admin to Telegram channels
- [ ] Instagram access token is valid and has correct permissions
- [ ] Instagram Business Account ID is correct
- [ ] Media upload to public URL is implemented
- [ ] Public URLs are accessible via HTTPS
- [ ] Bot can download photos from Telegram
- [ ] Bot can download videos from Telegram
- [ ] Bot can post photos to Instagram
- [ ] Bot can post videos to Instagram
- [ ] Captions are preserved
- [ ] Local files are cleaned up after posting
- [ ] Bot handles errors gracefully
- [ ] Event log shows all activities

## Known Limitations

1. **Media Upload**: Requires implementation of public URL upload
2. **Carousel Posts**: Not currently supported (single media only)
3. **Stories**: Not supported (feed posts only)
4. **Reels**: Not supported (feed posts only)
5. **Hashtag Parsing**: No special handling for hashtags
6. **Mention Parsing**: No special handling for mentions
7. **Scheduled Posts**: Not supported (immediate posting only)
8. **Content Moderation**: No built-in filtering

## Future Enhancements

1. **Webhook Support**: Replace polling with webhooks for real-time updates
2. **Database Integration**: Store message history and posting status
3. **Content Filtering**: Add keyword filtering and content moderation
4. **Scheduled Posting**: Queue posts for specific times
5. **Multi-Account**: Support multiple Instagram accounts
6. **Analytics**: Track posting success rate and engagement
7. **Carousel Support**: Post multiple images as carousel
8. **Caption Templates**: Custom caption formatting
9. **Retry Logic**: Automatic retry on temporary failures
10. **Token Refresh**: Automatic access token renewal

## Troubleshooting

### Bot not receiving messages
- Check bot is admin in channel
- Verify channel username is correct
- Ensure bot token is valid

### Instagram posting fails
- Verify access token is valid
- Check media URL is publicly accessible
- Ensure media meets Instagram requirements
- Check rate limits

### Media upload fails
- Implement `uploadMediaToPublicUrl()` method
- Verify hosting service credentials
- Check file size limits

### App crashes
- Check Flutter version compatibility
- Verify all dependencies are installed
- Review error logs

## Development Setup

1. Install Flutter SDK (3.0.3 or higher)
2. Clone repository
3. Run `flutter pub get`
4. Configure credentials
5. Run `flutter run`

## Production Deployment

1. Implement media upload to public URL
2. Set up environment variables
3. Configure persistent storage
4. Set up error monitoring
5. Configure logging
6. Test thoroughly
7. Deploy to target platform

## Support Resources

- [Telegram Bot API Documentation](https://core.telegram.org/bots/api)
- [Instagram Graph API Documentation](https://developers.facebook.com/docs/instagram-api)
- [Flutter Documentation](https://docs.flutter.dev/)
- [Cloudinary Documentation](https://cloudinary.com/documentation)
