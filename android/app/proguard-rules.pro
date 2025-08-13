# Add project specific ProGuard rules here.

## Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

## Dart
-keep class io.flutter.embedding.** { *; }

## Keep application class
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider

## PDF and image processing
-dontwarn java.awt.**
-dontwarn java.beans.Beans
-dontwarn javax.security.**
-keep class com.itextpdf.** { *; }

## Permission handler
-keep class com.baseflow.permissionhandler.** { *; }

## Image picker  
-keep class io.flutter.plugins.imagepicker.** { *; }

## Shared preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }