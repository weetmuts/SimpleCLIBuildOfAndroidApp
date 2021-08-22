
help:
	@echo "Help"
	@echo "make install # to install cli tools, build tools and sdk for android-30."
	@echo "make install_29 # also install android-29"

VER:=android-30
BTVER:=30.0.3
BOOTSTRAP_TOOLS:=cmdline-tools
SDKROOT:=android-sdk
SDKMANAGER:=$(BOOTSTRAP_TOOLS)/bin/sdkmanager --sdk_root=$(SDKROOT)

$(shell mkdir -p $(BOOTSTRAP_TOOLS) $(SDKROOT))

install:
	@echo "Bootstrapping cli tools, in particular sdkmanager..."
	@wget --no-clobber https://dl.google.com/android/repository/commandlinetools-linux-7006259_latest.zip
	@echo "Unzipping cli tools...this can take a while..."
	@unzip -n commandlinetools-linux-7006259_latest.zip | sed 's/^.*$$/./g' | tr -d '\n'
	@echo Using bootstrapped sdkmanager to install cli tools again.
	$(SDKMANAGER) "tools"
	@echo Using bootstrap sdkmanager to install build tools $(BTVER)
	$(SDKMANAGER) "build-tools;$(BTVER)"
	@echo Using bootstrap sdkmanager to sdk $(VER)
	$(SDKMANAGER) "platforms;$(VER)"

install_29: install
	$(SDKMANAGER) "platforms;android-29"

.PHONY: install install_29
