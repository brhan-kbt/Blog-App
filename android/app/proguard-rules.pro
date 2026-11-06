# ---------------------------------------------------------------------------
# R8 / ProGuard keep rules for AdMob mediation (Unity + Meta Audience Network)
# ---------------------------------------------------------------------------

# Meta Audience Network references Facebook annotation classes that are not
# present at compile time. Tell R8 not to warn/strip on them.
-dontwarn com.facebook.infer.annotation.**
-keep class com.facebook.infer.annotation.** { *; }

# Keep the Meta Audience Network SDK classes.
-keep class com.facebook.ads.** { *; }
-dontwarn com.facebook.ads.**

# Keep Unity Ads SDK classes.
-keep class com.unity3d.ads.** { *; }
-keep class com.unity3d.services.** { *; }
-dontwarn com.unity3d.ads.**
-dontwarn com.unity3d.services.**

# Keep Google Mobile Ads mediation adapters.
-keep class com.google.ads.mediation.** { *; }
-keep class com.google.android.gms.ads.** { *; }
-dontwarn com.google.ads.mediation.**
