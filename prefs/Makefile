include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = StatusBarProPrefs
StatusBarProPrefs_FILES = StatusBarProPrefsListController.m
StatusBarProPrefs_INSTALL_PATH = /Library/PreferenceBundles
StatusBarProPrefs_FRAMEWORKS = UIKit
StatusBarProPrefs_CFLAGS = -fobjc-arc -Wno-unused-function
StatusBarProPrefs_LDFLAGS = -Wl,-undefined,dynamic_lookup

include $(THEOS_MAKE_PATH)/bundle.mk
