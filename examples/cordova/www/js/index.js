/*
Pure cordova sample app for AppsFlyer SDK
 */
var app = {
    // Application Constructor
    initialize: function () {
        this.bindEvents();
    },
    bindEvents: function () {
        document.addEventListener('deviceready', this.onDeviceReady, false);
    },
};
document.addEventListener(
    'deviceready',
    function () {

        window.plugins.appsFlyer.registerOnAppOpenAttribution(function (res) {
                console.log('onAppOpenAttribution ~~>' + res);
                alert('onAppOpenAttribution ~~> ' + res);
            },
            function (err) {
                console.log(err);
            });

        // if onDeepLinkListener: false or undefined, sdk will ignore registerOnDeepLink
        window.plugins.appsFlyer.registerOnDeepLink(function (res) {
            console.log("DDL ~~>" + res);
            alert('DDL ~~>' + res);
        });


        var options = {
            devKey: 'UsXxXxed',
            appId: '7XxXx1',
            isDebug: true,
            onInstallConversionDataListener: true,
            // onDeepLinkListener: true, //if true, will override onAppOpenAttribution
            waitForATTUserAuthorization: 10, //--> Here you set the time for the sdk to wait before launch
        };

        window.plugins.appsFlyer.initSdk(options, function (res) {
            console.log('GCD ~~>' + res);
            alert('GCD ~~>' + res);

        }, function (err) {
            console.log(`failed ~~> ${err}`);
        });
    },
    false
);
app.initialize();
