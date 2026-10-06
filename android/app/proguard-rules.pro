# Flutter wrapper
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-dontwarn io.flutter.embedding.**

# Keep app entry point
-keep class com.ashish.aipetcare.** { *; }

# Google Play billing
-keep class com.android.billingclient.** { *; }
-dontwarn com.android.billingclient.**

# Razorpay
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**

# Keep model classes used for JSON serialisation (Gson / Moshi / kotlinx)
-keepattributes Signature
-keepattributes *Annotation*

# OkHttp / Retrofit (if used by any plugin)
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn retrofit2.**

# Google Sign-In
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
