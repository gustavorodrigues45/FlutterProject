import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/foundation.dart' show debugPrint;
import '../database/database_helper.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _initialized = true;
  }

  void _onNotificationTap(NotificationResponse response) {
    // Aqui você pode navegar para uma tela específica quando a notificação for tocada
    debugPrint('Notificação tocada: ${response.payload}');
  }

  Future<void> solicitarPermissoes() async {
    final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    await androidPlugin?.requestNotificationsPermission();
  }

  Future<void> mostrarNotificacao({
    required int id,
    required String titulo,
    required String corpo,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'vacinas_channel',
      'Notificações de Vacinas',
      channelDescription: 'Notificações para lembrar de vacinas do gado',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(id, titulo, corpo, details, payload: payload);
  }

  Future<void> agendarNotificacao({
    required int id,
    required String titulo,
    required String corpo,
    required DateTime dataAgendada,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'vacinas_channel',
      'Notificações de Vacinas',
      channelDescription: 'Notificações para lembrar de vacinas do gado',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      id,
      titulo,
      corpo,
      tz.TZDateTime.from(dataAgendada, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  Future<void> verificarEEnviarNotificacoesPendentes() async {
    final notificacoesPendentes = await _dbHelper.buscarNotificacoesPendentes();
    
    for (var notificacao in notificacoesPendentes) {
      await mostrarNotificacao(
        id: notificacao['id'],
        titulo: 'Lembrete de Vacina',
        corpo: 'O gado precisa receber a vacina: ${notificacao['vacina']}',
        payload: notificacao['gado_id'],
      );
      
      await _dbHelper.marcarNotificacaoEnviada(notificacao['id']);
    }
  }

  Future<void> cancelarNotificacao(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  Future<void> cancelarTodasNotificacoes() async {
    await _notificationsPlugin.cancelAll();
  }
}
