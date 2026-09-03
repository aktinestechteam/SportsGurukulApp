import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

import 'app/app.dart';
import 'app/dependencies.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  Dependencies.initialize();
  runApp(const SportsGurukulApp());
}
