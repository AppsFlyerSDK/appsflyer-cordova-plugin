# Hooks

For iOS, you may need to add Preprocessor Macros to compile your project. <br> You can add them manually by following [these steps](https://stackoverflow.com/questions/26928622/add-preprocessor-macro-to-a-target-in-xcode-6/26928784#26928784) or, you can use our Cordova hooks scripts. For more info about Cordova hooks, please check [this document](https://cordova.apache.org/docs/en/10.x/guide/appdev/hooks/).

## Table of content
- [ Available Scripts](#AvailableScripts)  
- [How To Use](#HowToUse)

## <a id="AvailableScripts"> Available Scripts

The list of available hooks for this plugin is described below.

|Script Name                 |Preprocessor Macros            |Script Uses                  |
|----------------------------|-------------------------------|-----------------------------|
|`af_enable_swizzling.js.`   |`AFSDK_SHOULD_SWIZZLE=1`       |Use this script to enable method swizzling (when using another plugin for deep linking like `cordova-plugin-deeplinks`, `ionic-plugin-deeplinks`, etc.)|
|`af_disable_app_delegate.js`|`AFSDK_DISABLE_APP_DELEGATE=1` |Use this script to disable AppsFlyer deep links implementation completely. The plugin would not process deep links unless you implemented the code in `AppDelegate.m` on your own. |
|`af_use_strict_mode.js`     |`AFSDK_NO_IDFA=1`			     |Use this script to exclude non strict mode SDK methods from the compilation.|

## <a id="HowToUse"> How To Use

To use our Cordova hooks, please follow the next steps:

 1. Make sure you installed the 3rd party library [q](https://www.npmjs.com/package/q).
 2. Create a hooks directory in your project root folder. 
 3. Open the folder `/node_modules/cordova-plugin-appsflyer-sdk/hooks` and copy the scripts into the directory you created in step #2 
 4. Open your `config.xml` file and paste the line `<hook src="hooks/${ScriptName}.js" type="after_prepare" />` under the iOS platform tag.
 5. The Script will run automatically after the command `cordova prepare ios`.
 
*  Example: 
```xml
<widget ...>
	...
	...
	<platform name="ios">  
		<hook src="hooks/af_enable_swizzling.js" type="after_prepare" />  
	    ...
	    ...
	</platform>
</widget>
```

