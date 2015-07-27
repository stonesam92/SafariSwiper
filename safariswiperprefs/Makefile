include theos/makefiles/common.mk

BUNDLE_NAME = SafariSwiperPrefs
SafariSwiperPrefs_FILES = SafariSwiperPrefs.mm
SafariSwiperPrefs_INSTALL_PATH = /Library/PreferenceBundles
SafariSwiperPrefs_FRAMEWORKS = UIKit
SafariSwiperPrefs_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/SafariSwiperPrefs.plist$(ECHO_END)
