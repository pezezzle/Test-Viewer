import java.util.Properties

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

val keyProperties = Properties()
val keyPropertiesFile = rootProject.file("key.properties")
if (keyPropertiesFile.exists()) keyPropertiesFile.inputStream().use { keyProperties.load(it) }
val hasReleaseKey = listOf("storeFile", "storePassword", "keyAlias", "keyPassword").all { !keyProperties.getProperty(it).isNullOrBlank() }

android {
    namespace = "com.pezezzle.testmasterviewer"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    defaultConfig {
        applicationId = "com.pezezzle.testmasterviewer"
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    signingConfigs {
        if (hasReleaseKey) create("release") {
            storeFile = rootProject.file(keyProperties.getProperty("storeFile"))
            storePassword = keyProperties.getProperty("storePassword")
            keyAlias = keyProperties.getProperty("keyAlias")
            keyPassword = keyProperties.getProperty("keyPassword")
            storeType = keyProperties.getProperty("storeType", "PKCS12")
        }
    }
    buildTypes {
        getByName("debug") {
            // CI/test builds can coexist with the signed production app.
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
        }
        getByName("release") {
            // Never silently sign a release with a public/debug key.
            if (hasReleaseKey) signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}
tasks.matching { it.name == "preReleaseBuild" }.configureEach {
    doFirst {
        check(hasReleaseKey) { "Release signing is not configured. Create android/key.properties with your private key, or build --debug." }
    }
}
flutter { source = "../.." }
