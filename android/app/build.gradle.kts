import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.jihunjo.quotespace"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.jihunjo.quotespace"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            // CodeMagic 환경 변수 우선 확인
            val keystorePath = System.getenv("CM_KEYSTORE_PATH")
            if (keystorePath != null) {
                storeFile = file(keystorePath)
                storePassword = System.getenv("CM_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("CM_KEY_ALIAS")
                keyPassword = System.getenv("CM_KEY_PASSWORD")
            } else {
                // 로컬 key.properties 파일 사용
                val keystorePropertiesFile = rootProject.file("key.properties")
                if (keystorePropertiesFile.exists()) {
                    val keystoreProperties = Properties()
                    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
                    val storeFileProp = keystoreProperties.getProperty("storeFile")
                    val storePasswordProp = keystoreProperties.getProperty("storePassword")
                    val keyAliasProp = keystoreProperties.getProperty("keyAlias")
                    val keyPasswordProp = keystoreProperties.getProperty("keyPassword")
                    
                    if (storeFileProp != null && storePasswordProp != null && keyAliasProp != null && keyPasswordProp != null) {
                        // storeFile 경로는 android/app/ 기준
                        val keystoreFile = file(storeFileProp)
                        if (keystoreFile.exists()) {
                            storeFile = keystoreFile
                            storePassword = storePasswordProp
                            keyAlias = keyAliasProp
                            keyPassword = keyPasswordProp
                            println("Keystore loaded: ${keystoreFile.absolutePath}")
                        } else {
                            println("ERROR: Keystore file not found: ${keystoreFile.absolutePath}")
                        }
                    } else {
                        println("ERROR: Missing keystore properties")
                    }
                } else {
                    println("WARNING: key.properties file not found")
                }
            }
        }
    }

    buildTypes {
        release {
            // CodeMagic 환경 변수 우선 확인
            val keystorePath = System.getenv("CM_KEYSTORE_PATH")
            if (keystorePath != null) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                // 로컬 key.properties 파일 확인
                val keystorePropertiesFile = rootProject.file("key.properties")
                if (keystorePropertiesFile.exists()) {
                    signingConfig = signingConfigs.getByName("release")
                } else {
                    // 키스토어가 없으면 디버그 서명 사용 (경고)
                    signingConfig = signingConfigs.getByName("debug")
                }
            }
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
