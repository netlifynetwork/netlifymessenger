import 'package:flutter/material.dart';

void main() => runApp(const NetlifyMessengerApp());

class NetlifyMessengerApp extends StatefulWidget {
  const NetlifyMessengerApp({super.key});
  @override
  State<NetlifyMessengerApp> createState() => _NetlifyMessengerAppState();
}

class _NetlifyMessengerAppState extends State<NetlifyMessengerApp> {
  ThemeMode mode = ThemeMode.dark;
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Netlify Messenger',
        themeMode: mode,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF7900)),
          scaffoldBackgroundColor: const Color(0xFFF5F6F8),
          fontFamily: 'Segoe UI',
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFF7900),
            brightness: Brightness.dark,
            surface: const Color(0xFF191C22),
          ),
          scaffoldBackgroundColor: const Color(0xFF111318),
          fontFamily: 'Segoe UI',
        ),
        home: MessengerScreen(
          dark: mode == ThemeMode.dark,
          toggleTheme: () => setState(() {
            mode = mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
          }),
        ),
      );
}

class Chat {
  Chat(this.name, this.initials, this.color, this.last, this.time,
      {this.unread = 0, this.online = false, List<String>? messages})
      : messages = messages ?? [];
  final String name, initials, last, time;
  final Color color;
  final bool online;
  int unread;
  final List<String> messages;
}

class MessengerScreen extends StatefulWidget {
  const MessengerScreen({super.key, required this.dark, required this.toggleTheme});
  final bool dark;
  final VoidCallback toggleTheme;
  @override
  State<MessengerScreen> createState() => _MessengerScreenState();
}

class _MessengerScreenState extends State<MessengerScreen> {
  int selected = 0;
  String section = 'Chats';
  String filter = 'All';
  final search = TextEditingController();
  final message = TextEditingController();
  final chats = <Chat>[
    Chat('Alex Morgan', 'AM', const Color(0xFF477F9F),
        'That sounds great! See you soon.', '10:42',
        unread: 2, online: true,
        messages: ['Hey! How are you?', 'I’m doing great, thanks! How about you?',
          'Pretty good. Are we still on for today?',
          'Absolutely. I’ll be there around 6.',
          'That sounds great! See you soon.']),
    Chat('Netlify Team', 'N', const Color(0xFFFF7900),
        'Maya: The new design looks amazing.', '09:18',
        unread: 4, messages: ['Welcome to the Netlify Team group!',
          'Thanks everyone. Happy to be here.',
          'Maya: The new design looks amazing.']),
    Chat('Sarah Wilson', 'SW', const Color(0xFF9470B4),
        'Sent a photo', 'Yesterday', online: true,
        messages: ['Did you see the photos?', 'Yes! They look beautiful.']),
    Chat('David Kumar', 'DK', const Color(0xFF438F79),
        'Thanks for your help!', 'Yesterday',
        messages: ['Could you help me with the project?',
          'Of course. Send me the details.', 'Thanks for your help!']),
    Chat('Design Community', 'DC', const Color(0xFF5479C8),
        'Jordan: Shared a new resource', 'Mon',
        messages: ['Jordan: Shared a new resource']),
  ];

  @override
  void dispose() {
    search.dispose();
    message.dispose();
    super.dispose();
  }

  void send() {
    final text = message.text.trim();
    if (text.isEmpty) return;
    setState(() {
      chats[selected].messages.add(text);
      message.clear();
    });
  }

