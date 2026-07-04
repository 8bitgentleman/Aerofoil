
# Uncomment this if you're using STL in your project
# You can find more information here:
# https://developer.android.com/ndk/guides/cpp-support
APP_STL := c++_shared

APP_ABI := armeabi-v7a arm64-v8a x86 x86_64

# Min runtime API level
APP_PLATFORM=android-16

# Align native library segments to 16 KB so they load on devices that use
# 16 KB memory pages (e.g. newer Android 15+ devices).
APP_LDFLAGS := -Wl,-z,max-page-size=16384
