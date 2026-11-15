import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val isIntegrationTest =
    providers.gradleProperty("tukiIntegrationTest").orNull == "true"
val allowUnsignedRelease =
    providers.gradleProperty("tukiAllowUnsignedRelease").orNull == "true"
val releasePropertiesFile = rootProject.file("key.properties")
val releaseProperties = Properties().apply {
    if (releasePropertiesFile.exists()) {
        releasePropertiesFile.inputStream().use(::load)
    }
}
val releasePropertyNames = listOf(
    "storeFile",
    "storePassword",
    "keyAlias",
    "keyPassword",
)
val hasReleaseSigning = releasePropertyNames.all {
    !releaseProperties.getProperty(it).isNullOrBlank()
}

if (
    gradle.startParameter.taskNames.any { it.contains("Release", ignoreCase = true) } &&
    !hasReleaseSigning &&
    !allowUnsignedRelease
) {
    throw GradleException(
        "Release signing is not configured. Copy android/key.properties.example " +
            "to android/key.properties and provide an upload key outside Git, or use " +
            "-PtukiAllowUnsignedRelease=true only for a non-publishable validation build.",
    )
}

android {
    namespace = "dev.tukiapp.tuki_little_adventures"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Confirm this identifier with the Play Console owner before the first
        // upload: Play fixes the package name when the first artifact is added.
        applicationId = "dev.tukiapp.tuki_little_adventures"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["appLabel"] = "TUKI"
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = rootProject.file(releaseProperties.getProperty("storeFile"))
                storePassword = releaseProperties.getProperty("storePassword")
                keyAlias = releaseProperties.getProperty("keyAlias")
                keyPassword = releaseProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        debug {
            // QA vive junto a la app normal. Las herramientas de integración
            // usan otro paquete porque Flutter puede retirarlo al terminar.
            applicationIdSuffix = if (isIntegrationTest) ".qa.integration" else ".qa"
            versionNameSuffix = if (isIntegrationTest) "-integration" else "-qa"
            manifestPlaceholders["appLabel"] =
                if (isIntegrationTest) "TUKI Test" else "TUKI QA"
        }
        getByName("profile") {
            applicationIdSuffix = if (isIntegrationTest) ".qa.integration" else ".qa"
            versionNameSuffix = if (isIntegrationTest) "-integration" else "-qa"
            manifestPlaceholders["appLabel"] =
                if (isIntegrationTest) "TUKI Test" else "TUKI QA"
        }
        release {
            signingConfig = if (hasReleaseSigning) signingConfigs.getByName("release") else null
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
