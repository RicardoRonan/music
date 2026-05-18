import 'package:flutter/material.dart';

import 'app/app_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  installGlobalErrorHandlers();
  runApp(const AppBootstrap());
}
