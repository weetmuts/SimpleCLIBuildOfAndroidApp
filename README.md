# AndroidExperiments

The easiest way to build an Android app from the command line on Ubuntu.

First run `(cd android_tools; make install)`

This will install a binary package with the sdkmanager, then use the
sdkmanager to install remaining Android tools and an Android SDK and
platform.jar for android-30.

Then run `make` to build the build/app.apk

Then run `make install_phone` to send the apk to your USB connected android phone.


## Older versions of android.

You can easily build against android-29 instead.

First run `(cd android_tools; make install_29)` to get platform 29.

Then run: `make BUILD=build29 ANDROID_VERSION=android-29`

This will generate build29/app.apk