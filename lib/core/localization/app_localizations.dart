import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'login_title': 'Welcome to KRIVA',
      'login_subtitle': 'The Technical Learning & Collaboration Community',
      'login_button': 'Sign In with Google',
      'login_mock': 'Simulate Developer Account',
      'login_request_access': 'Request Club Admission',
      'dashboard_title': 'Dashboard',
      'profile_title': 'Profile',
      'roadmaps_title': 'Roadmaps',
      'community_title': 'Community',
      'collab_title': 'Collaboration',
      'streak_label': 'Day Streak',
      'club_id_label': 'Club ID',
      'domains_label': 'Domains',
      'recent_broadcasts': 'Recent Broadcasts',
      'progress_label': 'Your Domain Progress',
      'completed_tasks': 'tasks completed',
      'language_setting': 'App Language',
    },
    'es': {
      'login_title': 'Bienvenido a KRIVA',
      'login_subtitle': 'La Comunidad de Aprendizaje Técnico y Colaboración',
      'login_button': 'Iniciar sesión con Google',
      'login_mock': 'Simular Cuenta de Desarrollador',
      'login_request_access': 'Solicitar Admisión al Club',
      'dashboard_title': 'Panel de Control',
      'profile_title': 'Perfil',
      'roadmaps_title': 'Rutas de Aprendizaje',
      'community_title': 'Comunidad',
      'collab_title': 'Colaboración',
      'streak_label': 'Racha de Días',
      'club_id_label': 'ID del Club',
      'domains_label': 'Dominios',
      'recent_broadcasts': 'Transmisiones Recientes',
      'progress_label': 'Progreso de tu Dominio',
      'completed_tasks': 'tareas completadas',
      'language_setting': 'Idioma de la Aplicación',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'es'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
