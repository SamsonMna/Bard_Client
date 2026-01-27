# Quick Start Guide

Get your Telegram to Instagram bot running in 10 minutes!

## Prerequisites

- Flutter SDK installed (3.0.3+)
- Telegram account
- Instagram Business account
- Facebook Developer account

## Step 1: Get Your Credentials (5 minutes)

### Telegram Bot Token
1. Message [@BotFather](https://t.me/botfather) on Telegram
2. Send `/newbot` and follow instructions
3. Copy the token (looks like: `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`)
4. Add your bot as admin to your Telegram channel

### Instagram Access Token
1. Go to [Facebook Developers](https://developers.facebook.com/)
2. Create an app and add Instagram product
3. Generate a User Access Token with these permissions:
   - `instagram_basic`
   - `instagram_content_publish`
   - `pages_read_engagement`
4. Get your Instagram Business Account ID:
   ```bash
   curl "https://graph.facebook.com/v18.0/me/accounts?fields=instagram_business_account&access_token=YOUR_TOKEN"
   ```

### Cloudinary Account (for media hosting)
1. Sign up at [cloudinary.com](https://cloudinary.com/) (free tier is fine)
2. Get your Cloud Name from the dashboard
3. Create an unsigned upload preset:
   - Settings → Upload → Add upload preset
   - Set "Signing Mode" to "Unsigned"
   - Copy the preset name

## Step 2: Configure Media Upload (2 minutes)

Edit `lib/services/instagram_service.dart` and update the `uploadMediaToPublicUrl()` method:

```dart
Future<String?> uploadMediaToPublicUrl(String localFilePath) async {
  final uploader = CloudinaryUploader(
    cloudName: 'YOUR_CLOUD_NAME',      // Replace with your cloud name
    uploadPreset: 'YOUR_UPLOAD_PRESET', // Replace with your preset name
  );
  return await uploader.uploadFile(localFilePath);
}
```

Don't forget to uncomment the import at the top:
```dart
import 'cloudinary_uploader.dart';
```

## Step 3: Install and Run (3 minutes)

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run
```

## Step 4: Configure the Bot

In the app:

1. **Telegram Bot Token**: Paste your bot token
2. **Telegram Channels**: Enter channel usernames (e.g., `@mychannel`)
3. **Instagram Access Token**: Paste your Instagram token
4. **Instagram Business Account ID**: Paste your account ID
5. **Polling Interval**: Leave as 300 (5 minutes)

Click **Initialize Bot**, then **Start Bot**

## Step 5: Test It!

1. Post a photo or video to your Telegram channel
2. Wait up to 5 minutes (or your polling interval)
3. Check your Instagram account - the post should appear!
4. Watch the event log in the app for real-time updates

## Troubleshooting

### "Failed to connect to Telegram bot"
- Double-check your bot token
- Make sure you copied the entire token

### "Invalid Instagram access token"
- Verify the token hasn't expired
- Check you have the correct permissions

### "Failed to upload media to public URL"
- Make sure you updated the Cloudinary credentials
- Verify your Cloud Name and Upload Preset are correct

### Bot not receiving messages
- Ensure your bot is added as an admin to the channel
- Include the @ symbol in channel username

### "Failed to post to Instagram"
- Check that your media URL is publicly accessible
- Verify your Instagram Business Account ID is correct
- Make sure you haven't exceeded the 25 posts/day limit

## What's Next?

- Read [SETUP_GUIDE.md](SETUP_GUIDE.md) for detailed setup instructions
- Check [IMPLEMENTATION_NOTES.md](IMPLEMENTATION_NOTES.md) for technical details
- Review [README.md](README.md) for full documentation

## Rate Limits to Remember

- **Instagram**: 25 posts per 24 hours
- **Polling**: Recommended minimum 300 seconds (5 minutes)
- **API Calls**: 200 per hour per user

## Need Help?

1. Check the event log in the app for error messages
2. Review the troubleshooting section above
3. Read the full documentation in README.md
4. Check API documentation:
   - [Telegram Bot API](https://core.telegram.org/bots/api)
   - [Instagram Graph API](https://developers.facebook.com/docs/instagram-api)

## Security Reminder

⚠️ **Never commit your tokens to Git!**

- Keep your tokens private
- Don't share screenshots with tokens visible
- Rotate tokens regularly
- Use environment variables in production

---

**That's it!** Your bot should now be automatically posting from Telegram to Instagram. 🎉
