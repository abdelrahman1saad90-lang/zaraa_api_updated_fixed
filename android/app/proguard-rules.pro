# ── Zaraa ProGuard Rules ──────────────────────────────────────────
# Keep Flutter engine
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }

# Keep Gson / JSON serialization
-keepattributes Signature
-keepattributes *Annotation*

# OkHttp (used by Dio)
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# Dio
-keep class com.dio.** { *; }

# SharedPreferences
-keep class android.content.SharedPreferences { *; }

# Image Picker
-keep class io.flutter.plugins.imagepicker.** { *; }

# Prevent stripping Kotlin metadata needed by reflection
-keep class kotlin.Metadata { *; }
