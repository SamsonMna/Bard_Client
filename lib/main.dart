import 'package:flutter/material.dart';
import 'models/bot_config.dart';
import 'services/bot_controller.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Telegram to Instagram Bot',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const BotHomePage(),
    );
  }
}

class BotHomePage extends StatefulWidget {
  const BotHomePage({super.key});

  @override
  State<BotHomePage> createState() => _BotHomePageState();
}

class _BotHomePageState extends State<BotHomePage> {
  final _formKey = GlobalKey<FormState>();
  final _telegramBotTokenController = TextEditingController();
  final _telegramChannelsController = TextEditingController();
  final _instagramAccessTokenController = TextEditingController();
  final _instagramBusinessIdController = TextEditingController();
  final _pollingIntervalController = TextEditingController(text: '300');

  BotController? _botController;
  final List<BotEvent> _events = [];
  bool _isConfigured = false;

  @override
  void dispose() {
    _telegramBotTokenController.dispose();
    _telegramChannelsController.dispose();
    _instagramAccessTokenController.dispose();
    _instagramBusinessIdController.dispose();
    _pollingIntervalController.dispose();
    _botController?.dispose();
    super.dispose();
  }

  Future<void> _initializeBot() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final channels = _telegramChannelsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final config = BotConfig(
      telegramBotToken: _telegramBotTokenController.text.trim(),
      telegramChannelUsernames: channels,
      instagramAccessToken: _instagramAccessTokenController.text.trim(),
      instagramBusinessAccountId: _instagramBusinessIdController.text.trim(),
      pollingIntervalSeconds: int.parse(_pollingIntervalController.text),
    );

    setState(() {
      _events.clear();
      _botController?.dispose();
      _botController = BotController(config: config);
    });

    _botController!.events.listen((event) {
      setState(() {
        _events.insert(0, event);
        if (_events.length > 100) {
          _events.removeLast();
        }
      });
    });

    final success = await _botController!.initialize();
    if (success) {
      setState(() {
        _isConfigured = true;
      });
    }
  }

  void _startBot() {
    _botController?.start();
    setState(() {});
  }

  void _stopBot() {
    _botController?.stop();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Telegram to Instagram Bot'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Bot Configuration',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _telegramBotTokenController,
                        decoration: const InputDecoration(
                          labelText: 'Telegram Bot Token',
                          hintText: '123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter Telegram bot token';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _telegramChannelsController,
                        decoration: const InputDecoration(
                          labelText: 'Telegram Channels (comma-separated)',
                          hintText: '@channel1, @channel2',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter at least one channel';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _instagramAccessTokenController,
                        decoration: const InputDecoration(
                          labelText: 'Instagram Access Token',
                          hintText: 'Your Instagram Graph API access token',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter Instagram access token';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _instagramBusinessIdController,
                        decoration: const InputDecoration(
                          labelText: 'Instagram Business Account ID',
                          hintText: '1234567890',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter Instagram business account ID';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _pollingIntervalController,
                        decoration: const InputDecoration(
                          labelText: 'Polling Interval (seconds)',
                          hintText: '300',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter polling interval';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _initializeBot,
                        child: const Text('Initialize Bot'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_isConfigured) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Bot Control',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _botController?.isRunning == true
                                  ? null
                                  : _startBot,
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Start Bot'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _botController?.isRunning == false
                                  ? null
                                  : _stopBot,
                              icon: const Icon(Icons.stop),
                              label: const Text('Stop Bot'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Status: ${_botController?.isRunning == true ? "Running" : "Stopped"}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _botController?.isRunning == true
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Event Log',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _events.clear();
                              });
                            },
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 300,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: _events.isEmpty
                            ? const Center(
                                child: Text('No events yet'),
                              )
                            : ListView.builder(
                                itemCount: _events.length,
                                itemBuilder: (context, index) {
                                  final event = _events[index];
                                  return ListTile(
                                    dense: true,
                                    leading: Icon(
                                      _getEventIcon(event.type),
                                      color: _getEventColor(event.type),
                                      size: 20,
                                    ),
                                    title: Text(
                                      event.message,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    subtitle: Text(
                                      DateFormat('HH:mm:ss')
                                          .format(event.timestamp),
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getEventIcon(BotEventType type) {
    switch (type) {
      case BotEventType.info:
        return Icons.info_outline;
      case BotEventType.success:
        return Icons.check_circle_outline;
      case BotEventType.warning:
        return Icons.warning_amber;
      case BotEventType.error:
        return Icons.error_outline;
    }
  }

  Color _getEventColor(BotEventType type) {
    switch (type) {
      case BotEventType.info:
        return Colors.blue;
      case BotEventType.success:
        return Colors.green;
      case BotEventType.warning:
        return Colors.orange;
      case BotEventType.error:
        return Colors.red;
    }
  }
}
