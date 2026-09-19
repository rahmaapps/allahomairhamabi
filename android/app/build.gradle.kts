import java.util.Base64
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

// ---- LOT 5.F — Identifiants AdMob : source unique de vérité ----------------
// L'App ID injecté dans AndroidManifest.xml (placeholder ${admobAppId}) est lu
// dans android/ads_ids.properties, le même fichier que celui contrôlé côté Dart
// par test/monetization/ads_config_test.dart. Le manifest ne peut donc plus
// diverger de `AdsConfig` sans que la suite de tests le signale.
//
// Environnement sélectionné par --dart-define=ADS_ENV=test|production. Flutter
// transmet les dart-defines à Gradle via la propriété `dart-defines` (liste de
// valeurs "CLE=VALEUR" encodées en base64). Absente (gradle appelé seul), on
// retombe sur `test` : jamais de bascule implicite en production.
fun adsEnvFromDartDefines(): String {
    val raw = project.findProperty("dart-defines") as String? ?: return "test"
    val decoded = raw.split(",").mapNotNull { token ->
        try {
            String(Base64.getDecoder().decode(token.trim()), Charsets.UTF_8)
        } catch (e: Exception) {
            null
        }
    }
    val entry = decoded.firstOrNull { it.startsWith("ADS_ENV=") } ?: return "test"
    return entry.substringAfter("=").trim()
}

val adsEnv = adsEnvFromDartDefines()
if (adsEnv != "test" && adsEnv != "production") {
    throw GradleException(
        "ADS_ENV invalide : « $adsEnv ». Valeurs acceptées : test, production " +
            "(--dart-define=ADS_ENV=production)."
    )
}

val adsIdsFile = rootProject.file("ads_ids.properties")
if (!adsIdsFile.exists()) {
    throw GradleException("Fichier introuvable : ${adsIdsFile.path} (identifiants AdMob).")
}
val adsIdsProps = Properties()
adsIdsFile.inputStream().use { adsIdsProps.load(it) }

val admobAppId = adsIdsProps.getProperty("$adsEnv.appId").orEmpty()
if (admobAppId.isBlank()) {
    throw GradleException("Propriété « $adsEnv.appId » manquante ou vide dans ${adsIdsFile.path}.")
}
// Fail-fast : un build production ne doit jamais embarquer un placeholder.
if (adsEnv == "production" && admobAppId.startsWith("PLACEHOLDER_PRODUCTION_")) {
    throw GradleException(
        "ADS_ENV=production mais l'App ID de production est encore un placeholder " +
            "(« $admobAppId »). Renseignez les identifiants réels dans " +
            "${adsIdsFile.path} ET dans lib/monetization/ads_config.dart avant " +
            "tout build de production."
    )
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

        // LOT 5.F — consommé par AndroidManifest.xml (meta-data
        // com.google.android.gms.ads.APPLICATION_ID).
        manifestPlaceholders["admobAppId"] = admobAppId
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