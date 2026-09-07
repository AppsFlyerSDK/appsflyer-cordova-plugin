var app = {
    // Application Constructor
    initialize: function () {
        this.bindEvents();
    },
    bindEvents: function () {
        document.addEventListener('deviceready', this.onDeviceReady, false);
    },
};
// RPC results/events are objects -- string-concatenating one directly renders "[object Object]".
function fmt(value) {
    return typeof value === 'object' && value !== null ? JSON.stringify(value) : value;
}

document.addEventListener(
    'deviceready',
    async function () {
        // registerOnAppOpenAttribution removed -- folded into registerDeepLinkListener's onDeepLinking.
        window.plugins.appsFlyer.registerDeepLinkListener({
            onDeepLinking: function (res) {
                console.log("DDL 1~~>" + fmt(res));
                alert('DDL 1~~>' + fmt(res));
            }
        }).catch(function (err) {
            console.log(err);
        });

        window.plugins.appsFlyer.registerDeepLinkListener({
            onDeepLinking: function (res) {
                console.log("DDL 2~~>" + fmt(res));
                alert('DDL 2~~>' + fmt(res));
            }
        }).catch(function (err) {
            console.log(err);
        });

        if (!window.AF_CONFIG) {
            alert('Missing js/af-config.js -- run `npm install` (regenerates it from .env; see .env.example).');
            return;
        }

        var options = {
            devKey: window.AF_CONFIG.devKey,
            appId: window.AF_CONFIG.appId,
            // isDebug/onInstallConversionDataListener/onDeepLinkListener/waitForATTUserAuthorization
            // are gone from init()'s schema (see RENAME_AUDIT.md): isDebug -> enableDebug() below;
            // onInstallConversionDataListener -> registerConversionListener; onDeepLinkListener ->
            // registerDeepLinkListener above. waitForATTUserAuthorization has NO equivalent anywhere
            // in js-core-plugin's RPC method schema -- not carried forward, flagged for a human.
        };

        try {
            await window.plugins.appsFlyer.init(options);
        } catch (err) {
            console.log(`failed ~~> ${err}`);
            return;
        }

        window.plugins.appsFlyer.enableDebug({ enabled: true }).catch(function (err) {
            console.log(err);
        });

        // init()'s own success callback used to double as the GCD delivery path
        // (onInstallConversionDataListener: true) -- that's now this standalone listener.
        window.plugins.appsFlyer.registerConversionListener({
            onConversionDataSuccess: function (res) {
                console.log('GCD ~~>' + fmt(res));
                alert('GCD ~~>' + fmt(res));
            },
            onConversionDataFail: function (err) {
                console.log(`failed ~~> ${err}`);
            }
        }).catch(function (err) {
            console.log(err);
        });

        window.plugins.appsFlyer.enableTCFDataCollection({ shouldCollect: true }).catch(function (err) {
            console.log(err);
        });

        // ponytail: session-ready is native-driven and could in principle never fire (e.g. init
        // rejected silently upstream) -- this timeout is just a visible bounded fallback for a
        // manual test app, not a retry/recovery strategy.
        var sessionReady = false;
        window.plugins.appsFlyer.registerSessionReadyListener(function () {
            sessionReady = true;
            window.plugins.appsFlyer.start().catch(function (err) {
                console.log(err);
            });
        }).catch(function (err) {
            console.log(err);
        });
        setTimeout(function () {
            if (!sessionReady) {
                console.log('[AF] session-ready never fired within 10s -- start() was not called.');
            }
        }, 10000);
    },
    false
);
app.initialize();
