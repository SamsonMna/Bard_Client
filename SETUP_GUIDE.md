# Setup Guide: Telegram to Instagram Bot

This guide will walk you through setting up the Telegram to Instagram bot from scratch.

## Step 1: Create a Telegram Bot

1. Open Telegram and search for **@BotFather**
2. Start a chat and send `/newbot`
3. Follow the prompts:
   - Choose a name for your bot (e.g., "My Instagram Poster")
   - Choose a username (must end in 'bot', e.g., "my_instagram_poster_bot")
4. BotFather will give you a token like: `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`
5. **Save this token** - you'll need it later

## Step 2: Add Bot to Telegram Channels

1. Go to the Telegram channel you want to monitor
2. Click on the channel name to open settings
3. Click "Administrators"
4. Click "Add Administrator"
5. Search for your bot username
6. Add the bot and grant it permission to read messages
7. Repeat for all channels you want to monitor

## Step 3: Set Up Facebook Developer Account

1. Go to [Facebook Developers](https://developers.facebook.com/)
2. Click "Get Started" if you don't have an account
3. Complete the registration process
4. Verify your account (email and/or phone)

## Step 4: Create a Facebook App

1. In Facebook Developers, click "My Apps"
2. Click "Create App"
3. Choose "Business" as the app type
4. Fill in the details:
   - App Name: "Instagram Content Poster" (or your choice)
   - App Contact Email: Your email
5. Click "Create App"

## Step 5: Add Instagram Graph API

1. In your app dashboard, click "Add Product"
2. Find "Instagram" and click "Set Up"
3. This will add the Instagram Graph API to your app

## Step 6: Get Instagram Business Account

If you don't have an Instagram Business account:

1. Open Instagram app on your phone
2. Go to your profile
3. Tap the menu (three lines)
4. Tap "Settings"
5. Tap "Account"
6. Tap "Switch to Professional Account"
7. Choose "Business"
8. Complete the setup

## Step 7: Connect Instagram to Facebook Page

1. Create a Facebook Page if you don't have one:
   - Go to [facebook.com/pages/create](https://www.facebook.com/pages/create)
   - Follow the prompts
2. Connect your Instagram account to the Facebook Page:
   - Go to your Facebook Page
   - Click "Settings"
   - Click "Instagram" in the left menu
   - Click "Connect Account"
   - Log in to your Instagram account

## Step 8: Generate Access Token

1. In your Facebook App dashboard, go to "Tools" → "Graph API Explorer"
2. Select your app from the dropdown
3. Click "Generate Access Token"
4. Select the following permissions:
   - `instagram_basic`
   - `instagram_content_publish`
   - `pages_read_engagement`
   - `pages_show_list`
5. Click "Generate Access Token"
6. **Save this token** - you'll need it later

### Make the Token Long-Lived (Recommended)

Short-lived tokens expire in 1 hour. To get a long-lived token (60 days):

```bash
curl -i -X GET "https://graph.facebook.com/v18.0/oauth/access_token?grant_type=fb_exchange_token&client_id={app-id}&client_secret={app-secret}&fb_exchange_token={short-lived-token}"
```

Replace:
- `{app-id}`: Your Facebook App ID
- `{app-secret}`: Your Facebook App Secret (found in App Settings → Basic)
- `{short-lived-token}`: The token you just generated

The response will contain a `access_token` field with your long-lived token.

## Step 9: Get Instagram Business Account ID

### Method 1: Using Graph API Explorer

1. In Graph API Explorer, paste this query:
   ```
   me/accounts?fields=instagram_business_account
   ```
2. Click "Submit"
3. Find your page in the response
4. Copy the `instagram_business_account.id` value

### Method 2: Using cURL

```bash
# Get your Facebook Pages
curl -X GET "https://graph.facebook.com/v18.0/me/accounts?access_token={your-access-token}"

# Use the page ID to get Instagram Business Account ID
curl -X GET "https://graph.facebook.com/v18.0/{page-id}?fields=instagram_business_account&access_token={your-access-token}"
```

The response will look like:
```json
{
  "instagram_business_account": {
    "id": "17841405309211844"
  },
  "id": "123456789"
}
```

Copy the `instagram_business_account.id` value.

## Step 10: Set Up Media Hosting

You need a service to host media files publicly. Here are some options:

### Option A: Cloudinary (Recommended for Beginners)

1. Sign up at [cloudinary.com](https://cloudinary.com/)
2. Get your credentials from the dashboard:
   - Cloud Name
   - API Key
   - API Secret
3. Create an upload preset:
   - Go to Settings → Upload
   - Scroll to "Upload presets"
   - Click "Add upload preset"
   - Set "Signing Mode" to "Unsigned"
   - Save the preset name

4. Update `lib/services/instagram_service.dart`:

```dart
Future<String?> uploadMediaToPublicUrl(String localFilePath) async {
  try {
    final cloudName = 'YOUR_CLOUD_NAME';
    final uploadPreset = 'YOUR_UPLOAD_PRESET';
    
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

### Option B: AWS S3

1. Create an AWS account
2. Create an S3 bucket with public read access
3. Get your AWS credentials (Access Key ID and Secret Access Key)
4. Install AWS SDK: Add `aws_s3_upload: ^1.0.0` to `pubspec.yaml`
5. Implement the upload method using AWS SDK

### Option C: Firebase Storage

1. Create a Firebase project
2. Enable Firebase Storage
3. Set up security rules for public read access
4. Install Firebase: Add `firebase_storage: ^11.0.0` to `pubspec.yaml`
5. Implement the upload method using Firebase Storage

## Step 11: Configure the Bot

1. Run the Flutter app:
   ```bash
   flutter pub get
   flutter run
   ```

2. Fill in the configuration form:
   - **Telegram Bot Token**: From Step 1
   - **Telegram Channels**: Channel usernames (e.g., `@mychannel1, @mychannel2`)
   - **Instagram Access Token**: From Step 8
   - **Instagram Business Account ID**: From Step 9
   - **Polling Interval**: 300 (5 minutes) or your preference

3. Click "Initialize Bot"

4. If initialization succeeds, click "Start Bot"

## Step 12: Test the Bot

1. Post a photo or video to one of your monitored Telegram channels
2. Wait for the polling interval
3. Check the event log in the app
4. Verify the post appears on your Instagram account

## Troubleshooting

### "Failed to connect to Telegram bot"
- Verify your bot token is correct
- Check your internet connection
- Ensure the token hasn't been revoked

### "Invalid Instagram access token"
- Verify the token is correct
- Check if the token has expired
- Ensure you have the correct permissions

### "Failed to upload media to public URL"
- Implement the `uploadMediaToPublicUrl()` method
- Verify your hosting service credentials
- Check file size limits

### "Failed to post to Instagram"
- Ensure the media URL is publicly accessible via HTTPS
- Check Instagram's media requirements:
  - Images: JPG, PNG, max 8MB
  - Videos: MP4, 3-60 seconds, max 100MB
- Verify your Instagram Business Account ID is correct
- Check API rate limits (25 posts per 24 hours)

### Bot not receiving channel messages
- Ensure the bot is added as an administrator to the channel
- Verify the channel username is correct (include @)
- Check that the bot has permission to read messages

## Security Best Practices

1. **Never share your tokens publicly**
2. **Don't commit tokens to Git**:
   - Add `.env` to `.gitignore`
   - Use environment variables in production
3. **Rotate tokens regularly**
4. **Monitor API usage** in Facebook Developer dashboard
5. **Use long-lived tokens** to avoid frequent re-authentication
6. **Set up alerts** for unusual API activity

## Next Steps

- Set up automatic token refresh
- Implement error recovery and retry logic
- Add content filtering and moderation
- Set up logging and monitoring
- Consider using webhooks instead of polling for better performance

## Support

If you encounter issues:
1. Check the event log in the app for error messages
2. Review the troubleshooting section above
3. Verify all credentials are correct
4. Check API documentation:
   - [Telegram Bot API](https://core.telegram.org/bots/api)
   - [Instagram Graph API](https://developers.facebook.com/docs/instagram-api)

## Rate Limits Summary

| Service | Limit | Notes |
|---------|-------|-------|
| Telegram Bot API | ~30 messages/second | No strict limit for receiving |
| Instagram Content Publishing | 25 posts/24 hours | Per user |
| Instagram Graph API | 200 calls/hour | Per user |

Plan your polling interval accordingly to stay within limits.
