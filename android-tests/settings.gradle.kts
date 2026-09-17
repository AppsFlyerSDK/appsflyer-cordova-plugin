// Test-only harness for src/android's Kotlin shim (AppsFlyerPlugin.kt) -- not part of the
// plugin's own distribution or install path (Cordova plugins are consumed via plugin.xml +
// cordovaAF.gradle, which a `cordova platform add android`-generated project applies, not this
// module). Exists solely so `./gradlew testDebugUnitTest` can compile and exercise the plugin's
// JSON-normalization/executor-routing logic against the real af-android-plugin-bridge and
// org.apache.cordova:framework artifacts, mirroring ios-tests/ on the Swift side.
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "android-tests"
