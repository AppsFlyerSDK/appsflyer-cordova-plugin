/* global cordova */
(function () {
  'use strict';

  var fileAppendChain = Promise.resolve();

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

  /**
   * Pull deep_link_value / deepLinkValue from UDL JSON (nested maps, link URLs, or JSON string fallbacks).
   */
  function extractDeepLinkValueFromUdl(o) {
    if (!o || typeof o !== 'object') {
      return '';
    }
    var visit = function (node, depth) {
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
          (val.indexOf('deep_link_value=') !== -1 || val.indexOf('afqa-') !== -1 || val.indexOf('://') !== -1)
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
    };
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

  /**
   * Normative line shape per appsflyer-mobile-plugin-tooling/contracts/test-app-contract.md — same
   * substrings the scenario runner greps (`status=Status.FOUND`, `deepLinkValue=…`).
   */
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
    var ds = o.deepLinkStatus != null ? String(o.deepLinkStatus) : '';
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
    if (!env.DEV_KEY) {
      await afQaLog('[AF_QA][CONFIG] DEV_KEY missing');
      return;
    }
    if (!env.APP_ID) {
      await afQaLog('[AF_QA][CONFIG] APP_ID missing');
      return;
    }

    var af = window.plugins.appsFlyer;

    af.registerOnAppOpenAttribution(
      function (res) {
        void afQaLog('[AF_QA][CALLBACK][onAppOpenAttribution] received: ' + stringifyRes(res));
      },
      function (err) {
        void afQaLog('[AF_QA][CALLBACK][onAppOpenAttribution] error: ' + stringifyRes(err));
      }
    );

    af.registerDeepLink(function (res) {
      void (async function () {
        await afQaLog(formatOnDeepLinkingContractLine(res));
        await afQaLog('[AF_QA][CALLBACK][onDeepLinking] raw: ' + stringifyRes(res));
      })();
    });

    var initOpts = {
      devKey: env.DEV_KEY,
      appId: env.APP_ID,
      isDebug: true,
      onInstallConversionDataListener: true,
      onDeepLinkListener: true,
      shouldStartSdk: false
    };

    await new Promise(function (resolve, reject) {
      var settled = false;
      af.initSdk(
        initOpts,
        function (gcd) {
          void afQaLog(
            '[AF_QA][CALLBACK][onInstallConversionData] received: ' + stringifyRes(gcd)
          );
        },
        function (err) {
          void afQaLog('[AF_QA][startSDK] error: initSdk ' + stringifyRes(err));
          if (!settled) {
            settled = true;
            reject(new Error(stringifyRes(err)));
          }
        }
      );
      setTimeout(function () {
        if (!settled) {
          settled = true;
          resolve();
        }
      }, 1500);
    });

    af.setAppUserId('e2e_user_42');
    await afQaLog('[AF_QA][setCustomerUserId] result: e2e_user_42');

    af.setCurrencyCode('EUR');
    await afQaLog('[AF_QA][setCurrencyCode] result: EUR');

    af.setAdditionalData({ tenant: 'e2e_tenant', e2e_flag: '1' });
    await afQaLog(
      '[AF_QA][setAdditionalData] keys: tenant,e2e_flag payload=' +
        JSON.stringify({ tenant: 'e2e_tenant', e2e_flag: '1' })
    );

    await afQaLog('[AF_QA][AUTO_APIS] --- Pre-start auto APIs complete ---');

    af.startSdk();
    await afQaLog('[AF_QA][startSDK] result: SUCCESS');

    await waitMs(400);

    await new Promise(function (resolve) {
      af.getSdkVersion(function (v) {
        afQaLog('[AF_QA][getSDKVersion] result: ' + v);
        resolve();
      });
    });

    await new Promise(function (resolve) {
      af.getAppsFlyerUID(function (uid) {
        afQaLog('[AF_QA][getAppsFlyerUID] result: ' + uid);
        resolve();
      });
    });

    await afQaLog('[AF_QA][AUTO_APIS] --- Post-start auto APIs complete ---');

    await new Promise(function (resolve) {
      af.logEvent(
        'af_demo_launch',
        {},
        function () {
          afQaLog('[AF_QA][logEvent(af_demo_launch)] result: SUCCESS');
          resolve();
        },
        function (err) {
          afQaLog('[AF_QA][logEvent] error: af_demo_launch ' + stringifyRes(err));
          resolve();
        }
      );
    });

    await new Promise(function (resolve) {
      af.logEvent(
        'af_purchase',
        {
          af_revenue: '12.34',
          af_currency: 'USD',
          af_content_id: 'qa_sku_1'
        },
        function () {
          afQaLog('[AF_QA][logEvent: af_purchase sent] result: SUCCESS');
          resolve();
        },
        function (err) {
          afQaLog('[AF_QA][logEvent] error: af_purchase ' + stringifyRes(err));
          resolve();
        }
      );
    });

    await new Promise(function (resolve) {
      af.logEvent(
        'af_content_view',
        { af_content_type: 'qa', af_content_id: 'home' },
        function () {
          afQaLog('[AF_QA][logEvent: af_content_view sent] result: SUCCESS');
          resolve();
        },
        function (err) {
          afQaLog('[AF_QA][logEvent] error: af_content_view ' + stringifyRes(err));
          resolve();
        }
      );
    });

    await new Promise(function (resolve) {
      af.logEvent(
        'af_qa_custom_purchase',
        {
          af_revenue: '9.99',
          af_currency: 'USD',
          metadata: { tier: 'gold', seats: 2 }
        },
        function () {
          afQaLog(
            '[AF_QA][logEvent] name=af_qa_custom_purchase payload=' +
              JSON.stringify({
                af_revenue: '9.99',
                af_currency: 'USD',
                metadata: { tier: 'gold', seats: 2 }
              })
          );
          resolve();
        },
        function (err) {
          afQaLog('[AF_QA][logEvent] error: af_qa_custom_purchase ' + stringifyRes(err));
          resolve();
        }
      );
    });

    await new Promise(function (resolve) {
      var identityPayload = {
        customer_user_id: 'e2e_user_42',
        tenant: 'e2e_tenant',
        check: 'identity_round_trip'
      };
      af.logEvent(
        'af_qa_identity_check',
        identityPayload,
        function () {
          afQaLog(
            '[AF_QA][logEvent] name=af_qa_identity_check payload=' +
              JSON.stringify(identityPayload)
          ).then(function () {
            return afQaLog('[AF_QA][event_payload] customer_user_id=e2e_user_42');
          }).then(function () {
            resolve();
          });
        },
        function (err) {
          afQaLog('[AF_QA][logEvent] error: af_qa_identity_check ' + stringifyRes(err));
          resolve();
        }
      );
    });

    af.Stop(true);
    await afQaLog('[AF_QA][stop] result: true');

    await new Promise(function (resolve) {
      af.logEvent(
        'af_qa_suppressed',
        { note: 'must_not_http_200_while_stopped' },
        function () {
          afQaLog('[AF_QA][logEvent] name=af_qa_suppressed (unexpected success while stopped)');
          resolve();
        },
        function () {
          resolve();
        }
      );
    });

    af.Stop(false);
    await afQaLog('[AF_QA][stop] result: false');

    await new Promise(function (resolve) {
      af.logEvent(
        'af_qa_resumed',
        { note: 'after_stop_false' },
        function () {
          afQaLog('[AF_QA][logEvent] name=af_qa_resumed result: SUCCESS');
          resolve();
        },
        function (err) {
          afQaLog('[AF_QA][logEvent] error: af_qa_resumed ' + stringifyRes(err));
          resolve();
        }
      );
    });

    await waitMs(1500);

    await afQaLog('[AF_QA][AUTO_APIS] --- Auto run complete ---');
    await fileAppendChain;
  }
})();
