plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

fun secretValue(name: String): String? {
    val envValue = providers.environmentVariable(name).orNull?.trim()
    if (!envValue.isNullOrEmpty()) {
        return envValue
    }

    val propertyValue = (findProperty(name) as String?)?.trim()
    return propertyValue?.takeIf { it.isNotEmpty() }
}

val releaseKeystoreFile = secretValue("ANDROID_UPLOAD_KEYSTORE_PATH")
    ?.let { file(it) }
    ?.takeIf { it.exists() }
val releaseKeyAlias = secretValue("ANDROID_UPLOAD_KEY_ALIAS")
val releaseKeystorePassword = secretValue("ANDROID_UPLOAD_KEYSTORE_PASSWORD")
val releaseKeyPassword = secretValue("ANDROID_UPLOAD_KEY_PASSWORD")
val hasReleaseSigning = releaseKeystoreFile != null &&
    !releaseKeyAlias.isNullOrEmpty() &&
    !releaseKeystorePassword.isNullOrEmpty() &&
    !releaseKeyPassword.isNullOrEmpty()

android {
    namespace = "com.example.jarz_pos"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.jarz_pos"
        // You can update the following values to match your application needs.
        // For more information, see: https://docs.flutter.dev/deployment/android#reviewing-the-gradle-build-configuration.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "environment"

    productFlavors {
        create("staging") {
            dimension = "environment"
            applicationIdSuffix = ".staging"
            versionNameSuffix = "-staging"
            manifestPlaceholders["appLabel"] = "Jarz POS Staging"
        }

        create("production") {
            dimension = "environment"
            manifestPlaceholders["appLabel"] = "Jarz POS"
        }

        // Jarz Studio ships as its own app (lib/main_studio.dart) with its own package, so it
        // installs next to the POS app. The server comes from --dart-define=ENV=staging|prod,
        // exactly as for the POS flavours; the flavour only sets identity and label.
        create("studioStaging") {
            dimension = "environment"
            applicationId = "com.orderjarz.studio.staging"
            versionNameSuffix = "-staging"
            manifestPlaceholders["appLabel"] = "Jarz Studio Staging"
        }

        create("studioProduction") {
            dimension = "environment"
            applicationId = "com.orderjarz.studio"
            manifestPlaceholders["appLabel"] = "Jarz Studio"
        }
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = releaseKeystoreFile
                storePassword = releaseKeystorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            // CI injects the release keystore via secrets; local release builds still work with debug signing.
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }

    // Removed custom splits { abi { ... } } block because Flutter manages ABI outputs.
    // To produce per-ABI APKs use: flutter build apk --split-per-abi
    // (Not supported directly on 'flutter run')
}

flutter {
    source = "../.."
}

dependencies {
    project.findProject(":flutter_native_splash")?.let { add("implementation", it) }
    project.findProject(":integration_test")?.let { add("implementation", it) }
    implementation(platform("com.google.firebase:firebase-bom:33.5.1"))
    implementation("com.google.firebase:firebase-messaging")
}
