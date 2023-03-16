/* jshint jasmine: true */

exports.defineAutoTests = function () {
    var platform = window.cordova.platformId;
    var isIOS = window.cordova.platformId === 'ios';
    var isAndroid = window.cordova.platformId === 'android';


    var AppsFlyerError = {
        INVALID_ARGUMENT_ERROR: "INVALID_ARGUMENT_ERROR",
        NO_DEVKEY_FOUND: "AppsFlyer 'devKey' is missing or empty",
        DEVKEY_NOT_VALID: "'devKey' is not valid",
        APPID_NOT_VALID: "'appId' is not valid",
        NO_APPID_FOUND: "'appId' is missing or empty",
        SUCCESS: "Success"
    };


    var fail = function (done) {
        expect(true).toBe(false);
        done();
    };

    describe("AppsFlyer", function () {

        it("appsflyer.spec.1 should exist", function () {
            expect(window.plugins.appsFlyer).toBeDefined();
        });

        it("appsFlyer.initSdk method", function () {
            expect(window.plugins.appsFlyer.initSdk).toBeDefined();
            expect(typeof window.plugins.appsFlyer.initSdk).toBe('function');
        });

        it("appsFlyer.registerDeepLink method", function () {
            expect(window.plugins.appsFlyer.registerDeepLink).toBeDefined();
            expect(typeof window.plugins.appsFlyer.registerDeepLink).toBe('function');
        });

        it("appsFlyer.registerOnAppOpenAttribution method", function () {
            expect(window.plugins.appsFlyer.registerOnAppOpenAttribution).toBeDefined();
            expect(typeof window.plugins.appsFlyer.registerOnAppOpenAttribution).toBe('function');
        });

        it("appsFlyer.setCurrencyCode method", function () {
            expect(window.plugins.appsFlyer.setCurrencyCode).toBeDefined();
            expect(typeof window.plugins.appsFlyer.setCurrencyCode).toBe('function');
        });

        it("appsFlyer.setAppUserId method", function () {
            expect(window.plugins.appsFlyer.setAppUserId).toBeDefined();
            expect(typeof window.plugins.appsFlyer.setAppUserId).toBe('function');
        });

        it("appsFlyer.getAppsFlyerUID method", function () {
            expect(window.plugins.appsFlyer.getAppsFlyerUID).toBeDefined();
            expect(typeof window.plugins.appsFlyer.getAppsFlyerUID).toBe('function');
        });

        it("appsFlyer.anonymizeUser method", function () {
            expect(window.plugins.appsFlyer.anonymizeUser).toBeDefined();
            expect(typeof window.plugins.appsFlyer.anonymizeUser).toBe('function');
        });

        it("appsFlyer.Stop method", function () {
            expect(window.plugins.appsFlyer.Stop).toBeDefined();
            expect(typeof window.plugins.appsFlyer.Stop).toBe('function');
        });

        it("appsFlyer.logEvent method", function () {
            expect(window.plugins.appsFlyer.logEvent).toBeDefined();
            expect(typeof window.plugins.appsFlyer.logEvent).toBe('function');
        });

        it("appsFlyer.updateServerUninstallToken method", function () {
            expect(window.plugins.appsFlyer.updateServerUninstallToken).toBeDefined();
            expect(typeof window.plugins.appsFlyer.updateServerUninstallToken).toBe('function');
        });

        it("appsFlyer.setAppInviteOneLinkID method", function () {
            expect(window.plugins.appsFlyer.setAppInviteOneLinkID).toBeDefined();
            expect(typeof window.plugins.appsFlyer.setAppInviteOneLinkID).toBe('function');
        });

        it("appsFlyer.generateInviteLink method", function () {
            expect(window.plugins.appsFlyer.generateInviteLink).toBeDefined();
            expect(typeof window.plugins.appsFlyer.generateInviteLink).toBe('function');
        });

        it("appsFlyer.logCrossPromotionImpression method", function () {
            expect(window.plugins.appsFlyer.logCrossPromotionImpression).toBeDefined();
            expect(typeof window.plugins.appsFlyer.logCrossPromotionImpression).toBe('function');
        });

        it("appsFlyer.logCrossPromotionAndOpenStore method", function () {
            expect(window.plugins.appsFlyer.logCrossPromotionAndOpenStore).toBeDefined();
            expect(typeof window.plugins.appsFlyer.logCrossPromotionAndOpenStore).toBe('function');
        });

        it("appsFlyer.handleOpenUrl method", function () {
            expect(window.plugins.appsFlyer.handleOpenUrl).toBeDefined();
            expect(typeof window.plugins.appsFlyer.handleOpenUrl).toBe('function');
        });

        it("appsFlyer.registerUninstall method", function () {
            expect(window.plugins.appsFlyer.registerUninstall).toBeDefined();
            expect(typeof window.plugins.appsFlyer.registerUninstall).toBe('function');
        });

        it("appsFlyer.getSdkVersion method", function () {
            expect(window.plugins.appsFlyer.getSdkVersion).toBeDefined();
            expect(typeof window.plugins.appsFlyer.getSdkVersion).toBe('function');
        });

        it("appsFlyer.setSharingFilterForPartners method", function () {
            expect(window.plugins.appsFlyer.setSharingFilterForPartners).toBeDefined();
            expect(typeof window.plugins.appsFlyer.setSharingFilterForPartners).toBe('function');
        });

        it("appsFlyer.setSharingFilter method", function () {
            expect(window.plugins.appsFlyer.setSharingFilter).toBeDefined();
            expect(typeof window.plugins.appsFlyer.setSharingFilter).toBe('function');
        });

        it("appsFlyer.setSharingFilterForAllPartners method", function () {
            expect(window.plugins.appsFlyer.setSharingFilterForAllPartners).toBeDefined();
            expect(typeof window.plugins.appsFlyer.setSharingFilterForAllPartners).toBe('function');
        });

        it("appsFlyer.validateAndLogInAppPurchase method", function () {
            expect(window.plugins.appsFlyer.validateAndLogInAppPurchase).toBeDefined();
            expect(typeof window.plugins.appsFlyer.validateAndLogInAppPurchase).toBe('function');
        });

        it("appsFlyer.setUseReceiptValidationSandbox method", function () {
            expect(window.plugins.appsFlyer.setUseReceiptValidationSandbox).toBeDefined();
            expect(typeof window.plugins.appsFlyer.setUseReceiptValidationSandbox).toBe('function');
        });

        it("appsFlyer.disableCollectASA method", function () {
            expect(window.plugins.appsFlyer.disableCollectASA).toBeDefined();
            expect(typeof window.plugins.appsFlyer.disableCollectASA).toBe('function');
        });

        it("appsFlyer.setDisableAdvertisingIdentifier method", function () {
            expect(window.plugins.appsFlyer.setDisableAdvertisingIdentifier).toBeDefined();
            expect(typeof window.plugins.appsFlyer.setDisableAdvertisingIdentifier).toBe('function');
        });

        it("appsFlyer.setOneLinkCustomDomains method", function () {
            expect(window.plugins.appsFlyer.setOneLinkCustomDomains).toBeDefined();
            expect(typeof window.plugins.appsFlyer.setOneLinkCustomDomains).toBe('function');
        });

        it("appsFlyer.enableFacebookDeferredApplinks method", function () {
            expect(window.plugins.appsFlyer.enableFacebookDeferredApplinks).toBeDefined();
            expect(typeof window.plugins.appsFlyer.enableFacebookDeferredApplinks).toBe('function');
        });

        it("appsFlyer.setPhoneNumber method", function () {
            expect(window.plugins.appsFlyer.setPhoneNumber).toBeDefined();
            expect(typeof window.plugins.appsFlyer.setPhoneNumber).toBe('function');
        });

        it("appsFlyer.setUserEmails method", function () {
            expect(window.plugins.appsFlyer.setUserEmails).toBeDefined();
            expect(typeof window.plugins.appsFlyer.setUserEmails).toBe('function');
        });

        it("appsFlyer.setHost method", function () {
            expect(window.plugins.appsFlyer.setHost).toBeDefined();
            expect(typeof window.plugins.appsFlyer.setHost).toBe('function');
        });

        it("appsFlyer.addPushNotificationDeepLinkPath method", function () {
            expect(window.plugins.appsFlyer.addPushNotificationDeepLinkPath).toBeDefined();
            expect(typeof window.plugins.appsFlyer.addPushNotificationDeepLinkPath).toBe('function');
        });

        it("appsFlyer.setResolveDeepLinkURLs method", function () {
            expect(window.plugins.appsFlyer.setResolveDeepLinkURLs).toBeDefined();
            expect(typeof window.plugins.appsFlyer.setResolveDeepLinkURLs).toBe('function');
        });

        it("appsFlyer.disableSKAD method", function () {
            expect(window.plugins.appsFlyer.disableSKAD).toBeDefined();
            expect(typeof window.plugins.appsFlyer.disableSKAD).toBe('function');
        });

        it("appsFlyer.setCurrentDeviceLanguage method", function () {
            expect(window.plugins.appsFlyer.setCurrentDeviceLanguage).toBeDefined();
            expect(typeof window.plugins.appsFlyer.setCurrentDeviceLanguage).toBe('function');
        });

        it("appsFlyer.setAdditionalData method", function () {
            expect(window.plugins.appsFlyer.setAdditionalData).toBeDefined();
            expect(typeof window.plugins.appsFlyer.setAdditionalData).toBe('function');
        });

        it("appsFlyer.setPartnerData method", function () {
            expect(window.plugins.appsFlyer.setPartnerData).toBeDefined();
            expect(typeof window.plugins.appsFlyer.setPartnerData).toBe('function');
        });

        it("appsFlyer.sendPushNotificationData method", function () {
            expect(window.plugins.appsFlyer.sendPushNotificationData).toBeDefined();
            expect(typeof window.plugins.appsFlyer.sendPushNotificationData).toBe('function');
        });

        it("appsFlyer.setDisableNetworkData method", function () {
            expect(window.plugins.appsFlyer.setDisableNetworkData).toBeDefined();
            expect(typeof window.plugins.appsFlyer.setDisableNetworkData).toBe('function');
        });
    });


    describe("AppsFlyer -> initSdk", function () {


        //     /*
        // ##################   SUCCESS testing   ################################
        // */

        it("appsflyer.init success callback devKey and app id are defined", function (done) {
            var successCB = function (result) {
                expect(result).toBeDefined();
                expect(typeof result === "string").toBe(true);
                expect(result).toBe(AppsFlyerError.SUCCESS);
                done();
            };

            function errorCB(err) {
                expect(err).toBeDefined();
                expect(typeof err === "string").toBe(true);
                fail(done);
            }

            var options = {
                devKey: 'd3Ac9qPnrpXYZxfWmCdpwL',
                appId: '123456789',
            };
            window.plugins.appsFlyer.initSdk(options, successCB, errorCB);
        });


        it("appsflyer.init success callback devKey and AppId and isDebug is defined", function (done) {

            var successCB = function (result) {
                expect(result).toBeDefined();
                expect(typeof result === "string").toBe(true);
                expect(result).toBe(AppsFlyerError.SUCCESS);
                done();
            };

            function errorCB(err) {
                expect(err).toBeDefined();
                fail(done);
            }


            var options = {
                devKey: 'd3Ac9qPnrpXYZxfWmCdpwL',
                appId: '123456789',
                isDebug: false
            };
            window.plugins.appsFlyer.initSdk(options, successCB, errorCB);
        });

        it("appsflyer.init success callback devKey is defined in android", function (done) {

            //ios uses appId, this test will fail
            if (isIOS) {
                pending();
                return;
            }

            var successCB = function (result) {
                expect(result).toBeDefined();
                expect(typeof result === "string").toBe(true);
                expect(result).toBe(AppsFlyerError.SUCCESS);
                done();
                return;
            };


            function errorCB(err) {
                expect(err).toBeDefined();
                expect(typeof err === "string").toBe(true);
                fail(done);
                return;
            }


            var options = {
                devKey: 'd3Ac9qPnrpXYZxfWmCdpwL'
            };
            window.plugins.appsFlyer.initSdk(options, successCB, errorCB);
        });

        /*
        ##################   ERROR testing   ################################
        */
        it("appsflyer.init error callback devKey is undefined", function (done) {
            var successCB = function (result) {
                fail(done);
            };

            function errorCB(err) {
                expect(err).toBeDefined();
                expect(typeof err === "string").toBe(true);
                expect(err).toBe(AppsFlyerError.NO_DEVKEY_FOUND);
                done();
            }

            var options = {
                appId: '123456789'
            };
            window.plugins.appsFlyer.initSdk(options, successCB, errorCB);
        });

        it("appsflyer.init error callback devKey is Empty", function (done) {

            var successCB = function (result) {
                fail(done);
            };

            function errorCB(err) {
                expect(err).toBeDefined();
                expect(typeof err === "string").toBe(true);
                expect(err).toBe(AppsFlyerError.NO_DEVKEY_FOUND);
                done();
            }

            var options = {
                devKey: '',
                appId: '123456789'
            };
            window.plugins.appsFlyer.initSdk(options, successCB, errorCB);
        });


        it("appsflyer.init error callback devkey defined as Integer", function (done) {

            var successCB = function (result) {
                fail(done);
            };

            function errorCB(err) {
                expect(err).toBeDefined();
                expect(typeof err === "string").toBe(true);
                expect(err).toBe(AppsFlyerError.DEVKEY_NOT_VALID);
                done();
            }

            var options = {
                devKey: 123456123,
                appId: '123456789'
            };
            window.plugins.appsFlyer.initSdk(options, successCB, errorCB);
        });


        it("appsflyer.init error callback appId is undefined", function (done) {

            if (isAndroid) {
                done();
                return;
            }
            var successCB = function (result) {
                fail(done);
            };

            function errorCB(err) {
                expect(err).toBeDefined();
                expect(typeof err === "string").toBe(true);
                expect(err).toBe(AppsFlyerError.NO_APPID_FOUND);
                done();
            }

            var options = {
                devKey: 'd3Ac9qPnrpXYZxfWmCdpwL',
            };
            window.plugins.appsFlyer.initSdk(options, successCB, errorCB);
        });


        it("appsflyer.init error callback appId defined as Integer", function (done) {

            if (isAndroid) {
                done();
                return;
            }
            var successCB = function (result) {
                fail(done);
            };

            function errorCB(err) {
                expect(err).toBeDefined();
                expect(typeof err === "string").toBe(true);
                expect(err).toBe(AppsFlyerError.APPID_NOT_VALID);
                done();
            }

            var options = {
                devKey: 'd3Ac9qPnrpXYZxfWmCdpwL',
                appId: 123456789
            };
            window.plugins.appsFlyer.initSdk(options, successCB, errorCB);
        });


        it("appsflyer.init error callback appId and devkey are not defined iOS", function (done) {
            if (isAndroid) {
                done();
                return;
            }
            var successCB = function (result) {
                fail(done);
            };

            function errorCB(err) {
                expect(err).toBeDefined();
                expect(typeof err === "string").toBe(true);
                expect(err).toBe(AppsFlyerError.NO_DEVKEY_FOUND);
                done();
            }

            var options = {};
            window.plugins.appsFlyer.initSdk(options, successCB, errorCB);
        });
    });

};
exports.defineManualTests = function (contentEl, createActionButton) {
};
