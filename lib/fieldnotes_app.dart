import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

const forest = Color(0xFF174D3D);
const paper = Color(0xFFF4F7F2);
const coral = Color(0xFFE86F51);

class FieldnotesApp extends StatelessWidget {
  const FieldnotesApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Fieldnotes',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: paper,
      colorScheme: ColorScheme.fromSeed(
        seedColor: forest,
        primary: forest,
        secondary: coral,
        surface: paper,
      ),
      fontFamily: 'Georgia',
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontFamily: 'Arial', color: Color(0xFF28322D)),
        labelMedium: TextStyle(fontFamily: 'Arial'),
      ),
    ),
    home: const FieldnotesHome(),
  );
}

class Fieldnote {
  const Fieldnote({
    required this.id,
    required this.author,
    required this.handle,
    required this.category,
    required this.title,
    required this.summary,
    required this.time,
    required this.readMinutes,
    required this.color,
    required this.icon,
  });

  final String id;
  final String author;
  final String handle;
  final String category;
  final String title;
  final String summary;
  final String time;
  final int readMinutes;
  final int color;
  final int icon;

  Map<String, Object> toJson() => {
    'id': id,
    'author': author,
    'handle': handle,
    'category': category,
    'title': title,
    'summary': summary,
    'time': time,
    'readMinutes': readMinutes,
    'color': color,
    'icon': icon,
  };

  factory Fieldnote.fromJson(Map<String, dynamic> json) => Fieldnote(
    id: json['id'] as String,
    author: json['author'] as String,
    handle: json['handle'] as String,
    category: json['category'] as String,
    title: json['title'] as String,
    summary: json['summary'] as String,
    time: json['time'] as String,
    readMinutes: json['readMinutes'] as int,
    color: json['color'] as int,
    icon: json['icon'] as int,
  );
}

const starterNotes = <Fieldnote>[
  Fieldnote(
    id: 'morning-walk',
    author: 'Nina Patel',
    handle: '@ninamakes',
    category: 'Outdoors',
    title: 'The long way home is still the way home',
    summary:
        'I started taking the river path after work. Ten extra minutes, and the whole day feels different.',
    time: '12 min ago',
    readMinutes: 3,
    color: 0xFFCEE0C4,
    icon: 0xe3a0,
  ),
  Fieldnote(
    id: 'good-questions',
    author: 'Leo Martins',
    handle: '@leomakes',
    category: 'Ideas',
    title: 'A good question can change the shape of a room',
    summary:
        'At our studio, we swapped status updates for one question: what surprised you this week?',
    time: '1 hr ago',
    readMinutes: 5,
    color: 0xFFF4CE83,
    icon: 0xe0c9,
  ),
  Fieldnote(
    id: 'market-table',
    author: 'Sam Rivera',
    handle: '@samstirs',
    category: 'Food',
    title: 'A market table, a paper bag, and no real plan',
    summary:
        'The best dinner this month began with a basket of tomatoes and a conversation with a stranger.',
    time: '3 hrs ago',
    readMinutes: 4,
    color: 0xFFF1B9AC,
    icon: 0xe532,
  ),
  Fieldnote(
    id: 'quiet-corners',
    author: 'Maya Chen',
    handle: '@mayasees',
    category: 'Culture',
    title: 'Finding the quiet corners of a loud city',
    summary:
        'A tiny map of benches, bookshops, and places where nobody minds if you stay awhile.',
    time: 'Yesterday',
    readMinutes: 6,
    color: 0xFFCAD8E5,
    icon: 0xe55f,
  ),
];

class FeedStore {
  static const _feedKey = 'cached_fieldnotes_v1';
  static const _savedKey = 'saved_fieldnotes_v1';
  static const _pushKey = 'push_enabled_v1';

