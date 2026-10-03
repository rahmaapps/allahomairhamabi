# Règles ProGuard/R8 pour Gson, utilisé en interne par flutter_local_notifications
# (17.2.4, Gson 2.8.9 embarqué — voir android/build.gradle du plugin) pour
# sérialiser/désérialiser la liste des notifications planifiées
# (SharedPreferences "scheduled_notifications" + reprise après reboot via
# ScheduledNotificationBootReceiver).
#
# CAUSE RACINE CONFIRMÉE (source du plugin + source Gson 2.8.9 inspectées
# directement) :
#   FlutterLocalNotificationsPlugin.java, loadScheduledNotifications() :
#     Type type = new TypeToken<ArrayList<NotificationDetails>>() {}.getType();
#   Cette classe anonyme (sous-classe de TypeToken) doit conserver son
#   attribut Signature pour que Gson résolve son paramètre générique à
#   l'exécution. Si R8 le supprime, TypeToken.getSuperclassTypeParameter()
#   (Gson 2.8.9) exécute littéralement :
#     if (superclass instanceof Class) { throw new RuntimeException("Missing type parameter."); }
#   — d'où PlatformException(error, "Missing type parameter.", ...).
#   `loadScheduledNotifications()` est appelée à la fois par cancel()
#   (cancelNotification -> removeNotificationFromCache) et par la
#   planification (saveScheduledNotifications) : d'où l'échec identique des
#   deux appels.
#
# Un premier jeu de règles Gson standard (allowobfuscation/allowshrinking,
# ciblé) n'a pas suffi en pratique sur ce build — renforcé ci-dessous par un
# `-keep` inconditionnel sur Gson et sur le paquet du plugin, pour éliminer
# toute marge d'optimisation R8 sur ce mécanisme précis.
-keepattributes Signature,*Annotation*,InnerClasses,EnclosingMethod

-dontwarn sun.misc.**

-keep class com.google.gson.** { *; }
-keep interface com.google.gson.** { *; }

-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Règle officielle Gson pour les sous-classes anonymes de TypeToken — retirée
# par erreur lors du renforcement ci-dessus, réintroduite en complément (pas
# en remplacement) car ciblant spécifiquement FlutterLocalNotificationsPlugin$1
# (= new TypeToken<ArrayList<NotificationDetails>>() {} dans
# loadScheduledNotifications(), confirmée par mapping.txt : renommée par R8
# malgré la règle par paquet ci-dessus, absente de seeds.txt).
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken { *; }
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken
