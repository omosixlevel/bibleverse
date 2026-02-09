import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';

class AppStrings {
  final String languageCode;

  AppStrings(this.languageCode);

  static AppStrings of(BuildContext context, {bool listen = true}) {
    // Listen to provider to trigger rebuilds when locale changes
    final provider = Provider.of<LocaleProvider>(context, listen: listen);
    return AppStrings(provider.locale?.languageCode ?? 'en');
  }

  // Navigation
  String get navHome => languageCode == 'fr' ? 'Accueil' : 'Home';
  String get navDiscover => languageCode == 'fr' ? 'Découvrir' : 'Discover';
  String get navEvents => languageCode == 'fr' ? 'Événements' : 'Events';
  String get navRooms => languageCode == 'fr' ? 'Salons' : 'Rooms';
  String get navBible => languageCode == 'fr' ? 'Bible' : 'Bible';
  String get navProfile => languageCode == 'fr' ? 'Profil' : 'Profile';

  // Generic
  String get loading => languageCode == 'fr' ? 'Chargement...' : 'Loading...';
  String get error => languageCode == 'fr' ? 'Erreur' : 'Error';
  String get retry => languageCode == 'fr' ? 'Réessayer' : 'Retry';
  String get save => languageCode == 'fr' ? 'Enregistrer' : 'Save';
  String get cancel => languageCode == 'fr' ? 'Annuler' : 'Cancel';
  String get edit => languageCode == 'fr' ? 'Modifier' : 'Edit';
  String get delete => languageCode == 'fr' ? 'Supprimer' : 'Delete';
  String get search => languageCode == 'fr' ? 'Rechercher' : 'Search';
  String get settings => languageCode == 'fr' ? 'Paramètres' : 'Settings';

  // Profile
  String get profileTitle => languageCode == 'fr' ? 'Mon Profil' : 'My Profile';
  String get spiritualInterests =>
      languageCode == 'fr' ? 'Intérêts Spirituels' : 'Spiritual Interests';
  String get activityHistory =>
      languageCode == 'fr' ? 'Historique d\'activité' : 'Activity History';
  String get insights =>
      languageCode == 'fr' ? 'Analyses Gemini' : 'Gemini Insights';
  String get generatingInsights => languageCode == 'fr'
      ? 'Génération d\'analyses personnalisées...'
      : 'Generating personalized insights...';
  String get privateStats =>
      languageCode == 'fr' ? 'Statistiques Privées' : 'Private Stats';

  String get interestsDescription => languageCode == 'fr'
      ? 'Ces intérêts personnalisent votre expérience et vous connectent avec des croyants partageant les mêmes idées.'
      : 'These help personalize your experience and connect you with like-minded believers.';

  String get id => 'ID';
  String get done => languageCode == 'fr' ? 'Terminé' : 'Done';

  // Stats
  String get dayStreak =>
      languageCode == 'fr' ? 'Jours d\'affilée' : 'Day Streak';
  String get thisWeek => languageCode == 'fr' ? 'Cette semaine' : 'This Week';
  String get timeInvested =>
      languageCode == 'fr' ? 'Temps investi' : 'Time Invested';

  // Messages
  String get onlyYouCanSee => languageCode == 'fr'
      ? 'Visible par vous uniquement.'
      : 'Only you can see this. Your journey, your reflection.';
  String get noActivities => languageCode == 'fr'
      ? 'Aucune activité pour le moment.'
      : 'No activities yet. Start your journey!';
  String get refreshInsights =>
      languageCode == 'fr' ? 'Actualiser' : 'Refresh Insights';
  String get checkBackLater => languageCode == 'fr'
      ? 'Revenez plus tard pour des analyses personnalisées.'
      : 'Check back later for personalized insights based on your activity.';

  // Dialogs
  String get signOut => languageCode == 'fr' ? 'Se déconnecter' : 'Sign Out';
  String get signOutConfirm => languageCode == 'fr'
      ? 'Voulez-vous vraiment vous déconnecter ?'
      : 'Are you sure you want to sign out?';
  String get yes => languageCode == 'fr' ? 'Oui' : 'Yes';
  String get no => languageCode == 'fr' ? 'Non' : 'No';

  // Bible
  String get oldTestament =>
      languageCode == 'fr' ? 'Ancien Testament' : 'Old Testament';
  String get newTestament =>
      languageCode == 'fr' ? 'Nouveau Testament' : 'New Testament';
  String get chapters => languageCode == 'fr' ? 'Chapitres' : 'Chapters';
  String get verses => languageCode == 'fr' ? 'Versets' : 'Verses';
  String get bibleVersion =>
      languageCode == 'fr' ? 'Version Biblique' : 'Bible Version';

