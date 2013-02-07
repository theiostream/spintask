include theos/makefiles/common.mk

TWEAK_NAME = SpinTask
SpinTask_FILES = SpinTask.xm
SpinTask_FRAMEWORKS = UIKit CoreGraphics QuartzCore
SpinTask_LDFLAGS = -lactivator

include $(THEOS_MAKE_PATH)/tweak.mk

after-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp SpinTaskPreferences.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/SpinTaskPreferences.plist$(ECHO_END)
	$(ECHO_NOTHING)cp icon.png $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/SpinTaskPreferences.png$(ECHO_END)