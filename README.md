# Telegram to Instagram Bot

A Flutter application that automatically posts content (photos and videos with captions) from pre-selected Telegram channels to Instagram using the Telegram Bot API and Instagram Graph API.

## Features

- 📱 Monitor multiple Telegram channels simultaneously
- 📸 Automatically download photos and videos from Telegram
- 🚀 Post content to Instagram with captions
- ⏱️ Configurable polling interval
- 📊 Real-time event logging and status monitoring
- 🎨 Clean and intuitive UI for bot configuration and control

## Prerequisites

Before you begin, ensure you have the following:

### 1. Telegram Bot Token
1. Open Telegram and search for [@BotFather](https://t.me/botfather)
2. Send `/newbot` and follow the instructions
3. Copy the bot token (format: `123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11`)
4. Add your bot to the Telegram channels you want to monitor as an administrator

### 2. Instagram Business Account
1. You need an Instagram Business or Creator account
2. The account must be connected to a Facebook Page
3. You need a Facebook Developer account

### 3. Instagram Graph API Access Token
1. Go to [Facebook Developers](https://developers.facebook.com/)
2. Create a new app or use an existing one
3. Add the Instagram Graph API product
4. Generate a User Access Token with the following permissions:
   - `instagram_basic`
   - `instagram_content_publish`
   - `pages_read_engagement`
5. Get your Instagram Business Account ID:
   ```
   GET https://graph.facebook.com/v18.0/me/accounts?access_token={your-access-token}
   ```
   Then use the page ID to get the Instagram Business Account ID:
   ```
   GET https://graph.facebook.com/v18.0/{page-id}?fields=instagram_business_account&access_token={your-access-token}
   ```

### 4. Public Media Hosting
Instagram requires media files to be accessible via public HTTPS URLs. You'll need to implement one of these solutions:

- **AWS S3** with public bucket
- **Cloudinary** (recommended for ease of use)
- **Google Cloud Storage**
- **Azure Blob Storage**
- Any other CDN or file hosting service with public HTTPS access

## Installation

1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd bard_client
   ```

2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

3. Run the application:
   ```bash
   flutter run
   ```

## Configuration

### Using the UI

1. Launch the application
2. Fill in the configuration form:
   - **Telegram Bot Token**: Your bot token from BotFather
   - **Telegram Channels**: Comma-separated list of channel usernames (e.g., `@channel1, @channel2`)
   - **Instagram Access Token**: Your Instagram Graph API access token
   - **Instagram Business Account ID**: Your Instagram Business Account ID
   - **Polling Interval**: How often to check for new messages (in seconds, default: 300)
3. Click "Initialize Bot"
4. Once initialized, click "Start Bot" to begin monitoring

## Important Implementation Notes

### Media Upload to Public URL

The current implementation includes a placeholder for uploading media to a public URL. You **MUST** implement the `uploadMediaToPublicUrl()` method in `lib/services/instagram_service.dart`.

Example implementation using Cloudinary:

```dart
Future<String?> uploadMediaToPublicUrl(String localFilePath) async {
  try {
    final cloudName = 'your_cloud_name';
    final uploadPreset = 'your_upload_preset';
    
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(localFilePath),
      'upload_preset': uploadPreset,
    });
    
    final response = await _dio.post(
      'https://api.cloudinary.com/v1_1/$cloudName/auto/upload',
      data: formData,
    );
    
    if (response.statusCode == 200) {
      return response.data['secure_url'];
    }
    return null;
  } catch (e) {
    print('Error uploading to Cloudinary: $e');
    return null;
  }
}
```

## How It Works

1. **Polling**: The bot polls Telegram channels at the configured interval
2. **Message Detection**: When a new message with media (photo/video) is detected
3. **Download**: The media is downloaded from Telegram to local storage
4. **Upload**: The media is uploaded to a public URL (you must implement this)
5. **Post to Instagram**: The media is posted to Instagram using the Graph API
6. **Cleanup**: Local files are deleted after successful posting

## Project Structure

```
lib/
├── models/
│   ├── bot_config.dart           # Bot configuration model
│   ├── instagram_post.dart       # Instagram post models
│   └── telegram_message.dart     # Telegram message models
├── services/
│   ├── bot_controller.dart       # Main bot orchestration logic
│   ├── instagram_service.dart    # Instagram Graph API integration
│   └── telegram_service.dart     # Telegram Bot API integration
└── main.dart                     # UI and application entry point
```

## API Rate Limits

### Telegram Bot API
- No strict rate limits for bot API
- Recommended: Don't send more than 30 messages per second

### Instagram Graph API
- Content Publishing: 25 API calls per 24 hours per user
- Rate limit: 200 calls per hour per user
- Plan your polling interval accordingly

## Troubleshooting

### Bot not receiving messages
- Ensure your bot is added as an administrator to the Telegram channel
- Check that the channel username is correct (include the @ symbol)
- Verify your bot token is valid

### Instagram posting fails
- Verify your access token is valid and has the correct permissions
- Ensure the media URL is publicly accessible via HTTPS
- Check that the Instagram Business Account ID is correct
- For videos, ensure they meet Instagram's requirements:
  - Duration: 3-60 seconds
  - Aspect ratio: 4:5 to 16:9
  - File size: < 100 MB

### Media upload issues
- Implement the `uploadMediaToPublicUrl()` method
- Ensure your hosting service supports HTTPS
- Check file size limits on your hosting service

## Security Considerations

- **Never commit API tokens** to version control
- Store sensitive credentials securely
- Use environment variables for production deployments
- Regularly rotate access tokens
- Monitor API usage to detect unauthorized access

## Future Enhancements

- [ ] Support for carousel posts (multiple images)
- [ ] Scheduled posting
- [ ] Content filtering and moderation
- [ ] Analytics and reporting
- [ ] Webhook support instead of polling
- [ ] Database integration for message tracking
- [ ] Multi-account support
- [ ] Custom caption templates

## License

This project is provided as-is for educational and personal use.

## Disclaimer

This bot is for personal use only. Ensure you comply with:
- Telegram's Terms of Service
- Instagram's Terms of Service
- Facebook Platform Terms
- Copyright laws when reposting content

Always obtain proper permissions before reposting content from Telegram channels to Instagram.