  Future<List<Fieldnote>> loadFeed() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_feedKey);
    if (value == null) {
      await saveFeed(starterNotes);
      return starterNotes;
    }
    try {
      return (jsonDecode(value) as List<dynamic>)
          .map((item) => Fieldnote.fromJson(item as Map<String, dynamic>))
          .toList();
    } on FormatException {
      await saveFeed(starterNotes);
      return starterNotes;
    } on TypeError {
      await saveFeed(starterNotes);
      return starterNotes;
    }
  }

  Future<void> saveFeed(List<Fieldnote> notes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _feedKey,
      jsonEncode(notes.map((n) => n.toJson()).toList()),
    );
  }

  Future<Set<String>> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_savedKey) ?? const <String>[]).toSet();
  }

  Future<void> saveBookmarks(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_savedKey, ids.toList());
  }

  Future<bool> loadPush() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pushKey) ?? false;
  }

  Future<void> savePush(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pushKey, enabled);
  }

  Future<void> clearFeed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_feedKey);
  }
}

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _channel = 'fieldnotes_updates';
  static bool firebaseReady = false;

  static Future<void> initialize() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(settings: settings);
    const channel = AndroidNotificationChannel(
      _channel,
      'Fieldnotes updates',
      description: 'New notes and community updates',
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
    try {
      await Firebase.initializeApp();
      firebaseReady = true;
      FirebaseMessaging.onMessage.listen((message) {
        show(
          message.notification?.title ?? 'A new fieldnote is here',
          message.notification?.body ?? 'Open Fieldnotes to see what is new.',
        );
      });
    } on FirebaseException {
      firebaseReady = false;
    } on Exception {
      firebaseReady = false;
    }
  }

  static Future<bool> enablePush() async {
    if (!firebaseReady) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return false;
    }
    final permission = await FirebaseMessaging.instance.requestPermission();
    final allowed =
        permission.authorizationStatus == AuthorizationStatus.authorized ||
        permission.authorizationStatus == AuthorizationStatus.provisional;
    if (allowed) {
      await FirebaseMessaging.instance.subscribeToTopic('fieldnotes_updates');
      await FirebaseMessaging.instance.getToken();
    }
    return allowed;
  }

  static Future<void> show(String title, String body) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channel,
        'Fieldnotes updates',
        channelDescription: 'New notes and community updates',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }
}

class FieldnotesHome extends StatefulWidget {
  const FieldnotesHome({super.key});

  @override
  State<FieldnotesHome> createState() => _FieldnotesHomeState();
}

class _FieldnotesHomeState extends State<FieldnotesHome> {
  final _store = FeedStore();
  List<Fieldnote> _notes = const [];
  Set<String> _saved = {};
  bool _pushEnabled = false;
  bool _loading = true;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final values = await Future.wait<Object>([
      _store.loadFeed(),
      _store.loadSaved(),
      _store.loadPush(),
    ]);
    if (!mounted) return;
    setState(() {
      _notes = values[0] as List<Fieldnote>;
      _saved = values[1] as Set<String>;
      _pushEnabled = values[2] as bool;
      _loading = false;
    });
  }

  Future<void> _toggleSaved(Fieldnote note) async {
    setState(() {
      if (!_saved.add(note.id)) _saved.remove(note.id);
    });
    await _store.saveBookmarks(_saved);
  }

  Future<void> _addNote(String text) async {
    final title = text.length > 64 ? '${text.substring(0, 61)}...' : text;
    final note = Fieldnote(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      author: 'You',
      handle: '@you',
      category: 'Notes',
      title: title,
      summary: text,
      time: 'Just now',
      readMinutes: 1,
      color: 0xFFD9E2BD,
      icon: 0xe1cc,
    );
    final updated = [note, ..._notes];
    setState(() => _notes = updated);
    await _store.saveFeed(updated);
  }

  Future<void> _refresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    await _store.saveFeed(_notes);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your offline feed is up to date.')),
      );
    }
  }

  Future<void> _togglePush(bool enabled) async {
    if (!enabled) {
      setState(() => _pushEnabled = false);
      await _store.savePush(false);
      return;
    }
    final remote = await NotificationService.enablePush();
    if (!mounted) return;
    if (NotificationService.firebaseReady && !remote) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification permission was not granted.'),
        ),
      );
      return;
    }
    setState(() => _pushEnabled = true);
    await _store.savePush(true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          remote
              ? 'Push notifications enabled.'
              : 'Demo alerts enabled. Add Firebase setup for remote push.',
        ),
      ),
    );
  }

  Future<void> _resetCache() async {
    await _store.clearFeed();
    await _store.saveFeed(starterNotes);
    if (!mounted) return;
    setState(() => _notes = starterNotes);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Feed cache refreshed.')));
  }

  @override
  Widget build(BuildContext context) {
    final savedNotes = _notes.where((n) => _saved.contains(n.id)).toList();
    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : IndexedStack(
                index: _tab,
                children: [
                  _FeedView(
                    notes: _notes,
                    saved: _saved,
                    onSave: _toggleSaved,
                    onRefresh: _refresh,
                    onWrite: _addNote,
                  ),
                  _SavedView(
                    notes: savedNotes,
                    saved: _saved,
                    onSave: _toggleSaved,
                  ),
                  _SettingsView(
                    pushEnabled: _pushEnabled,
                    onPushChanged: _togglePush,
                    onResetCache: _resetCache,
                  ),
                ],
              ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFDCE9D8),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Saved',
          ),
          NavigationDestination(icon: Icon(Icons.tune), label: 'Settings'),
        ],
      ),
    );
  }
}

