'use strict';

app.controller('AppsFlyerCtrl', function (
        $scope,
        $rootScope,
        $timeout,
        AppsFlyerService)
{

    $scope.viewModel = {
        trackEventResponse: {status: "NA"},
        appsFlyerUID: "not called yet",
        initSdkResponse: "not initialized yet",
        gcmProjectIDResponse: "not initialized yet",
        initSdkResponse: "not initialized yet",
        trackLocation: []
    };

    function run() {

        console.log('start AppsFlyerCtrl: ' + $rootScope.isAndroid);

//        $scope.onInstallConversionDataCanceller = window.plugins.appsFlyer.onInstallConversionData(
//            (data) => {
//                console.log(data);
//                alert(JSON.stringify(data));
//            }
//        );

    }

    $scope.onClick = function (_data) {

        switch (_data.type) {
            case 'initSDK':
                initSdk();
                break;
            case 'trackEvent':
                trackEvent();
                break;
            case 'getAppsflyerUID':
                getAppsflyerUID();
                break;
            case 'trackLocation':
                trackLocation();
                break;
            case 'setGCMProjectID':
                setGCMProjectID();
                break;
            default:

                break;
        }
    };

    function setGCMProjectID() {
        var gcmProjectId = "565637785481";
          window.plugins.appsFlyer.setGCMProjectID(gcmProjectId);
          
          // we don't use callback for this method
          $scope.viewModel.gcmProjectIDResponse = "Success";
    }

    function getAppsflyerUID() {
        window.plugins.appsFlyer.getAppsFlyerUID(function (_id) {

            $timeout(function () {
                $scope.viewModel.appsFlyerUID = _id;
            }, 1);
        })
    }


    function initSdk() {
        var options = {
            devKey: 'WdpTVAcYwmxsaQ4WeTspmh',
            isDebug: true , // (optional, default - false)
            onInstallConversionDataListener: true
        };

        if (ionic.Platform.isIOS()) {
            options.appId = "1231267677";
        }


        if (ionic.Platform.isAndroid() || (options.appId !== null)) {
            console.log('AF-JS :: Initialised appsFlyer');
            window.plugins.appsFlyer.initSdk(options,
                    function successCB(_response) {
                        console.log(_response);
                       
                             alert(_response);
                        $timeout(function () {
                            $scope.viewModel.initSdkResponse = _response;
                        }, 1);


                    },
                    function errorCB(_error) {
                        $timeout(function () {
                            $scope.viewModel.initSdkResponse = _response;
                        }, 1);
                    }
            );
        }
    }


    function trackEvent() {
        var eventName = "af_add_to_cart";
        var eventValues = {
            "af_content_id": "id123",
            "af_currency": "USD",
            "af_revenue": "2"
        };

        window.plugins.appsFlyer.trackEvent(eventName, eventValues);

        $scope.viewModel.trackEventResponse = 'trackEvent - Success'; //TODO  
    }


    $scope.$on("ionicPlatformReady", function () {
        run();
    });

//    document.addEventListener('onInstallConversionData', function (e) {
//        var attributionData = (JSON.stringify(e.detail));
//        alert(attributionData);
//    }, false);
});