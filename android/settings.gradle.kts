pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

/* Important : ce bloc garantit les dépôts pour tous les sous-projets */

dependencyResolutionManagement {
    // Autoriser les dépôts ajoutés par les plugins
    repositoriesMode.set(RepositoriesMode.PREFER_PROJECT)
    repositories {
        google()
        mavenCentral()
        // Recommandé : repo Flutter pour éviter que le plugin le rajoute lui-même
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
    }
}


plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
    // ❌ NE PAS ajouter: id("com.android.library")
}

rootProject.name = "test_1"
include(":app")