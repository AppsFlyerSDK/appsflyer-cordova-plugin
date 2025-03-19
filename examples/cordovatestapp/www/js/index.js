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
                console.log('onAppOpenAttribution 1 ~~>' + res);
                alert('onAppOpenAttribution 1 ~~> ' + res);
            },
            function (err) {
                console.log(err);
            });

        window.plugins.appsFlyer.registerOnAppOpenAttribution(function (res) {
                console.log('onAppOpenAttribution 2 ~~>' + res);
                alert('onAppOpenAttribution 2 ~~> ' + res);
            },
            function (err) {
                console.log(err);
            });
        // if onDeepLinkListener: false or undefined, sdk will ignore registerOnDeepLink
        window.plugins.appsFlyer.registerDeepLink(function (res) {
            console.log("DDL 1~~>" + res);
            alert('DDL 1~~>' + res);
        });

        window.plugins.appsFlyer.registerDeepLink(function (res) {
            console.log("DDL 2~~>" + res);
            alert('DDL 2~~>' + res);
        });

        var options = {
            devKey: 'fakeone',
            appId: 'id111111111',
            isDebug: true,
            onInstallConversionDataListener: true,
            onDeepLinkListener: true, //if true, will override onAppOpenAttribution
            waitForATTUserAuthorization: 15, //--> Here you set the time for the sdk to wait before launch
        };

        window.plugins.appsFlyer.initSdk(options, function (res) {
            console.log('GCD ~~>' + res);
            alert('GCD ~~>' + res);

        }, function (err) {
            console.log(`failed ~~> ${err}`);
        });
        window.plugins.appsFlyer.enableTCFDataCollection(true);
        window.plugins.appsFlyer.startSdk();
    },
    false
);
app.initialize();

