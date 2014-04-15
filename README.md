Air Native Extension for Microphone (iOS)
===========================

This is an [Air native extension](http://www.adobe.com/devnet/air/native-extensions-for-air.html) aiming to replace the Microphone class on iOS. It has been developed by [Fovea](http://fovea.cc).

Notes
---------

* only support activity level monitoring for now.
* this is WORK IN PROGRESS.

Installation
---------

The ANE binary (AirMicrophone.ane) is located in the *bin* folder. You should add it to your application project's Build Path and make sure to package it with your app (more information [here](http://help.adobe.com/en_US/air/build/WS597e5dadb9cc1e0253f7d2fc1311b491071-8000.html)).


Build script
---------

Should you need to edit the extension source code and/or recompile it, you will find an ant build script (build.xml) in the *build* folder:

```bash
cd /path/to/the/ane

# Setup build configuration
cd build
mv example.build.config build.config
# Edit build.config file to provide your machine-specific paths

# Build the ANE
ant
```


Authors
------

This ANE has been written by [Jean-Christophe Hoelt](https://github.com/j3k0). It belongs to [Fovea](http://fovea.cc) and is distributed under the [Apache Licence, version 2.0](http://www.apache.org/licenses/LICENSE-2.0).
