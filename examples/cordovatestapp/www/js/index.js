var app = {
    // Application Constructor
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
        window.plugins.appsFlyer.registerDeepLink(function (res) {
            console.log("DDL ~~>" + res);
            alert('DDL ~~>' + res);
        });

        const options = {
            devKey: 'fakeone',
            appId: 'id111111111',
        };
        window.plugins.appsFlyer.disableSKAD(true);
        window.plugins.appsFlyer.initSdk(options);
        window.plugins.appsFlyer.waitForATT(3); //--> Here you set the time for the sdk to wait before launch

        window.plugins.appsFlyer.registerConversionDataListener(function (res) {
                console.log('onConversionDataSuccess ~~>' + res);
                alert('onConversionDataSuccess ~~>' + res);
            },
            function (err) {
                console.log('onConversionDataSuccess ~~>' + err);
                alert('onConversionDataSuccess ~~>' + err);
            })

        window.plugins.appsFlyer.setCollectAndroidID(true);
        window.plugins.appsFlyer.setDebugLog(true);
        window.plugins.appsFlyer.enableTCFDataCollection(true);
        window.plugins.appsFlyer.setCurrentDeviceLanguage("en-US");


        if (isAndroid()) {
            window.plugins.appsFlyer.registerSessionReadyListener(function (event) {
                window.plugins.appsFlyer.startSdk(
                    function (res) {
                        console.log('startSdk success ~~>' + res);
                        alert('startSdk success ~~>' + res);
                    },
                    function (err) {
                        console.log('startSdk failed ~~>' + err);
                        alert('startSdk failed ~~>' + err);
                    }
                );
            });
        } else {
            window.plugins.appsFlyer.startSdk(
                function (res) {
                    console.log('startSdk success ~~>' + res);
                    alert('startSdk success ~~>' + res);
                },
                function (err) {
                    console.log('startSdk failed ~~>' + err);
                    alert('startSdk failed ~~>' + err);
                }
            );
        }
    },
    false
);
app.initialize();

