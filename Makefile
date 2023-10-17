
JAVAC:=$(shell which javac)

ifeq (,$(JAVAC))
    $(error You have to have javac in your path! Or specify "make JAVAC=/..../bin/javac")
endif

SOURCES:=$(shell find src/main/java -name "*.java")
APP_NAME:=FingerPaint
PACKAGE_NAME:=eu.nivelleringslikaren.testinteraction
PACKAGE_DIR:=eu/nivelleringslikaren/testinteraction

BUILD:=build
BUILD_TOOLS:=build_tools

$(shell mkdir -p $(BUILD) $(BUILD_TOOLS))

GENSRC:=$(BUILD)/generated-sources
RJAVA:=$(GENSRC)/$(PACKAGE_DIR)/R.java

# The android sdk root directory.
ASDKROOT?=$(abspath ./android_tools/android-sdk)

ifeq (,$(wildcard $(ASDKROOT)))
    ifeq (,$(findstring android_tools,$(MAKECMDGOALS)))
        ifneq (,$(ADSKROOT))
            $(info No android-sdk found here: $(ASDKROOT))
            $(info You can specify the location when building: "make ASDKROOT=/...../android-sdk")
            $(error fail)
        endif
        $(info No android-sdk installed. Do: "cd android_tools; make install" for version 30.)
        $(info Or do: "cd android_tools; make install_29" for a different android version.)
        $(info Then run make again!)
        $(error fail)
   endif
endif

# The android version we want to build against.
ANDROID_BUILD_TOOLS_VERSION:=30.0.3
ANDROID_VERSION:=android-30

# The aapt tool is used to package the app and to generate the R.java resource file
AAPT:=$(ASDKROOT)/build-tools/$(ANDROID_BUILD_TOOLS_VERSION)/aapt
# The adb tool is used to install the app into a phone or an emulator.
ADB:=$(ASDKROOT)/platform-tools/adb
# The apksigner tool signs the app package (apk) with the developer key.
APKSIGNER:=$(ASDKROOT)/build-tools/$(ANDROID_BUILD_TOOLS_VERSION)/apksigner
# The avdmanager can install emulators
AVDMANAGER:=$(ASDKROOT)/tools/bin/avdmanager
# The dx tool converts the class files into a more compressed dx file.
DX:=$(ASDKROOT)/build-tools/$(ANDROID_BUILD_TOOLS_VERSION)/dx
# The android.jar contains the whole of android Java library to be linked against.
PLATFORM=$(ASDKROOT)/platforms/$(ANDROID_VERSION)/android.jar
# The sdkmanager can install different android sdks
SDKMANAGER:=$(ASDKROOT)/tools/bin/sdkmanager
# The zipalign tool makes the app archive be of the right size to be signed.
ZIPALIGN:=$(ASDKROOT)/build-tools/$(ANDROID_BUILD_TOOLS_VERSION)/zipalign

ifeq (,$(wildcard $(PLATFORM)))
    $(error No android.jar found! Check your path: $(PLATFORM))
endif

UNALIGNED_APK:=$(BUILD)/app.unaligned.apk
SIGNED_APK:=$(BUILD)/app.apk

all: $(SIGNED_APK)

# Apply this pattern rule only for targets inside $(BUILD)/xml
$(BUILD)/xml/%.xml: src/%.xmq $(BUILD_TOOLS)/xmq
	@mkdir -p $$(dirname $@)
	$(AT)$(BUILD_TOOLS)/xmq $< to_xml > $@
	@echo "Updated $@ from xmq source $<"

$(RJAVA): $(BUILD)/xml/main/AndroidManifest.xml $(BUILD)/xml/main/res/values/strings.xml $(PLATFORM) $(AAPT)
	@mkdir -p $(dir $(RJAVA))
	$(AT)$(AAPT) package -f -m -J $(GENSRC) -M $(BUILD)/xml/main/AndroidManifest.xml -S $(BUILD)/xml/main/res -I $(PLATFORM)

$(BUILD)/classes.dex: $(SOURCES) $(RJAVA)
	@rm -rf $(BUILD)/classes
	@mkdir -p $(BUILD)/classes
	@echo "Compiling $(words $(SOURCES)) java files."
	$(AT)$(JAVAC) -bootclasspath $(PLATFORM) -cp src/main/java -source 1.8 -target 1.8 -d $(BUILD)/classes $(SOURCES) $(RJAVA)
	@echo "Generating dex file."
	$(AT)$(DX) --dex --output=$(BUILD)/classes.dex $(BUILD)/classes

$(UNALIGNED_APK): $(BUILD)/xml/main/AndroidManifest.xml $(BUILD)/classes.dex $(PLATFORM)
	@echo "Creating unaligned apk"
	$(AT)$(AAPT) package -f -m -F $(UNALIGNED_APK) -M $(BUILD)/xml/main/AndroidManifest.xml -S $(BUILD)/xml/main/res -I $(PLATFORM)
	@echo "Adding classes.dex to apk"
	$(AT)(cd $(BUILD); $(AAPT) add ../$(UNALIGNED_APK) classes.dex)

$(SIGNED_APK): $(UNALIGNED_APK)
	@echo "Aligning apk"
	$(AT)$(ZIPALIGN) -f 4 $(UNALIGNED_APK) $(SIGNED_APK)
	@echo "Signing apk"
	$(AT)$(APKSIGNER) sign --ks debug.keystore --ks-pass "pass:123456" $(SIGNED_APK)

start_emulator:
# This is not yet working.

create_emulator:
# This is not working.
	echo "no" | $(AVDMANAGER) --verbose create avd --force --name "generic_10" --package "system-images;android-30;default;x86" --tag "default" --abi "x86"

list_emulators:
	$(AT)$(AVDMANAGER) list

install_emu:
	$(ADB) install $(SIGNED_APK)

install_phone:
	$(AT)$(ADB) install --no-incremental $(SIGNED_APK)

XMQ_SOURCES:=$(wildcard $(BUILD_TOOLS)/xmq/src/main/cc/*)

$(BUILD_TOOLS)/xmq: $(XMQ_SOURCES)
	@echo "Cloning xmq from https://github.com/weetmuts/xmq"
	$(AT)(cd $(BUILD_TOOLS); git clone https://github.com/libxmq/xmq.git xmq_sources > /tmp/xmq_clone 2>&1 ; \
		if [ "$$?" != "0" ]; then cat /tmp/xmq_clone ; fi)
	@echo "Building xmq..."
	$(AT)(cd $(BUILD_TOOLS)/xmq_sources; ./configure ; make > /tmp/xmq_build 2>&1 ; \
        if [ "$$?" != "0" ]; then cat /tmp/xmq_build; fi)
	@echo "Done building xmq."
	$(AT)cp $(BUILD_TOOLS)/xmq_sources/build/*/release/xmq $@

clean:
	@echo "Removing $(BUILD)"
	@rm -rf $(BUILD)

clean-all:
	@echo "Removing $(BUILD) and $(BUILD_TOOLS)"
	@rm -rf $(BUILD) $(BUILD_TOOLS)

help:
	@echo "make                  # Build the $(BUILD)/app.apk"
	@echo "make start_emulator   # Start an Nexus 10 emulator"
	@echo "make install          # Download $(BUILD)/app.apk into your phone"

# These target do not create any file in the filesystem.
.PHONY: all emu install_emu install_phone clean clean-all help android_tools

# Disable all builtin rules makes debugging using "make -d" easier."
MAKEFLAGS += --no-builtin-rules

# Run with "make AT=" to show all important commands as they are executed.
# But continue to skip boring commands like mkdir and echo.
AT?=@
