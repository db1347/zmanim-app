# Flutter wrapper + plugins.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# flutter_local_notifications: scheduled notifications are persisted with
# Gson and restored by reflection after reboot — keep its model classes.
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# Generic Gson TypeToken support (used by the notifications plugin).
-keep class * extends com.google.gson.reflect.TypeToken
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# mobile_scanner uses ML Kit barcode scanning.
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Play Core is referenced by Flutter's deferred-components support but not
# bundled — safe to ignore in apps that don't use it.
-dontwarn com.google.android.play.core.**
