
JAVA_HOME:=/home/fredrik/bin/jdk
JAVAC:=/home/fredrik/bin/jdk/bin/javac

SOURCES:=$(shell find src/main/java -name "*.java")
APP_NAME:=FingerPaint
PACKAGE_NAME:=eu.nivelleringslikaren.testinteraction
PACKAGE_DIR:=eu/nivelleringslikaren/testinteraction

BUILD:=build
GENSRC:=build/generated-sources
RJAVA:=$(GENSRC)/$(PACKAGE_DIR)/R.java

ASDKROOT:=/usr/lib/android-sdk
ASDKVER:=29.0.2
ASDKV:=29

AAPT:=$(ASDKROOT)/build-tools/$(ASDKVER)/aapt
DX:=$(ASDKROOT)/build-tools/$(ASDKVER)/dx
ZIPALIGN:=$(ASDKROOT)/build-tools/$(ASDKVER)/zipalign
APKSIGNER:=$(ASDKROOT)/build-tools/$(ASDKVER)/apksigner
PLATFORM=$(ASDKROOT)/platforms/android-$(ASDKV)/android.jar

UNALIGNED_APK:=$(BUILD)/app.unaligned.apk
SIGNED_APK:=$(BUILD)/app.apk

all: $(SIGNED_APK)

%.xml: %.xmq
	@xmq $< > $@
	@echo Updated $< from xmq source.

$(RJAVA): src/main/AndroidManifest.xml src/main/res/values/strings.xml $(PLATFORM)
	mkdir -p $(dir $(RJAVA))
	$(AAPT) package -f -m -J $(GENSRC) -M src/main/AndroidManifest.xml -S src/main/res -I $(PLATFORM)

build/classes.dex: $(SOURCES) $(RJAVA)
	@rm -rf build/classes
	@mkdir -p build/classes
	$(JAVAC) -bootclasspath $(PLATFORM) -cp src/main/java -source 1.8 -target 1.8 -d build/classes $(SOURCES) $(RJAVA)
	$(DX) --dex --output=build/classes.dex build/classes

$(UNALIGNED_APK): src/main/AndroidManifest.xml build/classes.dex $(PLATFORM)
	@echo Creating unaligned apk
	$(AAPT) package -f -m -F $(UNALIGNED_APK) -M src/main/AndroidManifest.xml -S src/main/res -I $(PLATFORM)
	@echo Adding classes.dex to apk
	(cd build; $(AAPT) add ../$(UNALIGNED_APK) classes.dex)

$(SIGNED_APK): $(UNALIGNED_APK)
	@echo "Aligning apk"
	$(ZIPALIGN) -f 4 $(UNALIGNED_APK) $(SIGNED_APK)
	@echo "Signing apk"
	$(APKSIGNER) sign --ks debug.keystore --ks-pass "pass:123456" $(SIGNED_APK)

emu:
	adb install path/to/your_app.apk

install:
	adb -d install $(SIGNED_APK)

clean:
	rm -rf build