  // Settings
  String get notifications =>
      languageCode == 'fr' ? 'Notifications' : 'Notifications';
  String get enabled => languageCode == 'fr' ? 'Activé' : 'Enabled';
  String get disabled => languageCode == 'fr' ? 'Désactivé' : 'Disabled';
  String get theme => languageCode == 'fr' ? 'Thème' : 'Theme';
  String get light => languageCode == 'fr' ? 'Clair' : 'Light';
  String get dark => languageCode == 'fr' ? 'Sombre' : 'Dark';
  String get language => languageCode == 'fr' ? 'Langue' : 'Language';
  String get privacy => languageCode == 'fr'
      ? 'Confidentialité & Sécurité'
      : 'Privacy & Security';
  String get help => languageCode == 'fr' ? 'Aide & Support' : 'Help & Support';
  String get about => languageCode == 'fr' ? 'À propos' : 'About';

  // Bible Screen
  String get offlineMode => languageCode == 'fr'
      ? 'Mode hors ligne - Certaines fonctionnalités indisponibles'
      : 'Offline Mode - Some features unavailable';
  String get selectBook =>
      languageCode == 'fr' ? 'Sélectionner un livre' : 'Select Book';
  String get chooseHighlightColor =>
      languageCode == 'fr' ? 'Choisir une couleur' : 'Choose Highlight Color';
  String get geminiEngine => languageCode == 'fr'
      ? 'Moteur Spirituel Gemini'
      : 'Gemini Spiritual Engine';
  String get thematicStudy =>
      languageCode == 'fr' ? 'Étude Thématique' : 'Thematic Study';
  String get contextAnalysis => languageCode == 'fr'
      ? 'Analyse Contextuelle Massive (1M Tokens)'
      : 'Massive Context Analysis (1M Tokens)';
  String get saveToNotebook =>
      languageCode == 'fr' ? 'Enregistrer dans le carnet' : 'Save to Notebook';
  String get addedToNotebook =>
      languageCode == 'fr' ? 'Ajouté au carnet' : 'Added to Notebook';
  String get copiedToClipboard => languageCode == 'fr'
      ? 'Copié dans le presse-papier'
      : 'Copied to clipboard';
  String get versesHighlighted =>
      languageCode == 'fr' ? 'Versets surlignés' : 'Verses highlighted';
  String get internetRequired => languageCode == 'fr'
      ? 'Connexion internet requise'
      : 'Explain feature requires internet connection';
  String get studySaved => languageCode == 'fr'
      ? 'Étude enregistrée !'
      : 'Study saved to your notebook!';

  // Bible Analysis Headers
  String get linguistics => languageCode == 'fr'
      ? 'Linguistique Biblique'
      : 'Biblical Linguistics (Hebrew/Greek)';
  String get similarity => languageCode == 'fr'
      ? 'Similitude d\'Intention'
      : 'Spiritual Intent Similarity';
  String get prayerPoints =>
      languageCode == 'fr' ? 'Points de Prière' : 'Prayer & Declarations';
  String get tags => languageCode == 'fr' ? 'Tags Spirituels' : 'Dynamics Tags';

  // Home Screen
  String get morningPrayer =>
      languageCode == 'fr' ? 'Prière Matinale' : 'Morning Prayer';
  String get noonIntercession =>
      languageCode == 'fr' ? 'Intercession de Midi' : 'Noon Intercession';
  String get eveningReflection =>
      languageCode == 'fr' ? 'Réflexion du Soir' : 'Evening Reflection';
  String get nightWatch =>
      languageCode == 'fr' ? 'Veille de Nuit' : 'Night Watch';
  String get overallProgression => languageCode == 'fr'
      ? 'Progression Spirituelle Globale'
      : 'Overall Spiritual Progression';
  String get activeFocus =>
      languageCode == 'fr' ? 'FOCUS ACTIF' : 'ACTIVE FOCUS';
  String get sacredPulse =>
      languageCode == 'fr' ? 'POULS SACRÉ' : 'SACRED PULSE';
  String get discoverSpaces => languageCode == 'fr'
      ? 'Découvrir des Espaces Sacrés'
      : 'Discover Sacred Spaces';
  String get joinRoomPrompt => languageCode == 'fr'
      ? 'Rejoignez un salon pour commencer'
      : 'Join a room to begin your journey';
  String get geminiSuggestion => languageCode == 'fr'
      ? 'Selon votre engagement, Gemini suggère de terminer votre réflexion quotidienne avant le coucher du soleil.'
      : 'Based on your commitment, Gemini suggests finishing your Daily Reflection before sunset.';
  String get resumeDevotion =>
      languageCode == 'fr' ? 'REPRENDRE LA DÉVOTION' : 'RESUME DEVOTION';
  String get joinEventsPrompt => languageCode == 'fr'
      ? 'Rejoignez des événements pour voir votre chronologie sacrée.'
      : 'Join events to see your sacred timeline.';
  String get ends => languageCode == 'fr' ? 'Fin le' : 'Ends';
  String get ongoingFocus =>
      languageCode == 'fr' ? 'Focus En Cours' : 'Ongoing Focus';
}