  void newChat() {
    final name = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start a conversation'),
        content: TextField(
          controller: name,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Contact name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final value = name.text.trim();
              if (value.isNotEmpty) {
                setState(() {
                  chats.insert(0, Chat(value, value.substring(0, 1).toUpperCase(),
                      const Color(0xFF477F9F), 'Start a conversation', 'Now'));
                  selected = 0;
                  section = 'Chats';
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final visible = chats.asMap().entries.where((e) {
      final chat = e.value;
      final query = search.text.toLowerCase();
      final match = chat.name.toLowerCase().contains(query) ||
          chat.last.toLowerCase().contains(query);
      final group = chat.name.contains('Team') || chat.name.contains('Community');
      return match && (filter == 'All' ||
          (filter == 'Unread' && chat.unread > 0) ||
          (filter == 'Groups' && group));
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            Container(
              width: 76,
              color: c.surface,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 22),
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF7900),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.chat_bubble_rounded,
                          color: Colors.white, size: 24),
                    ),
                  ),
                  for (final item in [
                    ['Chats', Icons.chat_rounded],
                    ['Calls', Icons.call_rounded],
                    ['Contacts', Icons.people_alt_rounded],
                    ['Settings', Icons.settings_rounded],
                  ])
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Tooltip(
                        message: item[0] as String,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => setState(() => section = item[0] as String),
                          child: Container(
                            width: 50, height: 50,
                            decoration: BoxDecoration(
                              color: section == item[0]
                                  ? const Color(0xFFFF7900).withOpacity(.15)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(item[1] as IconData,
                              color: section == item[0]
                                  ? const Color(0xFFFF7900) : c.onSurfaceVariant),
                          ),
                        ),
                      ),
                    ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Switch theme',
                    onPressed: widget.toggleTheme,
                    icon: Icon(widget.dark ? Icons.light_mode : Icons.dark_mode),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
            VerticalDivider(width: 1, color: c.outlineVariant.withOpacity(.4)),
            if (section == 'Chats') ...[
              SizedBox(
                width: 330,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 25, 16, 18),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('NETLIFY NETWORK',
                                  style: TextStyle(fontSize: 10,
                                    letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                                SizedBox(height: 5),
                                Text('Messages', style: TextStyle(
                                  fontSize: 25, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                          IconButton.filledTonal(
                            onPressed: newChat,
                            icon: const Icon(Icons.add),
                            style: IconButton.styleFrom(
                              foregroundColor: const Color(0xFFFF7900),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 17),
                      child: TextField(
                        controller: search,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search conversations',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          filled: true,
                          fillColor: c.surfaceContainerHighest.withOpacity(.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(13),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Wrap(
                        spacing: 7,
                        children: ['All', 'Unread', 'Groups'].map((v) =>
                          ChoiceChip(
                            label: Text(v),
                            selected: filter == v,
                            onSelected: (_) => setState(() => filter = v),
                            showCheckmark: false,
                            selectedColor: const Color(0xFFFF7900),
                            labelStyle: TextStyle(
                              color: filter == v ? Colors.white : c.onSurface,
                              fontSize: 12),
                          )).toList(),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(21, 17, 20, 8),
                      child: Text('RECENT CHATS', style: TextStyle(
                        fontSize: 10, letterSpacing: 1.4,
                        fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 9),
                        children: visible.map((entry) {
                          final chat = entry.value;
                          final active = selected == entry.key;
                          return ListTile(
                            selected: active,
                            selectedTileColor: const Color(0xFFFF7900).withOpacity(.12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13)),
                            leading: _Avatar(chat: chat, size: 45),
                            title: Text(chat.name, style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                            subtitle: Text(chat.messages.isEmpty
                              ? chat.last : chat.messages.last,
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: c.onSurfaceVariant)),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(chat.time, style: TextStyle(
                                  fontSize: 10, color: c.onSurfaceVariant)),
                                if (chat.unread > 0) ...[
                                  const SizedBox(height: 5),
                                  CircleAvatar(radius: 9,
                                    backgroundColor: const Color(0xFFFF7900),
                                    child: Text('${chat.unread}',
                                      style: const TextStyle(fontSize: 9, color: Colors.white)),
                                  ),
                                ],
                              ],
                            ),
                            onTap: () => setState(() {
                              selected = entry.key;
                              chat.unread = 0;
                            }),
                          );
                        }).toList(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(children: [
                        Icon(Icons.lock_outline, size: 14, color: c.onSurfaceVariant),
                        const SizedBox(width: 7),
                        Text('Your conversations, your space',
                          style: TextStyle(fontSize: 10, color: c.onSurfaceVariant)),
                      ]),
                    ),
                  ],
                ),
              ),
              VerticalDivider(width: 1, color: c.outlineVariant.withOpacity(.4)),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 76,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      color: c.surface,
                      child: Row(children: [
                        _Avatar(chat: chats[selected], size: 42),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(chats[selected].name,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 3),
                            Text(chats[selected].online ? 'Online' : 'Last seen recently',
                              style: TextStyle(fontSize: 11, color: c.onSurfaceVariant)),
                          ],
                        )),
                        IconButton(
                          tooltip: 'Voice call',
                          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Voice calling will be added in a later milestone.'))),
                          icon: const Icon(Icons.call_outlined)),
                        IconButton(
                          tooltip: 'Video call',
                          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Video calling will be added in a later milestone.'))),
                          icon: const Icon(Icons.videocam_outlined)),
                        IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
                      ]),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
                        itemCount: chats[selected].messages.length,
                        itemBuilder: (context, index) {
                          final text = chats[selected].messages[index];
                          final mine = index == chats[selected].messages.length - 2 ||
                              (index == chats[selected].messages.length - 1 &&
                               text == chats[selected].messages.last &&
                               text == message.text);
                          return Align(
                            alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 500),
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                              decoration: BoxDecoration(
                                color: mine ? const Color(0xFFFF7900)
                                  : c.surfaceContainerHighest.withOpacity(.85),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Text(text, style: TextStyle(
                                color: mine ? Colors.white : c.onSurface,
                                fontSize: 13, height: 1.4)),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      color: c.surface,
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                      child: Row(children: [
                        IconButton(onPressed: () {}, icon: const Icon(Icons.sentiment_satisfied_alt_outlined)),
                        IconButton(onPressed: () {}, icon: const Icon(Icons.attach_file)),
                        Expanded(child: TextField(
                          controller: message,
                          minLines: 1, maxLines: 4,
                          onSubmitted: (_) => send(),
                          decoration: InputDecoration(
                            hintText: 'Write a message...',
                            filled: true,
                            fillColor: c.surfaceContainerHighest.withOpacity(.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 17, vertical: 13),
                          ),
                        )),
                        const SizedBox(width: 9),
                        IconButton.filled(
                          onPressed: send,
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFFF7900),
                            foregroundColor: Colors.white,
                            fixedSize: const Size(46, 46)),
                          icon: const Icon(Icons.send_rounded)),
                      ]),
                    ),
                  ],
                ),
              ),
            ] else
              Expanded(
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                      section == 'Calls' ? Icons.call_outlined :
                      section == 'Contacts' ? Icons.people_alt_outlined :
                      Icons.settings_outlined,
                      size: 56, color: const Color(0xFFFF7900)),
                    const SizedBox(height: 18),
                    Text(section, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(
                      section == 'Calls' ? 'Your voice and video call history will appear here.' :
                      section == 'Contacts' ? 'Find people and start conversations.' :
                      'Manage your profile, appearance and privacy.',
                      style: TextStyle(color: c.onSurfaceVariant)),
                    if (section != 'Settings') ...[
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: newChat,
                        icon: const Icon(Icons.add),
                        label: const Text('Start a chat'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFF7900),
                          foregroundColor: Colors.white),
                      ),
                    ],
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.chat, required this.size});
  final Chat chat;
  final double size;
  @override
  Widget build(BuildContext context) => Stack(children: [
    CircleAvatar(
      radius: size / 2,
      backgroundColor: chat.color,
      child: Text(chat.initials, style: TextStyle(
        color: Colors.white, fontWeight: FontWeight.bold, fontSize: size * .29)),
    ),
    if (chat.online)
      Positioned(right: 0, bottom: 0,
        child: Container(width: 11, height: 11,
          decoration: BoxDecoration(
            color: const Color(0xFF25B879),
            shape: BoxShape.circle,
            border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
          ),
        )),
  ]);
}
