# AndroidExperiments

The easiest way to build an Android app from the command line on Ubuntu.

First: `make android_tools`
This will install a binary package with the sdkmanager, then use the sdkmanager to
install remaining tools and an Android SDK.

Then run `make` to build the build/app.apk

Then run `make install` to send the apk to your USB connected android phone.