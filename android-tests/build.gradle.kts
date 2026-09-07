plugins {
    id("com.android.library") version "8.7.2"
    id("org.jetbrains.kotlin.android") version "2.0.21"
}

android {
    namespace = "com.appsflyer.cordova.plugin"
    compileSdk = 34

    defaultConfig {
        minSdk = 21
    }

    // Points straight at the real production source under src/android -- a test of this file,
    // not a copy that can drift out of sync (same reasoning as ios-tests/'s symlinked sources).
    sourceSets["main"].java.srcDirs("../src/android")

    testOptions {
        unitTests.isReturnDefaultValues = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

kotlin {
    jvmToolchain(17)
}

dependencies {
    implementation("com.android.installreferrer:installreferrer:2.1")
    implementation(platform("com.appsflyer:af-android-sdk-bom:7.0.1"))
    implementation("com.appsflyer:af-android-sdk")
    // Pinned explicitly -- af-android-sdk-bom does not yet carry this version (mirrors
    // src/android/cordovaAF.gradle, the real dependency block this harness must match).
    implementation("com.appsflyer:af-android-plugin-bridge:7.0.12")
    implementation("org.apache.cordova:framework:15.0.0")

    // Real org.json impl -- Android's mockable android.jar stubs org.json methods to throw,
    // which would silently pass broken JSON-parsing code inside a try/catch otherwise.
    testImplementation("org.json:json:20240303")
    testImplementation("junit:junit:4.13.2")
}
