# AndroidExperiments

The easiest way to build an Android app from the command line on Ubuntu.

Firstrun `make android_tools`

This will install a binary package with the sdkmanager,
then use the sdkmanager to install remaining Android tools and an Android SDK.

Then run `make` to build the build/app.apk

Then run `make install_phone` to send the apk to your USB connected android phone.