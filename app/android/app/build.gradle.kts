plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "io.github.oh_aerox.live_a_long_life"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications 需要（java.time 在 API 26 以下的补丁）
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "io.github.oh_aerox.livealonglife"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // health 插件（Health Connect）要求 26
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // 医疗文字提取（D-23）：ML Kit 中文识别用 bundled 版，模型打进 APK——
    // 国行系统没有 Google 服务，依赖 Play 服务下载模型的版本用不了。
    implementation("com.google.mlkit:text-recognition-chinese:16.0.1")
    // PDF 文字层抽取；系统 PdfRenderer 取文字要 SDK 扩展 13，不可靠。
    implementation("com.tom-roush:pdfbox-android:2.0.27.0")
    // 照片按 EXIF 方向转正后再识别，坐标才能和显示对齐
    implementation("androidx.exifinterface:exifinterface:1.3.7")
}
