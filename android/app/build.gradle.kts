import java.util.Properties


plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

// ---- Charge les secrets de signature depuis key.properties (s'il existe) ----
val keystoreProps = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) {
        load(f.inputStream())
    }
}

android {
    namespace = "com.joumane.allahomairhamabi"

    // Tu peux garder 36 si toutes tes libs/SDK sont compatibles. 34–36 conviennent.
    compileSdk = 36

    defaultConfig {
        // ⚠️ applicationId final : celui du Play Store
        applicationId = "com.joumane.allahomairhamabi"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = 4
        versionName = "1.1"
    }

    // ✅ Java 17 + desugaring
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    // ---- Configs de signature ----

    val hasSigning = keystoreProps.getProperty("storeFile")?.isNotBlank() == true

    signingConfigs {
        if (hasSigning) {
            create("release") {
                storeFile = file(keystoreProps.getProperty("storeFile"))
                storePassword = keystoreProps.getProperty("storePassword")
                keyAlias = keystoreProps.getProperty("keyAlias")
                keyPassword = keystoreProps.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        getByName("release") {
            if (hasSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
            isMinifyEnabled = false
            isShrinkResources = false
        }
        getByName("debug") { /* rien */ }
    }

}

flutter {
    source = "../.."
}

dependencies {
    // Desugaring (garde-le)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
    // Les dépendances Flutter restent gérées par le plugin
}