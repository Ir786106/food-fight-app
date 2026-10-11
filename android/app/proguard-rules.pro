# Flutter wrapper
-keep class io.flutter.** { *; }
-keep class io.flutter.plugin.** { *; }
-dontwarn io.flutter.**

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Supabase / Realtime / Ktor
-keep class io.github.jan.supabase.** { *; }
-dontwarn io.github.jan.supabase.**

# Kotlin
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }
-dontwarn kotlin.**
-dontwarn kotlinx.**

# OkHttp (used by Dio indirectly)
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }

# Google Maps
-keep class com.google.android.gms.maps.** { *; }

# OpenFilex
-keep class com.crazecoder.openfile.** { *; }

# Image picker
-keep class io.flutter.plugins.imagepicker.** { *; }

# Package info plus
-keep class dev.fluttercommunity.plus.packageinfo.** { *; }

# Remove debug logging in release
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int d(...);
}
