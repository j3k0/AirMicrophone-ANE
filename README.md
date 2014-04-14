Air Native Extension for In App Purchases (iOS + Android)
======================================

This is an [Air native extension](http://www.adobe.com/devnet/air/native-extensions-for-air.html) for In-App Purchases on iOS and Android. It has been developed by [FreshPlanet](http://freshplanet.com) and is used in the game [SongPop](http://songpop.fm).


Notes
---------

* iOS implementation does NOT contain on-device receipt validation.
* Android implementation uses [In-app Billing Version 3](http://developer.android.com/google/play/billing/api.html).


Installation
---------

The ANE binary (InAppPurchase.ane) is located in the *bin* folder. You should add it to your application project's Build Path and make sure to package it with your app (more information [here](http://help.adobe.com/en_US/air/build/WS597e5dadb9cc1e0253f7d2fc1311b491071-8000.html)).

On Android:

 * you will need to add the following in your application descriptor:

```xml

<android>
    <manifestAdditions><![CDATA[
        <manifest android:installLocation="auto">
            
            <uses-permission android:name="com.android.vending.BILLING" />
            
            <application>
                <service android:name="com.freshplanet.inapppurchase.BillingService" />
            </application>

        </manifest>
    ]]></manifestAdditions>
</android>
```



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

This ANE has been written by [Thibaut Crenn](https://github.com/titi-us). It belongs to [FreshPlanet Inc.](http://freshplanet.com) and is distributed under the [Apache Licence, version 2.0](http://www.apache.org/licenses/LICENSE-2.0).