# Release Notes
### 6.0.30
Release date **September 6 2020**
Release type: Major / **Minor** / Hotfix

**Overview and Highlights:**

- Updated iOS SDK to v6.0.3
- API name change: waitForAdvertisingIdentifier --> waitForATTUserAuthorization
- SDK collects IDFA by default for iOS 14 (as for earlier iOS versions)

### 6.0.20
Release date **August 27 2020**
Release type: **Major** / Minor / Hotfix

**Overview and Highlights:**

- Updated iOS SDK to v6.0.2
- AppTrackingTransparency (ATT) dialog is required to collect IDFA for iOS 14

### 5.4.30
Release date **July 30 2020**
Release type: Major / **Minor** / Hotfix

**Overview and Highlights:**

- Updated Android SDK to v5.4.3

- Updated iOS SDK to v5.4.3


### 5.4.1
Release date **June 30 2020**
Release type: Major / **Minor** / Hotfix

**Overview and Highlights:**

- add SharingFilter support

### 5.2.2
Release date **April 30 2020**
Release type: Major / Minor / **Hotfix**

**Overview and Highlights:**

- remove undefined alerts

### 5.2.1
Release date **April 14 2020**

**Overview and Highlights:**

- add useUninstallSandbox option for iOS uninstall

### 5.2.0
Release date **March 10 2020**

**Overview and Highlights:**

- Extended logging and debugging capabilities

- Bug fixes and maintenance

- Updated Android SDK to v5.2.0

- Updated iOS SDK to v5.2.0


### 4.4.22
Release date **Sep 16 2019**
Release type: Major / **Minor** / Hotfix

**Overview and Highlights:**

- Update iOS SDK to 4.10.4, for iOS 13 push token retrieval needed for Uninstall Measurement
- Bug fixes and maintenance

### 4.4.12
Release date **Nov 14 2018**
Release type: Major / Minor / **Hotfix**

**Overview and Highlights:**

- Fixed Android platform <source-file /> tag to work with Cordova-Android 7.1.0 and above

- Updated Android SDK to v4.8.18

- Updated iOS SDK to v4.8.10


### 4.4.10
Release date: **Nov 01 2018**
Release type: Major / **Minor** / Hotfix

**Overview and Highlights:**

- Added new method API for iOS: `registerUninstall`

- Updated Android SDK to latest 4.8.17

- Updated iOS SDK to latest 4.8.10


---


### 4.4.8
Release date: May 10 2018

Release type: Major / Minor / **Hotfix**

Overview and Highlights

- [Android: invalid JSON in initSdk's onSuccess callback on link click](https://github.com/AppsFlyerSDK/cordova-plugin-appsflyer-sdk/issues/31)



---




### 4.4.7
Release date: May 01 2018

Release type: Major / **Minor** / Hotfix

Overview and Highlights

- Android: updated  to latest SDK: 4.8.10

- Android: Moved from jar to gradle 

- Android: added Google install referrer

- Android: Added 2 APIs: collectAndroidID and collectIMEI

- stopTracking API



---




### 4.4.0
* changed Android paths to support cordova-android 7.0.0

### 4.3.0
* Added User Invite and Cross Promotion API Calls
* Bug Fixes

### 4.2.10 (Nov 30, 2016)
* updated iOS Appsflyer SDK vertsion to 4.5.12
* updated Android Appsflyer SDK vertsion to 4.6.1

# Release Notes
### 4.2.9 (Nov 25, 2016)
* moved from PhoneGap to cordova-plugin-appsflyer-sdk
* onInstallConversionDataListener added to `initSdk`
* DOCs fixes

# Release Notes
### 4.2.7 (Nov 14, 2016)
* changed isDebug to default false
* DOCs fixes

### 4.2.6 (Nov 13, 2016)
* added Travis support


### 4.2.4 (Nov 09, 2016)
* added deep linking tracking section


### 4.2.4 (Oct 26, 2016)
* fixed README.md

### 4.2.3 (Oct 19, 2016)
* added unitest for intSDK
* changed initSDK API
* updated static lib 'libAppsFlyerLib.a'
* bug fix: Fixes compatibility with cordova-ios 6 (#17) 
* bug fix: "isDebug" Is Set to YES #21


### 4.2.2 (Oct 18, 2016)
* removed 'test' folder
* added 'tests' regards to Cordova Plugin Test Framework


### 4.2.1 (Oct 13, 2016)
* Fixed typo in `appsflyer.js`
* added `RELEASENOTES.md`
* changed `README.md` (added Ionic example) 
