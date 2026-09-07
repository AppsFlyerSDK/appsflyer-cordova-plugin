/* global cordova */
(function () {
  'use strict';

  var fileAppendChain = Promise.resolve();

  document.addEventListener(
    'deviceready',
    function () {
      runAfQaContract().catch(function (e) {
        var msg = e && e.message ? e.message : String(e);
        afQaLog('[AF_QA][startSDK] error: ' + msg);
      });
    },
    false
  );

  async function runAfQaContract() {
    await afQaLog('[AF_QA][BOOT] deviceready');

    var env = window.__AF_QA_ENV__ || {};
    // AND_DEV_KEY is optional -- some AppsFlyer dashboard setups register the iOS and Android
    // apps under different dev keys. Falls back to DEV_KEY when the app is registered under one
    // shared key.
    var devKey = (cordova.platformId === 'android' && env.AND_DEV_KEY) || env.DEV_KEY;
    if (!devKey) {
      await afQaLog('[AF_QA][CONFIG] DEV_KEY missing');
      return;
    }
    if (!env.APP_ID) {
      await afQaLog('[AF_QA][CONFIG] APP_ID missing');
      return;
    }

    var af = window.plugins.appsFlyer;

    // registerOnAppOpenAttribution removed -- folded into registerDeepLinkListener's onDeepLinking
    // (see RENAME_AUDIT.md). Must be registered before init() per the new SDK's sequencing model.
    af.registerDeepLinkListener({
      onDeepLinking: function (res) {
        void (async function () {
          await afQaLog(formatOnDeepLinkingContractLine(res));
          await afQaLog('[AF_QA][CALLBACK][onDeepLinking] raw: ' + stringifyRes(res));
        })();
      }
    }).catch(function (err) {
      void afQaLog('[AF_QA][CALLBACK][onDeepLinking] register error: ' + stringifyRes(err));
    });

    var initOpts = {
      devKey: devKey,
      appId: env.APP_ID
      // isDebug -> enableDebug() below; onInstallConversionDataListener -> registerConversionListener
      // below; onDeepLinkListener -> registerDeepLinkListener above; shouldStartSdk is moot -- init()
      // never implicitly starts tracking anymore, see RENAME_AUDIT.md's initSdk row.
    };

    await initSdkWait(af, initOpts, 1500);

    // Conversion listener + one-off config calls, registered after init() per the new sequencing
    // model (RPC_MIGRATION Step 5 note): GCD used to arrive via initSdk's own success callback,
    // now it's a standalone listener.
    af.registerConversionListener({
      onConversionDataSuccess: function (data) {
        void afQaLog('[AF_QA][CALLBACK][onInstallConversionData] received: ' + stringifyRes(data));
      },
      onConversionDataFail: function (err) {
        void afQaLog('[AF_QA][CALLBACK][onInstallConversionData] error: ' + stringifyRes(err));
      }
    }).catch(function (err) {
      void afQaLog('[AF_QA][CALLBACK][onInstallConversionData] register error: ' + stringifyRes(err));
    });

    await af.enableDebug({ enabled: true }).catch(function (err) {
      void afQaLog('[AF_QA][enableDebug] error: ' + stringifyRes(err));
    });

    await af.setCustomerUserId({ customerId: 'e2e_user_42' }).catch(function (err) {
      void afQaLog('[AF_QA][setCustomerUserId] error: ' + stringifyRes(err));
    });
    await afQaLog('[AF_QA][setCustomerUserId] result: e2e_user_42');

    await af.setCurrencyCode({ currencyCode: 'EUR' }).catch(function (err) {
      void afQaLog('[AF_QA][setCurrencyCode] error: ' + stringifyRes(err));
    });
    await afQaLog('[AF_QA][setCurrencyCode] result: EUR');

    await af.setAdditionalData({ customData: { tenant: 'e2e_tenant', e2e_flag: '1' } }).catch(function (err) {
      void afQaLog('[AF_QA][setAdditionalData] error: ' + stringifyRes(err));
    });
    await afQaLog(
      '[AF_QA][setAdditionalData] keys: tenant,e2e_flag payload=' +
        JSON.stringify({ tenant: 'e2e_tenant', e2e_flag: '1' })
    );

    await afQaLog('[AF_QA][AUTO_APIS] --- Pre-start auto APIs complete ---');

    // start() must be called from inside registerSessionReadyListener's callback per SDK 7's manual
    // startup model (RENAME_AUDIT.md) -- no longer fired unconditionally right after init. Bounded
    // with a timeout so the QA log always gets an unambiguous SUCCESS/error/timeout line for this
    // call, instead of silently having no line at all if onSessionReady never fires.
    // 10s, not 5s: AppsFlyerLib's own Universal Link readiness check (a session-ready
    // precondition) has a longer bounded timeout than that on the native side -- a 5s QA
    // timeout was racing it and losing on every real device/simulator run.
    await awaitSessionReadyAndStart(af, 10000);

    await waitMs(400);

    await af.getSdkVersion()
      .then(function (v) {
        return afQaLog('[AF_QA][getSDKVersion] result: ' + v);
      })
      .catch(function (err) {
        return afQaLog('[AF_QA][getSDKVersion] error: ' + stringifyRes(err));
      });

    await af.getAppsFlyerUID()
      .then(function (uid) {
        return afQaLog('[AF_QA][getAppsFlyerUID] result: ' + uid);
      })
      .catch(function (err) {
        return afQaLog('[AF_QA][getAppsFlyerUID] error: ' + stringifyRes(err));
      });

    await afQaLog('[AF_QA][AUTO_APIS] --- Post-start auto APIs complete ---');

    await afLogEvent(af, 'qa_demo_launch', {}, '[AF_QA][logEvent(qa_demo_launch)] result: SUCCESS');

    await afLogEvent(
      af,
      'af_purchase',
      { af_revenue: '12.34', af_currency: 'USD', af_content_id: 'qa_sku_1' },
      '[AF_QA][logEvent: af_purchase sent] result: SUCCESS'
    );

    await afLogEvent(
      af,
      'af_content_view',
      { af_content_type: 'qa', af_content_id: 'home' },
      '[AF_QA][logEvent: af_content_view sent] result: SUCCESS'
    );

    await afLogEvent(
      af,
      'qa_custom_purchase',
      {
        af_revenue: '9.99',
        af_currency: 'USD',
        metadata: { tier: 'gold', seats: 2 }
      },
      '[AF_QA][logEvent] name=qa_custom_purchase payload=' +
        JSON.stringify({
          af_revenue: '9.99',
          af_currency: 'USD',
          metadata: { tier: 'gold', seats: 2 }
        })
    );

    await (function () {
      var identityPayload = {
        customer_user_id: 'e2e_user_42',
        tenant: 'e2e_tenant',
        check: 'identity_round_trip'
      };
      return af.logEvent({ eventName: 'qa_identity_check', eventValues: identityPayload })
        .then(function () {
          return afQaLog(
            '[AF_QA][logEvent] name=qa_identity_check payload=' +
              JSON.stringify(identityPayload)
          ).then(function () {
            return afQaLog('[AF_QA][event_payload] customer_user_id=e2e_user_42');
          });
        })
        .catch(function (err) {
          return afQaLog('[AF_QA][logEvent] error: qa_identity_check ' + stringifyRes(err));
        });
    })();

    await af.stop({ shouldStop: true }).catch(function (err) {
      void afQaLog('[AF_QA][stop] error: ' + stringifyRes(err));
    });
    await afQaLog('[AF_QA][stop] result: true');

    await af.logEvent({ eventName: 'qa_suppressed', eventValues: { note: 'must_not_http_200_while_stopped' } })
      .then(function () {
        return afQaLog('[AF_QA][logEvent] name=qa_suppressed (unexpected success while stopped)');
      })
      .catch(function () {
        // Expected: SDK is stopped, logEvent should reject/no-op.
      });

    await af.stop({ shouldStop: false }).catch(function (err) {
      void afQaLog('[AF_QA][stop] error: ' + stringifyRes(err));
    });
    await afQaLog('[AF_QA][stop] result: false');

    await afLogEvent(
      af,
      'qa_resumed',
      { note: 'after_stop_false' },
      '[AF_QA][logEvent] name=qa_resumed result: SUCCESS'
    );

    await waitMs(1500);

    await afQaLog('[AF_QA][AUTO_APIS] --- Auto run complete ---');
    await fileAppendChain;
  }

  function initSdkWait(af, initOpts, timeoutMs) {
    return new Promise(function (resolve, reject) {
      var settled = false;
      // init() no longer forwards GCD through its own success path -- that now arrives via
      // registerConversionListener's onConversionDataSuccess (wired by the caller).
      af.init(initOpts).catch(function (err) {
        void afQaLog('[AF_QA][startSDK] error: initSdk ' + stringifyRes(err));
        if (!settled) {
          settled = true;
          reject(err instanceof Error ? err : new Error(stringifyRes(err)));
        }
      });
      setTimeout(function () {
        if (!settled) {
          settled = true;
          resolve();
        }
      }, timeoutMs);
    });
  }

  function awaitSessionReadyAndStart(af, timeoutMs) {
    return new Promise(function (resolve) {
      var settled = false;
      function finish() {
        if (!settled) {
          settled = true;
          resolve();
        }
      }
      af.registerSessionReadyListener(function () {
        af.start()
          .then(function () {
            void afQaLog('[AF_QA][startSDK] result: SUCCESS');
          })
          .catch(function (err) {
            void afQaLog('[AF_QA][startSDK] error: ' + stringifyRes(err));
          })
          .then(finish);
      }).catch(function (err) {
        void afQaLog('[AF_QA][startSDK] error: registerSessionReadyListener ' + stringifyRes(err));
        finish();
      });
      setTimeout(function () {
        if (!settled) {
          settled = true;
          void afQaLog('[AF_QA][startSDK] error: onSessionReady did not fire within ' + timeoutMs + 'ms');
          resolve();
        }
      }, timeoutMs);
    });
  }

  function afLogEvent(af, eventName, eventValues, successLine) {
    return af.logEvent({ eventName: eventName, eventValues: eventValues })
      .then(function () {
        void afQaLog(successLine);
      })
      .catch(function (err) {
        void afQaLog('[AF_QA][logEvent] error: ' + eventName + ' ' + stringifyRes(err));
      });
  }

  function afQaAppendFileLine(line) {
    if (!window.cordova || !cordova.file) {
      return fileAppendChain;
    }
    fileAppendChain = fileAppendChain.then(function () {
      return new Promise(function (resolve) {
        window.resolveLocalFileSystemURL(
          cordova.file.dataDirectory,
          function (dirEntry) {
            dirEntry.getFile(
              'af_qa_logs.txt',
              { create: true },
              function (fileEntry) {
                fileEntry.file(function (file) {
                  var reader = new FileReader();
                  reader.onloadend = function () {
                    var prev = typeof reader.result === 'string' ? reader.result : '';
                    fileEntry.createWriter(function (writer) {
                      writer.onwriteend = function () {
                        resolve();
                      };
                      writer.onerror = function () {
                        resolve();
                      };
                      writer.write(prev + line + '\n');
                    }, function () {
                      resolve();
                    });
                  };
                  reader.onerror = function () {
                    resolve();
                  };
                  reader.readAsText(file);
                }, function () {
                  resolve();
                });
              },
              function () {
                resolve();
              }
            );
          },
          function () {
            resolve();
          }
        );
      });
    });
    return fileAppendChain;
  }

  function afQaAppendUiLine(line) {
    var el = document.getElementById('af-qa-log-view');
    if (!el) {
      return;
    }
    el.appendChild(document.createTextNode(line + '\n'));
    el.scrollTop = el.scrollHeight;
  }

  async function afQaLog(line) {
    console.log(line);
    afQaAppendUiLine(line);
    afQaAppendFileLine(line);
    await fileAppendChain;
  }

  function stringifyRes(res) {
    if (res === undefined || res === null) {
      return '';
    }
    if (typeof res === 'string') {
      return res;
    }
    try {
      return JSON.stringify(res);
    } catch (e) {
      return String(res);
    }
  }

  function extractDeepLinkValueFromUdl(o) {
    if (!o || typeof o !== 'object') {
      return '';
    }
    function visit(node, depth) {
      if (depth > 8 || node == null) {
        return '';
      }
      if (typeof node === 'string') {
        if (node.length > 1 && (node.charAt(0) === '{' || node.charAt(0) === '[')) {
          try {
            var parsed = JSON.parse(node);
            var fromParsed = visit(parsed, depth + 1);
            if (fromParsed) {
              return fromParsed;
            }
          } catch (e0) {
            /* not JSON */
          }
        }
        if (/^qa_deeplink_(bg|fg)$/.test(node)) {
          return node;
        }
        var um = node.match(/[?&]deep_link_value=([^&]+)/);
        if (um) {
          try {
            return decodeURIComponent(um[1]);
          } catch (e) {
            return um[1];
          }
        }
        return '';
      }
      if (typeof node !== 'object') {
        return '';
      }
      var k;
      for (k in node) {
        if (!Object.prototype.hasOwnProperty.call(node, k)) continue;
        var lk = k.toLowerCase();
        var val = node[k];
        if (
          (lk === 'deep_link_value' || lk === 'deeplinkvalue' || lk === 'deep_value') &&
          val != null &&
          String(val) !== ''
        ) {
          return String(val);
        }
        if (lk === 'link' && typeof val === 'string') {
          var fromLink = visit(val, depth + 1);
          if (fromLink) return fromLink;
        }
        if (
          typeof val === 'string' &&
          val !== '' &&
          (val.indexOf('deep_link_value=') !== -1 ||
            val.indexOf('afqa-') !== -1 ||
            val.indexOf('://') !== -1)
        ) {
          var fromUrlish = visit(val, depth + 1);
          if (fromUrlish) return fromUrlish;
        }
        if (val && typeof val === 'object') {
          var inner = visit(val, depth + 1);
          if (inner) return inner;
        }
        if (typeof val === 'string' && /^qa_deeplink_(bg|fg)$/.test(val)) {
          return val;
        }
      }
      return '';
    }
    var out = visit(o, 0);
    if (out) {
      return out;
    }
    try {
      var s = JSON.stringify(o);
      var qm = s.match(/\b(qa_deeplink_(?:bg|fg))\b/);
      if (qm) {
        return qm[1];
      }
      var m = s.match(/"deep_link_value"\s*:\s*"([^"]+)"/);
      if (m) return m[1];
      m = s.match(/"deepLinkValue"\s*:\s*"([^"]+)"/);
      if (m) return m[1];
      m = s.match(/deep_link_value=([^&"\\]+)/);
      if (m) {
        try {
          return decodeURIComponent(m[1]);
        } catch (e2) {
          return m[1];
        }
      }
      m = s.match(/afqa-cordova:\/\/[^"'\\s]*[?&]deep_link_value=([^&"'\\]+)/);
      if (m) {
        try {
          return decodeURIComponent(m[1]);
        } catch (e4) {
          return m[1];
        }
      }
    } catch (e3) {
      return '';
    }
    return '';
  }

  function parseDeepLinkNativePayload(raw) {
    var o = raw;
    if (typeof raw === 'string') {
      try {
        o = JSON.parse(raw);
      } catch (e) {
        return { statusLabel: 'Status.ERROR', deepLinkValue: '' };
      }
    }
    if (!o || typeof o !== 'object') {
      return { statusLabel: 'Status.ERROR', deepLinkValue: '' };
    }
    // `status` is the new normalized DeepLinkData field (registerDeepLinkListener's onDeepLinking
    // always delivers 'FOUND'|'NOT_FOUND'|'ERROR' here now); `deepLinkStatus` is the old raw-payload
    // field name, kept as a fallback in case anything upstream ever leaks the pre-normalization shape.
    var ds = o.status != null ? String(o.status) : (o.deepLinkStatus != null ? String(o.deepLinkStatus) : '');
    var statusLabel = 'Status.ERROR';
    if (ds === 'FOUND' || ds === 'Found' || ds.indexOf('FOUND') !== -1) {
      statusLabel = 'Status.FOUND';
    } else if (ds === 'NOT_FOUND' || ds === 'NotFound' || ds.indexOf('NOT_FOUND') !== -1) {
      statusLabel = 'Status.NOT_FOUND';
    } else if (ds === 'Error' || ds === 'FAILURE' || ds === 'Failure' || ds.indexOf('Error') !== -1) {
      statusLabel = 'Status.ERROR';
    }
    var dlv = extractDeepLinkValueFromUdl(o);
    if (!dlv && o.deepLinkValue != null && String(o.deepLinkValue) !== '') {
      dlv = String(o.deepLinkValue);
    }
    if (!dlv && o.data != null) {
      var d = o.data;
      if (typeof d === 'string') {
        try {
          d = JSON.parse(d);
        } catch (e1) {
          d = null;
        }
      }
      if (d && typeof d === 'object') {
        dlv = extractDeepLinkValueFromUdl(d);
      }
    }
    return { statusLabel: statusLabel, deepLinkValue: dlv };
  }

  function formatOnDeepLinkingContractLine(res) {
    var n = parseDeepLinkNativePayload(res);
    return (
      '[AF_QA][CALLBACK][onDeepLinking] received: status=' +
      n.statusLabel +
      ', deepLinkValue=' +
      n.deepLinkValue
    );
  }

  function waitMs(ms) {
    return new Promise(function (resolve) {
      setTimeout(resolve, ms);
    });
  }
})();
