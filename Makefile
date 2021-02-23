
JAVAC:=$(shell which javac)

ifeq (,$(JAVAC))
    $(error You have to have javac in your path!)
    $(error Or specify "make JAVAC=/..../bin/javac")
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

ASDKROOT:=/usr/lib/android-sdk
ASDKVER:=29.0.2
ASDKV:=29

ADB:=$(ASDKROOT)/platform-tools/adb
AAPT:=$(ASDKROOT)/build-tools/$(ASDKVER)/aapt
DX:=$(ASDKROOT)/build-tools/$(ASDKVER)/dx
ZIPALIGN:=$(ASDKROOT)/build-tools/$(ASDKVER)/zipalign
APKSIGNER:=$(ASDKROOT)/build-tools/$(ASDKVER)/apksigner
PLATFORM=$(ASDKROOT)/platforms/android-$(ASDKV)/android.jar

ifeq (,$(wildcard $(PLATFORM)))
    $(error You have to have an android sdk installed here $(PLATFORM))
endif

UNALIGNED_APK:=$(BUILD)/app.unaligned.apk
SIGNED_APK:=$(BUILD)/app.apk

all: $(SIGNED_APK)

$(BUILD)/xml/%.xml: src/%.xmq $(BUILD_TOOLS)/xmq
	@mkdir -p $$(dirname $@)
	$(AT)$(BUILD_TOOLS)/xmq $< > $@
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

emu:
	adb install path/to/your_app.apk

install:
	adb -d install $(SIGNED_APK)

XMQ_SOURCES:=$(wildcard $(BUILD_TOOLS)/xmq/src/main/cc/*)

$(BUILD_TOOLS)/xmq: $(XMQ_SOURCES)
	@echo "Cloning xmq from https://github.com/weetmuts/xmq"
	$(AT)(cd $(BUILD_TOOLS); git clone https://github.com/weetmuts/xmq.git xmq_sources > /tmp/xmq_clone 2>&1 ; \
		if [ "$$?" != "0" ]; then cat /tmp/xmq_clone ; fi)
	@echo "Building xmq..."
	$(AT)(cd $(BUILD_TOOLS)/xmq_sources; make > /tmp/xmq_build 2>&1 ; \
        if [ "$$?" != "0" ]; then cat /tmp/xmq_build; fi)
	@echo "Done building xmq."
	$(AT)cp $(BUILD_TOOLS)/xmq_sources/build/xmq $@

clean:
	rm -rf $(BUILD)

clean-all:
	rm -rf $(BUILD) $(BUILD_TOOLS)

# These target do not create any file in the filesystem.
.PHONY: all emu install clean clean-all

# Disable all builtin rules makes debugging using "make -d" easier."
MAKEFLAGS += --no-builtin-rules

# Run with "make AT=" to show all important commands as they are executed.
# But continue to skip boring commands like mkdir and echo.
AT?=@
