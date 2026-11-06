# Keep WorkManager (required by ML Kit)
-keep class androidx.work.** { *; }
-keep class * extends androidx.room.RoomDatabase { *; }
-keep class androidx.room.** { *; }

# Keep ML Kit specific classes
-keep class com.google.android.gms.internal.mlkit_entity_extraction.** { *; }
-keep class com.google.mlkit.** { *; }