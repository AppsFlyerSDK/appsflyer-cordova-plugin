/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
//
var handleOpenURL = function (url) {
	window.plugins.appsFlyer.handleOpenUrl(url);
};

// Success callback for init SDK
var handleSuccessInit = function (success) {
	console.log(success);
};
// Failure callback for init SDK
var handleFailureInit = function (failure) {
	console.log(failure);
};

var app = {
	// Application Constructor
	initialize: function () {
		this.bindEvents();
	},
	// Bind Event Listeners
	//
	// Bind any events that are required on startup. Common events are:
	// 'load', 'deviceready', 'offline', and 'online'.
	bindEvents: function () {
		document.addEventListener('deviceready', this.onDeviceReady, false);
	},
	// deviceready Event Handler
	//
	// The scope of 'this' is the event. In order to call the 'receivedEvent'
	// function, we must explicitly call 'app.receivedEvent(...);'
	//    onDeviceReady: function() {
	//        app.receivedEvent('deviceready');
	//    },
	//    // Update DOM on a Received Event
	//    receivedEvent: function(id) {
	//        var parentElement = document.getElementById(id);
	//        var listeningElement = parentElement.querySelector('.listening');
	//        var receivedElement = parentElement.querySelector('.received');
	//
	//        listeningElement.setAttribute('style', 'display:none;');
	//        receivedElement.setAttribute('style', 'display:block;');
	//
	//        console.log('Received Event: ' + id);
	//    }
};
document.addEventListener(
	'deviceready',
	function () {
		var options = {
			devKey: 'xxxxxxx',
			isDebug: true,
			onInstallConversionDataListener: true,
			waitForATTUserAuthorization: 10, //--> Here you set the time for the sdk to wait before launch
		};

		var userAgent = window.navigator.userAgent.toLowerCase();

		if (/iphone|ipad|ipod/.test(userAgent)) {
			options.appId = '741993991'; // your ios app id in app store
		}
		window.plugins.appsFlyer.initSdk(options, handleSuccessInit, handleFailureInit);

		var push = PushNotification.init({
			android: {
				senderID: '12345',
			},
			browser: {
				pushServiceURL: 'http://push.api.phonegap.com/v1/push',
			},
			ios: {
				alert: 'true',
				badge: 'true',
				sound: 'true',
			},
			windows: {},
		});
		//Device Token for iOS
		push.on('registration', function (data) {
			console.log('device token: ' + data.registrationId);
			window.plugins.appsFlyer.registerUninstall(data.registrationId);
		});
	},
	false
);
app.initialize();