class _FeedView extends StatefulWidget {
  const _FeedView({
    required this.notes,
    required this.saved,
    required this.onSave,
    required this.onRefresh,
    required this.onWrite,
  });
  final List<Fieldnote> notes;
  final Set<String> saved;
  final ValueChanged<Fieldnote> onSave;
  final Future<void> Function() onRefresh;
  final Future<void> Function(String) onWrite;

  @override
  State<_FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<_FeedView> {
  static const _categories = ['All', 'Outdoors', 'Ideas', 'Food', 'Culture'];
  String _category = 'All';

  @override
  Widget build(BuildContext context) {
    final notes = _category == 'All'
        ? widget.notes
        : widget.notes.where((n) => n.category == _category).toList();
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: forest,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: forest,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.spa_outlined,
                          color: Colors.white,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'FIELDNOTES',
                        style: TextStyle(
                          fontFamily: 'Arial',
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                          fontSize: 13,
                          color: forest,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Search stories',
                        onPressed: () => showSearch<Fieldnote?>(
                          context: context,
                          delegate: _NoteSearch(widget.notes),
                        ),
                        icon: const Icon(Icons.search, color: forest),
                      ),
                      const CircleAvatar(
                        radius: 17,
                        backgroundColor: Color(0xFFFFD7C5),
                        child: Text(
                          'J',
                          style: TextStyle(
                            fontFamily: 'Arial',
                            color: forest,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 23),
                  Text(
                    _dateLabel(),
                    style: const TextStyle(
                      fontFamily: 'Arial',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.15,
                      color: Color(0xFF68766E),
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'A little more\nnoticing.',
                    style: TextStyle(
                      fontSize: 38,
                      height: 1.03,
                      color: forest,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _DailyPrompt(onWrite: widget.onWrite),
                  const SizedBox(height: 23),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'The community journal',
                          style: TextStyle(
                            fontSize: 21,
                            color: forest,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(Icons.wifi_off, size: 15, color: forest),
                      const SizedBox(width: 5),
                      const Text(
                        'available offline',
                        style: TextStyle(
                          fontFamily: 'Arial',
                          fontSize: 11,
                          color: Color(0xFF68766E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final selected = category == _category;
                        return ChoiceChip(
                          label: Text(category),
                          selected: selected,
                          onSelected: (_) =>
                              setState(() => _category = category),
                          showCheckmark: false,
                          labelStyle: TextStyle(
                            fontFamily: 'Arial',
                            fontSize: 12,
                            color: selected ? Colors.white : forest,
                            fontWeight: FontWeight.w600,
                          ),
                          backgroundColor: Colors.white,
                          selectedColor: forest,
                          side: BorderSide(
                            color: selected ? forest : const Color(0xFFDCE3DB),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
          if (notes.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('No stories in this category yet.')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
              sliver: SliverList.separated(
                itemCount: notes.length,
                separatorBuilder: (_, index) => const SizedBox(height: 14),
                itemBuilder: (context, index) => _NoteCard(
                  note: notes[index],
                  saved: widget.saved.contains(notes[index].id),
                  onSave: () => widget.onSave(notes[index]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _dateLabel() {
  const weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  const months = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];
  final now = DateTime.now();
  return '${weekdays[now.weekday - 1]}  /  ${months[now.month - 1]} ${now.day}';
}

IconData _iconFor(int codePoint) => switch (codePoint) {
  0xe3a0 => Icons.nature_people_outlined,
  0xe0c9 => Icons.lightbulb_outline,
  0xe532 => Icons.restaurant_outlined,
  0xe55f => Icons.location_city_outlined,
  _ => Icons.auto_stories_outlined,
};

class _DailyPrompt extends StatelessWidget {
  const _DailyPrompt({required this.onWrite});

  final Future<void> Function(String) onWrite;

  @override
  Widget build(BuildContext context) => Container(
    height: 136,
    width: double.infinity,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: forest,
      borderRadius: BorderRadius.circular(7),
    ),
    child: Stack(
      children: [
        Positioned(
          right: -6,
          bottom: -34,
          child: Icon(
            Icons.filter_vintage,
            size: 168,
            color: Colors.white.withValues(alpha: .09),
          ),
        ),
        Positioned(
          right: 53,
          top: -32,
          child: Icon(
            Icons.circle_outlined,
            size: 102,
            color: const Color(0xFFE9A575).withValues(alpha: .48),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 17, 18, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TODAY\'S FIELDNOTE',
                style: TextStyle(
                  fontFamily: 'Arial',
                  color: Color(0xFFF3C998),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 9),
              const Text(
                'What made you pause today?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => _WriteSheet(onSave: onWrite),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Write a note',
                      style: TextStyle(
                        fontFamily: 'Arial',
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward, size: 15, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.saved,
    required this.onSave,
  });
  final Fieldnote note;
  final bool saved;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final tint = Color(note.color);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFE3E9E2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 104,
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [tint, Color.lerp(tint, Colors.white, .32)!],
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: 18,
                    top: -31,
                    child: Icon(
                      Icons.circle_outlined,
                      size: 152,
                      color: Colors.white.withValues(alpha: .42),
                    ),
                  ),
                  Positioned(
                    right: 72,
                    bottom: -28,
                    child: Icon(
                      _iconFor(note.icon),
                      size: 99,
                      color: forest.withValues(alpha: .74),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    top: 13,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .78),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        note.category.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'Arial',
                          color: forest,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 13, 10, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: tint,
                      child: Text(
                        note.author[0],
                        style: const TextStyle(
                          fontFamily: 'Arial',
                          fontSize: 11,
                          color: forest,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      note.author,
                      style: const TextStyle(
                        fontFamily: 'Arial',
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: forest,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${note.handle}  ·  ${note.time}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Arial',
                          fontSize: 10,
                          color: Color(0xFF7A857D),
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: saved ? 'Remove bookmark' : 'Save story',
                      onPressed: onSave,
                      icon: Icon(
                        saved ? Icons.bookmark : Icons.bookmark_border,
                        color: saved ? coral : forest,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  note.title,
                  style: const TextStyle(
                    fontSize: 19,
                    height: 1.16,
                    color: Color(0xFF21382E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  note.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Arial',
                    fontSize: 12,
                    height: 1.4,
                    color: Color(0xFF56635B),
                  ),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 13, color: forest),
                    const SizedBox(width: 4),
                    Text(
                      '${note.readMinutes} min read',
                      style: const TextStyle(
                        fontFamily: 'Arial',
                        color: forest,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.favorite_border, size: 16, color: forest),
                    const SizedBox(width: 13),
                    const Icon(Icons.ios_share, size: 15, color: forest),
                    const SizedBox(width: 5),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedView extends StatelessWidget {
  const _SavedView({
    required this.notes,
    required this.saved,
    required this.onSave,
  });
  final List<Fieldnote> notes;
  final Set<String> saved;
  final ValueChanged<Fieldnote> onSave;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Eyebrow('YOUR LIBRARY'),
              const SizedBox(height: 7),
              const Text(
                'Keep the good ones.',
                style: TextStyle(fontSize: 31, color: forest),
              ),
            ],
          ),
        ),
      ),
      if (notes.isEmpty)
        const SliverFillRemaining(hasScrollBody: false, child: _EmptySaved())
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
          sliver: SliverList.separated(
            itemCount: notes.length,
            separatorBuilder: (_, index) => const SizedBox(height: 14),
            itemBuilder: (context, index) => _NoteCard(
              note: notes[index],
              saved: saved.contains(notes[index].id),
              onSave: () => onSave(notes[index]),
            ),
          ),
        ),
    ],
  );
}

class _EmptySaved extends StatelessWidget {
  const _EmptySaved();

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        width: 72,
        height: 72,
        decoration: const BoxDecoration(
          color: Color(0xFFE1EADF),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.bookmark_border, color: forest, size: 30),
      ),
      const SizedBox(height: 13),
      const Text(
        'Your reading shelf is waiting.',
        style: TextStyle(color: forest, fontSize: 18),
      ),
      const SizedBox(height: 5),
      const Text(
        'Save a story and it will be here offline.',
        style: TextStyle(fontFamily: 'Arial', color: Color(0xFF68766E)),
      ),
    ],
  );
}

class _SettingsView extends StatelessWidget {
  const _SettingsView({
    required this.pushEnabled,
    required this.onPushChanged,
    required this.onResetCache,
  });
  final bool pushEnabled;
  final ValueChanged<bool> onPushChanged;
  final VoidCallback onResetCache;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
    children: [
      const _Eyebrow('YOUR FIELDNOTES'),
      const SizedBox(height: 7),
      const Text(
        'A quieter corner\nof the internet.',
        style: TextStyle(fontSize: 31, height: 1.1, color: forest),
      ),
      const SizedBox(height: 27),
      const _Eyebrow('NOTIFICATIONS'),
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        value: pushEnabled,
        activeTrackColor: forest,
        title: const Text(
          'Community updates',
          style: TextStyle(fontFamily: 'Arial', fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          NotificationService.firebaseReady
              ? 'Push alerts from Fieldnotes'
              : 'Local demo alerts; Firebase setup needed for remote push',
          style: const TextStyle(fontFamily: 'Arial', fontSize: 12),
        ),
        secondary: const Icon(Icons.notifications_none, color: forest),
        onChanged: onPushChanged,
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.notifications_active_outlined, color: forest),
        title: const Text(
          'Send a test alert',
          style: TextStyle(fontFamily: 'Arial', fontWeight: FontWeight.w600),
        ),
        subtitle: const Text(
          'Check notifications on this device',
          style: TextStyle(fontFamily: 'Arial', fontSize: 12),
        ),
        onTap: () async {
          await NotificationService.show(
            'A small moment for you',
            'There is a new fieldnote waiting in your feed.',
          );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Test notification sent.')),
            );
          }
        },
      ),
      const SizedBox(height: 15),
      const _Eyebrow('OFFLINE STORAGE'),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.offline_pin_outlined, color: forest),
        title: const Text(
          'Refresh saved feed',
          style: TextStyle(fontFamily: 'Arial', fontWeight: FontWeight.w600),
        ),
        subtitle: const Text(
          'Replace the local cache with starter stories',
          style: TextStyle(fontFamily: 'Arial', fontSize: 12),
        ),
        onTap: onResetCache,
      ),
      const SizedBox(height: 22),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFE5ECE2),
          borderRadius: BorderRadius.circular(7),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.cloud_done_outlined, color: forest),
            SizedBox(width: 11),
            Expanded(
              child: Text(
                'Your feed and saved stories live on this device, ready whenever you are offline.',
                style: TextStyle(
                  fontFamily: 'Arial',
                  color: forest,
                  height: 1.45,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontFamily: 'Arial',
      color: coral,
      fontSize: 11,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.2,
    ),
  );
}

class _WriteSheet extends StatelessWidget {
  const _WriteSheet({required this.onSave});

  final Future<void> Function(String) onSave;

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    return Padding(
      padding: EdgeInsets.fromLTRB(
        22,
        22,
        22,
        MediaQuery.viewInsetsOf(context).bottom + 22,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'A moment worth keeping',
            style: TextStyle(fontSize: 25, color: forest),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            autofocus: true,
            maxLines: 5,
            maxLength: 240,
            decoration: InputDecoration(
              hintText: 'What made you pause today?',
              filled: true,
              fillColor: paper,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(7),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 7),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: forest),
              onPressed: () async {
                final text = controller.text.trim();
                if (text.isEmpty) return;
                await onSave(text);
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Your note is saved on this device.'),
                  ),
                );
              },
              child: const Text('Keep this thought'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteSearch extends SearchDelegate<Fieldnote?> {
  _NoteSearch(this.notes);
  final List<Fieldnote> notes;

  @override
  ThemeData appBarTheme(BuildContext context) => Theme.of(context).copyWith(
    appBarTheme: const AppBarTheme(backgroundColor: paper),
    inputDecorationTheme: const InputDecorationTheme(
      hintStyle: TextStyle(fontFamily: 'Arial'),
    ),
  );

  @override
  List<Widget> buildActions(BuildContext context) => [
    IconButton(
      tooltip: 'Clear search',
      onPressed: () => query = '',
      icon: const Icon(Icons.close),
    ),
  ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
    tooltip: 'Back',
    onPressed: () => close(context, null),
    icon: const Icon(Icons.arrow_back),
  );

  @override
  Widget buildResults(BuildContext context) => _matches();

  @override
  Widget buildSuggestions(BuildContext context) => _matches();

  Widget _matches() {
    final q = query.toLowerCase();
    final results = notes
        .where(
          (note) =>
              note.title.toLowerCase().contains(q) ||
              note.summary.toLowerCase().contains(q) ||
              note.category.toLowerCase().contains(q) ||
              note.author.toLowerCase().contains(q),
        )
        .toList();
    if (results.isEmpty) {
      return const Center(child: Text('No notes found. Try another search.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      itemCount: results.length,
      separatorBuilder: (_, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final note = results[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 6),
          leading: CircleAvatar(
            backgroundColor: Color(note.color),
            child: Icon(_iconFor(note.icon), color: forest),
          ),
          title: Text(note.title),
          subtitle: Text('${note.author}  ·  ${note.category}'),
        );
      },
    );
  }
}
