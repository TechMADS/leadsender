import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/dropdown_provider.dart';
import 'providers/lead_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/template_provider.dart';
import 'providers/theme_provider.dart';
import 'services/share_intent_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await ShareIntentService.instance.init();
  } catch (e) {
    debugPrint('ShareIntent init failed: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..load()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..load()),
        ChangeNotifierProvider(create: (_) => TemplateProvider()..load()),
        ChangeNotifierProvider(create: (_) => DropdownProvider()),
        ChangeNotifierProvider(create: (_) => LeadProvider()),
      ],
      child: const LeadSenderApp(),
    ),
  );

  // Defer network calls until after the first frame
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // These will be loaded lazily by the screens, or you can trigger here
    // if you have a reference to the providers.
  });
}
// import 'package:flutter/material.dart';
// import 'package:leadsender/providers/template_provider.dart';
// import 'package:provider/provider.dart';
// import 'app.dart';
// import 'providers/lead_provider.dart';
// import 'providers/settings_provider.dart';
// import 'providers/theme_provider.dart';
// import 'services/lead_database_service.dart';
// import 'services/share_intent_service.dart';
//
// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   final db = LeadDatabaseService();
//   await db.init();
//   await ShareIntentService.instance.init();
//   runApp(
//     MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => ThemeProvider()..load()),
//         ChangeNotifierProvider(create: (_) => SettingsProvider()..load()),
//         ChangeNotifierProvider(create: (_) => TemplateProvider()..load()),
//         ChangeNotifierProvider(create: (_) => LeadProvider(db)..loadHistory()),
//       ],
//       child: const LeadSenderApp(),
//     ),
//   );
// }