{ pkgs ? import <nixpkgs> {
    config = {
      android_sdk.accept_license = true;
      allowUnfree = true;
    };
  }
}:

let
  androidComposition = pkgs.androidenv.composeAndroidPackages {
    # Command line tools
    cmdLineToolsVersion = "13.0";
    
    # Android SDK tools
    toolsVersion = "26.1.1";
    platformToolsVersion = "35.0.2";
    
    # Build tools - include multiple versions for compatibility
    buildToolsVersions = [ "34.0.0" "35.0.0" ];
    
    # Android platform versions
    platformVersions = [ "34" "35" ];
    
    # CMake for native builds (required by some Flutter plugins)
    cmakeVersions = [ "3.22.1" ];
    
    # NDK for Flutter plugins (version required by flutter_contacts, etc.)
    includeNDK = true;
    ndkVersions = [ "27.0.12077973" ];
    
    # Extras
    includeEmulator = false;
    includeSources = false;
    includeSystemImages = false;
    
    # Extra packages that might be needed
    extraLicenses = [
      "android-googletv-license"
      "android-sdk-arm-dbt-license"
      "android-sdk-preview-license"
      "google-gdk-license"
      "intel-android-extra-license"
      "intel-android-sysimage-license"
      "mips-android-sysimage-license"
    ];
    
    abiVersions = [ "arm64-v8a" "armeabi-v7a" "x86_64" ];
  };

  androidSdk = androidComposition.androidsdk;
in
pkgs.mkShell {
  buildInputs = with pkgs; [
    # Flutter SDK (includes Dart)
    flutter

    # Java for Android builds
    jdk17

    # Android SDK
    androidSdk

    # Additional tools
    git
    
    # CMake (system-level, in case Android SDK cmake has issues)
    cmake
  ];

  ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
  ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
  JAVA_HOME = "${pkgs.jdk17}";
  
  # Point to the CMake in Android SDK
  ANDROID_CMAKE = "${androidSdk}/libexec/android-sdk/cmake/3.22.1/bin/cmake";

  shellHook = ''
    echo ""
    echo "=== Phone Roulette Development Environment ==="
    echo ""
    echo "Flutter: $(flutter --version 2>/dev/null | head -1)"
    echo "Java:    $(java -version 2>&1 | head -1)"
    echo ""
    echo "Android SDK: $ANDROID_SDK_ROOT"
    echo ""
    echo "Included components:"
    echo "  - Platforms: 34, 35"
    echo "  - Build tools: 34.0.0, 35.0.0"
    echo "  - NDK: 27.0.12077973"
    echo "  - CMake: 3.22.1"
    echo ""
    echo "Commands:"
    echo "  flutter run              - Run on connected device"
    echo "  flutter build apk        - Build debug APK"
    echo "  flutter build apk --release - Build release APK"
    echo "  flutter devices          - List connected devices"
    echo "  flutter doctor           - Check setup"
    echo ""
  '';
}
