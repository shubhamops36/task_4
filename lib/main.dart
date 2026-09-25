import 'package:flutter/material.dart';

import 'fieldnotes_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  runApp(const FieldnotesApp());
}
