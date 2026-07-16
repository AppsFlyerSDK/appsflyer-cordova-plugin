var app = {
    initialize: function () {
        this.bindEvents();
    },
    bindEvents: function () {
        document.addEventListener('deviceready', this.onDeviceReady, false);
    },
};

function isAndroid() {
    return typeof window.cordova !== 'undefined' && window.cordova.platformId === 'android';
}

document.addEventListener(
    'deviceready',
    function () {
        const options = {
            devKey: 'fakeone',
            appId: 'id111111111',
        };
        window.plugins.appsFlyer.initSdk(options, onInitSdkSuccess, onInitSdkError);
    },
    false
);

function invokeHashedPii() {
    window.plugins.appsFlyer.setUserEmail('john.doe@example.com');
    window.plugins.appsFlyer.setUserPhone('1', '5555550123');
    window.plugins.appsFlyer.setUserFirstName('John');
    window.plugins.appsFlyer.setUserLastName('Doe');
    window.plugins.appsFlyer.setUserFbLoginId(1234567890);
}

function onInitSdkSuccess(res) {
    console.log('initSdk success ~~>' + res);

    // SDK 7 order after initialize: config → listeners → sessionReady → start (in callback).
    window.plugins.appsFlyer.disableSKAD(true);
    window.plugins.appsFlyer.setDebugLog(true);
    window.plugins.appsFlyer.enableTCFDataCollection(true);
    window.plugins.appsFlyer.setCurrentDeviceLanguage('en-US');

    if (isAndroid()) {
        window.plugins.appsFlyer.setCollectAndroidID(true);
    } else {
        window.plugins.appsFlyer.disableCollectASA(true);
        window.plugins.appsFlyer.setUseReceiptValidationSandbox(true);
    }

    window.plugins.appsFlyer.registerDeepLink(function (res) {
        console.log('DDL ~~>' + res);
        alert('DDL ~~>' + res);
    });

    window.plugins.appsFlyer.registerConversionDataListener(
        function (res) {
            console.log('onConversionDataSuccess ~~>' + res);
            alert('onConversionDataSuccess ~~>' + res);
        },
        function (err) {
            console.log('onConversionDataFailure ~~>' + err);
            alert('onConversionDataFailure ~~>' + err);
        }
    );

    window.plugins.appsFlyer.registerSessionReadyListener(function () {
        console.log('onSessionReady ~~>');
        window.plugins.appsFlyer.startSdk(onStartSdkSuccess, onStartSdkError);
    });
}

function onInitSdkError(err) {
    console.log('initSdk failed ~~>' + err);
    alert('initSdk failed ~~>' + err);
}

function onStartSdkSuccess(res) {
    console.log('startSdk success ~~>' + res);
    alert('startSdk success ~~>' + res);
    invokeHashedPii();
}

function onStartSdkError(err) {
    console.log('startSdk failed ~~>' + err);
    alert('startSdk failed ~~>' + err);
}

app.initialize();
