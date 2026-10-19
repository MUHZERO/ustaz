import 'package:firebase_core/firebase_core.dart';

/// Push notifications stay off while this returns null.
///
/// To enable them run `flutterfire configure`, then return
/// `DefaultFirebaseOptions.currentPlatform` from the generated
/// `lib/firebase_options.dart` here.
abstract final class FirebaseConfig {
  static FirebaseOptions? options() => null;
}
