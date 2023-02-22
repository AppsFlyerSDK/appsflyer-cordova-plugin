TARGET_PLUGIN_DIR="./plugins/cordova-plugin-appsflyer-sdk/"
TARGET_TEST_PLUGIN_DIR="./plugins/cordova-plugin-appsflyer-sdk-tests/"

echo "Create the new target dirs"
for targetDirName in $TARGET_PLUGIN_DIR $TARGET_TEST_PLUGIN_DIR;
do
  mkdir -p $targetDirName
done

echo "Copy cordova-plugin-appsflyer-sdk directories code to the new folder under plugins"
for dirName in src testsScripts www
  do
    cp -r ../../"${dirName}" ${TARGET_PLUGIN_DIR}/"${dirName}"
  done

echo "Copy cordova-plugin-appsflyer-sdk & cordova-plugin-appsflyer-sdk-tests files code to the new folder under plugins"
for targetDir in ${TARGET_PLUGIN_DIR} ${TARGET_TEST_PLUGIN_DIR}
  do
    cp ../../package.json ${targetDir}
    cp ../../plugin.xml ${targetDir}
    if [ "$targetDir" == "$TARGET_TEST_PLUGIN_DIR" ];
    then
      cp ../../testsScripts/testsScripts.js ${targetDir}
    fi
  done

echo "install cordova-plugin-test-framework plugin"
cordova plugin add cordova-plugin-test-framework

echo "set cordova platforms"
cordova platform add ios && cordova platform add android