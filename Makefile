THEOS_DEVICE_IP = 127.0.0.1
THEOS_DEVICE_PORT = 22
ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:15.5

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = StatusBarPro
StatusBarPro_FILES = Sources/SBPStatusBar.x Sources/SBPPreferences.m
StatusBarPro_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-unused-variable -Wno-unused-function
StatusBarPro_FRAMEWORKS = UIKit CoreFoundation CoreTelephony AVFoundation QuartzCore

include $(THEOS_MAKE_PATH)/tweak.mk
