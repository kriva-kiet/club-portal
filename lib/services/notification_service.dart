import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final Set<String> _initializedUids = {};

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _localInitialized = false;

  // Firestore listener subscriptions
  static StreamSubscription<QuerySnapshot>? _broadcastSub;
  static StreamSubscription<QuerySnapshot>? _sessionSub;
  static StreamSubscription<QuerySnapshot>? _postSub;
  static StreamSubscription<QuerySnapshot>? _userDirectSub;

  // Track when the listener started so we only notify for TRULY NEW docs
  static DateTime? _listenStartTime;

  // ─── Notification channel IDs ────────────────────────────────────────────────
  static const _broadcastChannelId = 'kriva_broadcasts';
  static const _broadcastChannelName = 'KRIVA Broadcasts';
  static const _sessionChannelId = 'kriva_sessions';
  static const _sessionChannelName = 'KRIVA Sessions';
  static const _communityChannelId = 'kriva_community';
  static const _communityChannelName = 'KRIVA Community';
  static const _interactionChannelId = 'kriva_interactions';
  static const _interactionChannelName = 'KRIVA Likes & Comments';

  // ─── Init local notifications ─────────────────────────────────────────────────
  static Future<void> initLocalNotifications() async {
    if (_localInitialized) return;
    _localInitialized = true;

    const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotifications.initialize(initSettings);

    // Create Android notification channels
    final android = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _broadcastChannelId,
        _broadcastChannelName,
        description: 'Broadcast messages from leads and admins',
        importance: Importance.high,
      ),
    );
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _sessionChannelId,
        _sessionChannelName,
        description: 'Scheduled class and session reminders',
        importance: Importance.high,
      ),
    );
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _communityChannelId,
        _communityChannelName,
        description: 'New posts from the community',
        importance: Importance.defaultImportance,
      ),
    );
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _interactionChannelId,
        _interactionChannelName,
        description: 'Likes, comments, and interactions on your posts',
        importance: Importance.high,
      ),
    );
  }

  // ─── Initialize (called once per user session) ───────────────────────────────
  static Future<void> initialize(String uid) async {
    if (_initializedUids.contains(uid)) return;
    _initializedUids.add(uid);

    await initLocalNotifications();

    // Record when we start listening — only notify for docs created AFTER this
    _listenStartTime = DateTime.now();

    // Start Firestore listeners for real-time notifications
    _startFirestoreListeners(uid);

    // Request Android 13+ local notification permissions
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    try {
      // Request FCM permissions
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // VAPID key required for Web Push (FCM web). Get it from:
        // Firebase Console → Project Settings → Cloud Messaging → Web Push certificates
        const vapidKey =
            'BNyXH5iHBHJ0dLzcsNayFqFOW72rq8z5Pk5tyT6cTfVK0dkfZhTM1ZaBzffM4au0Pq8rq7KNULCHACMfyIkP3iU';
        final token = await _messaging.getToken(vapidKey: vapidKey);
        if (token != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .update({
            'fcmToken': token,
            'lastFcmUpdate': FieldValue.serverTimestamp(),
          });
        }

        _messaging.onTokenRefresh.listen((newToken) async {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .update({
            'fcmToken': newToken,
            'lastFcmUpdate': FieldValue.serverTimestamp(),
          });
        });

        await _messaging.subscribeToTopic('all_members');

        // Show FCM foreground messages as local notifications
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          final n = message.notification;
          if (n != null) {
            showBroadcastNotification(
              title: n.title ?? 'KRIVA',
              body: n.body ?? '',
            );
          }
        });
      }
    } catch (e) {
      // FCM unavailable on unsupported platforms
    }
  }

  // ─── Preferences check helper ────────────────────────────────────────────────
  static Future<bool> _isNotificationEnabled(String prefKey, {bool defaultValue = true}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('pref_notify_$prefKey') ?? defaultValue;
    } catch (_) {
      return defaultValue;
    }
  }

  // ─── Firestore real-time listeners ───────────────────────────────────────────
  /// Listen for NEW broadcasts, scheduled classes, user posts, and direct likes/comments
  static void _startFirestoreListeners(String uid) {
    final db = FirebaseFirestore.instance;
    final startTime = _listenStartTime ?? DateTime.now();
    final startTimestamp = Timestamp.fromDate(startTime);

    // 1. Broadcast listener — notify for broadcasts added after login
    _broadcastSub?.cancel();
    _broadcastSub = db
        .collection('broadcasts')
        .where('sentAt', isGreaterThan: startTimestamp)
        .orderBy('sentAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) async {
      final isEnabled = await _isNotificationEnabled('broadcasts', defaultValue: true);
      if (!isEnabled) return;

      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data == null) continue;
          final title = data['title'] as String? ?? 'New Broadcast';
          final body = data['body'] as String? ?? '';
          showBroadcastNotification(title: title, body: body);
        }
      }
    }, onError: (_) {});

    // 2. Session listener — notify for newly scheduled classes
    _sessionSub?.cancel();
    _sessionSub = db
        .collection('sessions')
        .where('dateTime', isGreaterThan: startTimestamp)
        .orderBy('dateTime', descending: false)
        .snapshots()
        .listen((snapshot) async {
      final isEnabled = await _isNotificationEnabled('events', defaultValue: true);
      if (!isEnabled) return;

      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data == null) continue;
          final title = data['title'] as String? ?? 'New Class Scheduled';
          final description = data['description'] as String? ?? 'A new class session has been scheduled.';
          showSessionNotification(title: title, body: description);
        }
      }
    }, onError: (_) {});

    // 3. Community post listener — notify for posts created by other community members
    _postSub?.cancel();
    _postSub = db
        .collection('posts')
        .where('createdAt', isGreaterThan: startTimestamp)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) async {
      final isEnabled = await _isNotificationEnabled('broadcasts', defaultValue: true);
      if (!isEnabled) return;

      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data == null) continue;
          final authorUid = data['authorUid'] as String? ?? '';
          if (authorUid == uid) continue; // Don't notify self

          final authorName = data['authorName'] as String? ?? 'Someone';
          final text = data['text'] as String? ?? '';
          final preview = text.length > 80 ? '${text.substring(0, 80)}…' : text;
          showPostNotification(title: authorName, body: preview);
        }
      }
    }, onError: (_) {});

    // 4. Direct User Notifications listener (Likes, Comments, Invites, Profile approvals)
    _userDirectSub?.cancel();
    _userDirectSub = db
        .collection('user_notifications')
        .where('recipientUid', isEqualTo: uid)
        .where('createdAt', isGreaterThan: startTimestamp)
        .orderBy('createdAt', descending: true)
        .limit(5)
        .snapshots()
        .listen((snapshot) async {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data == null) continue;
          final type = data['type'] as String? ?? 'notification';
          final title = data['title'] as String? ?? 'KRIVA Alert';
          final body = data['body'] as String? ?? '';

          if (type == 'like' || type == 'comment') {
            final isEnabled = await _isNotificationEnabled('broadcasts', defaultValue: true);
            if (!isEnabled) continue;
            showInteractionNotification(title: title, body: body, isLike: type == 'like');
          } else if (type == 'profile_status') {
            final isEnabled = await _isNotificationEnabled('profile_status', defaultValue: true);
            if (!isEnabled) continue;
            showBroadcastNotification(title: title, body: body);
          } else if (type == 'chat_invite') {
            final isEnabled = await _isNotificationEnabled('chat_invites', defaultValue: false);
            if (!isEnabled) continue;
            showBroadcastNotification(title: title, body: body);
          } else {
            showBroadcastNotification(title: title, body: body);
          }
        }
      }
    }, onError: (_) {});
  }

  /// Send a direct in-app & push notification to a specific user
  static Future<void> sendDirectNotification({
    required String recipientUid,
    required String type, // 'like', 'comment', 'session', 'profile_status', etc.
    required String title,
    required String body,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('user_notifications').add({
        'recipientUid': recipientUid,
        'type': type,
        'title': title,
        'body': body,
        'extraData': extraData ?? {},
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (_) {}
  }

  /// Stop all Firestore listeners (call on sign-out)
  static void dispose() {
    _broadcastSub?.cancel();
    _sessionSub?.cancel();
    _postSub?.cancel();
    _userDirectSub?.cancel();
    _broadcastSub = null;
    _sessionSub = null;
    _postSub = null;
    _userDirectSub = null;
    _initializedUids.clear();
    _listenStartTime = null;
    _localInitialized = false;
  }

  // ─── Public helpers: show local notifications ─────────────────────────────────

  /// Show a broadcast notification (from leads/admins)
  static Future<void> showBroadcastNotification({
    required String title,
    required String body,
    int id = 1001,
  }) async {
    await initLocalNotifications();
    await _localNotifications.show(
      id,
      '📢 $title',
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _broadcastChannelId,
          _broadcastChannelName,
          channelDescription: 'Broadcast messages from leads and admins',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
          color: const Color(0xFFE53935),
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// Show a session/class scheduled notification
  static Future<void> showSessionNotification({
    required String title,
    required String body,
    int id = 1002,
  }) async {
    await initLocalNotifications();
    await _localNotifications.show(
      id,
      '📅 Class Scheduled: $title',
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _sessionChannelId,
          _sessionChannelName,
          channelDescription: 'Scheduled class and session reminders',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
          color: const Color(0xFF10B981),
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// Show a community post notification
  static Future<void> showPostNotification({
    required String title,
    required String body,
    int id = 1003,
  }) async {
    await initLocalNotifications();
    await _localNotifications.show(
      id,
      '💬 $title posted in Community',
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _communityChannelId,
          _communityChannelName,
          channelDescription: 'New posts from the community',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/launcher_icon',
          color: const Color(0xFF6366F1),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: false,
        ),
      ),
    );
  }

  /// Show a like or comment notification
  static Future<void> showInteractionNotification({
    required String title,
    required String body,
    bool isLike = false,
    int id = 1004,
  }) async {
    await initLocalNotifications();
    await _localNotifications.show(
      id,
      isLike ? '❤️ $title' : '💬 $title',
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _interactionChannelId,
          _interactionChannelName,
          channelDescription: 'Likes, comments, and interactions on your posts',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
          color: isLike ? const Color(0xFFE53935) : const Color(0xFF3B82F6),
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}
