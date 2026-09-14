import java.util.Properties


plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

// ---- Charge les secrets de signature depuis key.properties (s'il existe) ----
val keyPropertiesFile = rootProject.file("key.properties")
val keystoreProps = Properties()
var signingConfigError: String? = null

if (!keyPropertiesFile.exists()) {
    signingConfigError = "fichier introuvable : ${keyPropertiesFile.path}"
} else {
    try {
        keyPropertiesFile.inputStream().use { keystoreProps.load(it) }
        val requiredKeys = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
        val missingKeys = requiredKeys.filter { keystoreProps.getProperty(it).isNullOrBlank() }
        if (missingKeys.isNotEmpty()) {
            signingConfigError = "propriétés manquantes ou vides : ${missingKeys.joinToString(", ")}"
        }
    } catch (e: Exception) {
        signingConfigError = "fichier illisible : ${e.message}"
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
        versionCode = flutter.versionCode
        versionName = flutter.versionName
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

    val hasSigning = signingConfigError == null

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
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        getByName("debug") { /* rien */ }
    }

}

// ---- Fail-fast : un build `release` sans signature valide doit échouer
// explicitement, plutôt que de produire silencieusement un artefact non
// signé (ou signé par erreur avec le keystore debug). Les autres variants
// (debug, etc.) ne sont pas affectés : ce contrôle ne se déclenche que si
// une tâche `release` fait effectivement partie du graphe de tâches exécuté.
gradle.taskGraph.whenReady {
    val buildingRelease = allTasks.any { it.name.contains("Release") }
    if (buildingRelease && signingConfigError != null) {
        throw GradleException(
            "Signature release invalide ou introuvable ($signingConfigError). " +
                "Renseignez android/key.properties (storeFile, storePassword, " +
                "keyAlias, keyPassword) avant de lancer un build release."
        )
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