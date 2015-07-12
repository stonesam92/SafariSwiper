DEBUG = 0
GO_EASY_ON_ME = 1
TARGET_IPHONEOS_DEPLOYMENT_VERSION = 8.0
ARCHS = armv7 arm64 armv7s

include theos/makefiles/common.mk

TWEAK_NAME = SafariSwiper
SafariSwiper_FILES = Tweak.xm CKBlurView.m
SafariSwiper_FRAMEWORKS = UIKit QuartzCore CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 MobileSafari"
include $(THEOS_MAKE_PATH)/aggregate.mk
