class BotConfig {
  final String telegramBotToken;
  final List<String> telegramChannelUsernames;
  final String instagramAccessToken;
  final String instagramBusinessAccountId;
  final int pollingIntervalSeconds;

  BotConfig({
    required this.telegramBotToken,
    required this.telegramChannelUsernames,
    required this.instagramAccessToken,
    required this.instagramBusinessAccountId,
    this.pollingIntervalSeconds = 300, // 5 minutes default
  });

  Map<String, dynamic> toJson() {
    return {
      'telegram_bot_token': telegramBotToken,
      'telegram_channel_usernames': telegramChannelUsernames,
      'instagram_access_token': instagramAccessToken,
      'instagram_business_account_id': instagramBusinessAccountId,
      'polling_interval_seconds': pollingIntervalSeconds,
    };
  }

  factory BotConfig.fromJson(Map<String, dynamic> json) {
    return BotConfig(
      telegramBotToken: json['telegram_bot_token'],
      telegramChannelUsernames:
          List<String>.from(json['telegram_channel_usernames']),
      instagramAccessToken: json['instagram_access_token'],
      instagramBusinessAccountId: json['instagram_business_account_id'],
      pollingIntervalSeconds: json['polling_interval_seconds'] ?? 300,
    );
  }
}
