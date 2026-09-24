import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// The in-app updater offers a release whenever its version name is higher, but
// Android refuses an APK whose versionCode is lower than the installed one. The
// pubspec build number can't be the versionCode: CI resets it to 1 on every
// patch bump (1.2.4+3 -> 1.2.5+1). So the code follows the version name:
// 1.2.5+1 -> 10200501, above every APK already on phones (the split-ABI
// builds of 1.2.4 reached 4003).
fun versionCodeFor(versionName: String, buildNumber: Int): Int {
    val parts = versionName.split(".").map { it.toIntOrNull() }
    if (parts.size != 3 || parts.any { it == null }) {
        throw GradleException("versionName '$versionName' is not MAJOR.MINOR.PATCH")
    }
    val (major, minor, patch) = parts.map { it!! }
    if (major > 209 || minor > 99 || patch > 999 || buildNumber !in 0..99) {
        throw GradleException(
            "$versionName+$buildNumber does not fit versionCodeFor's layout " +
                "(major <= 209, minor <= 99, patch <= 999, build <= 99)"
        )
    }
    return major * 10_000_000 + minor * 100_000 + patch * 100 + buildNumber
}

android {
    namespace = "com.xjanova.aipray"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        create("release") {
            val keystoreFile = file("aipray-release.jks")
            val keyPropsFile = rootProject.file("key.properties")
            if (keystoreFile.exists()) {
                storeFile = keystoreFile
                if (keyPropsFile.exists()) {
                    val props = Properties()
                    props.load(FileInputStream(keyPropsFile))
                    storePassword = props.getProperty("storePassword")
                    keyAlias = props.getProperty("keyAlias")
                    keyPassword = props.getProperty("keyPassword")
                } else {
                    storePassword = System.getenv("KEYSTORE_PASSWORD")
                    keyAlias = System.getenv("KEY_ALIAS")
                    keyPassword = System.getenv("KEY_PASSWORD")
                }
            }
        }
    }

    defaultConfig {
        applicationId = "com.xjanova.aipray"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = versionCodeFor(flutter.versionName, flutter.versionCode)
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            val releaseSigningConfig = signingConfigs.findByName("release")
            signingConfig = if (releaseSigningConfig?.storeFile?.exists() == true) {
                releaseSigningConfig
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
