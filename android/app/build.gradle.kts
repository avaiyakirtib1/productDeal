import java.text.SimpleDateFormat
import java.util.Date
import java.util.Properties
import kotlin.apply
plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties().apply {
    val localFile = rootProject.file("keystore.properties")
    if (localFile.exists()) {
        load(localFile.inputStream())
    }
}

fun findLocalProperty(key: String): String? =
    localProperties.getProperty(key)
android {
    namespace = "com.codemenschen.productdeal"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Enable core library desugaring (required for flutter_local_notifications)
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.codemenschen.productdeal"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Signing configurations for release and debug builds
    signingConfigs {
        create("release") {
            val storeFilePath = findLocalProperty("RELEASE_STORE_FILE")
            val storePassword = findLocalProperty("RELEASE_STORE_PASSWORD")
            val keyAlias = findLocalProperty("RELEASE_KEY_ALIAS")
            val keyPassword = findLocalProperty("RELEASE_KEY_PASSWORD")

            if (storeFilePath != null && storePassword != null && keyAlias != null && keyPassword != null) {
                this.storeFile = file(storeFilePath)
                this.storePassword = storePassword
                this.keyAlias = keyAlias
                this.keyPassword = keyPassword
            } else {
                println("⚠️  Release signing config not found, using default debug keystore.")
            }
        }

        getByName("debug") {
            val storeFilePath = findLocalProperty("RELEASE_STORE_FILE")
            val storePassword = findLocalProperty("RELEASE_STORE_PASSWORD")
            val keyAlias = findLocalProperty("RELEASE_KEY_ALIAS")
            val keyPassword = findLocalProperty("RELEASE_KEY_PASSWORD")

            if (storeFilePath != null && storePassword != null && keyAlias != null && keyPassword != null) {
                this.storeFile = file(storeFilePath)
                this.storePassword = storePassword
                this.keyAlias = keyAlias
                this.keyPassword = keyPassword
            } else {
                println("⚠️  Release debug config not found, using default debug keystore.")
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("release")
        }

        debug {
            isMinifyEnabled = false
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Core library desugaring (required for flutter_local_notifications)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    
    // AppCompat (required by image_cropper/ucrop)
    implementation("androidx.appcompat:appcompat:1.6.1")
    
    // OkHttp3 and OkIO dependencies (required by image_cropper/ucrop)
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
    implementation("com.squareup.okio:okio:3.6.0")
}
