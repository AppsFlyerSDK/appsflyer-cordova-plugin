#If you want to run locally use these commented lines:
# shellcheck disable=SC2164
#EMULATOR_NAME=$(emulator -list-avds | sed -n 1p)
#echo "the emulator name is: ${EMULATOR_NAME}"
#PROJECT_PATH=$(pwd)
#cd ~/Library/Android/sdk && emulator -avd "${EMULATOR_NAME}" -no-window & adb wait-for-device shell "while [[ -z $(getprop sys.boot_completed) ]]; do sleep 1; done;"
#EMULATOR_ID_OBJECT=$(adb devices | grep "emulator" | awk '{print $1}')
#EMULATOR_ID=${EMULATOR_ID_OBJECT[0]}
#echo "the emulator id is: ${EMULATOR_ID}"
#cd "${PROJECT_PATH}"
#cordova-paramedic --platform android --plugin plugins/cordova-plugin-appsflyer-sdk --outputDir "${HOME}"/projects/Dev/appsflyer-cordova-plugin/examples/cordovatestapp/testResults --verbose --target "${EMULATOR_ID}"

#Otherwise, when running through git actions that's the proper way to do this:
npm install "https://github.com/apache/cordova-paramedic.git#master" --save -g
DIR=$(pwd)
cordova-paramedic --platform android --plugin plugins/cordova-plugin-appsflyer-sdk --outputDir "${DIR}"/testResults/android --verbose

