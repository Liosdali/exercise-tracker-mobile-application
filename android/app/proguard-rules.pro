# Add project specific ProGuard rules here.

# Flutter wrapper classes (safe default for all Flutter apps).
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# sqflite (SQLite bindings) — keep native bridge classes.
-keep class com.tekartik.sqflite.** { *; }

# flutter_local_notifications — keep receivers/services referenced from the
# manifest and any classes it accesses via reflection.
-keep class com.dexterous.** { *; }

# Flutter's embedding references Play Core "deferred components" (dynamic
# feature delivery) classes that this app doesn't use/depend on. R8 fails
# without these keep rules (missing-class errors) even though the code
# paths are never actually invoked at runtime.
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Gson-based reflection used by some plugins (e.g. shared_preferences,
# flutter_local_notifications) — keep generic signatures.
-keepattributes Signature
-keepattributes *Annotation*

-keep class com.MythosForgeLabs.AtlasWorkout.MainActivity { *; }
