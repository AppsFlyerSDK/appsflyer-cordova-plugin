#!/usr/bin/env node
'use strict';

// After `cordova prepare ios`, patches the generated AppDelegate.m so `simctl launch … -deepLinkURL "<url>"` (which doesn't call `application:openURL:options:`) still schedules that URL through AppsFlyerAttribution after a short delay, giving JS initSdk time to run first (mirrors appsflyer-flutter-plugin's AppDelegate.swift). Idempotent via AFQA_SIMCTL_DEEPLINK_REPLAY markers.

const fs = require('fs');
const path = require('path');

function walkFiles(dir, predicate) {
  const out = [];
  if (!fs.existsSync(dir)) return out;
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const ent of entries) {
    const full = path.join(dir, ent.name);
    if (ent.isDirectory()) {
      if (ent.name === 'Pods' || ent.name === 'build') continue;
      out.push(...walkFiles(full, predicate));
    } else if (predicate(full)) {
      out.push(full);
    }
  }
  return out;
}

// Reads the AppsFlyerAttribution forward declaration straight out of AppsFlyerX+AppController.m (see that file's header comment) instead of keeping an independent hand-written copy here.
function readForwardDeclFromAppController() {
  const appControllerPath = path.join(__dirname, '..', '..', 'src', 'ios', 'AppsFlyerX+AppController.m');
  const src = fs.readFileSync(appControllerPath, 'utf8');
  const match = src.match(/@interface AppsFlyerAttribution : NSObject[\s\S]*?\n@end/);
  if (!match) {
    throw new Error(
      `[afqa-ios-simctl-deeplink-replay] Could not find AppsFlyerAttribution forward declaration in ${appControllerPath}`
    );
  }
  return match[0];
}

function patchAppDelegateM(filePath) {
  let src = fs.readFileSync(filePath, 'utf8');
  const begin = '/* AFQA_SIMCTL_DEEPLINK_REPLAY_BEGIN */';
  const end = '/* AFQA_SIMCTL_DEEPLINK_REPLAY_END */';
  if (src.includes(begin)) {
    return false;
  }

  const forwardDecl = readForwardDeclFromAppController();
  if (!src.includes(forwardDecl)) {
    const anchor = '#import "MainViewController.h"';
    if (!src.includes(anchor)) {
      console.warn(
        '[afqa-ios-simctl-deeplink-replay] No #import "MainViewController.h" anchor; skipping:',
        filePath
      );
      return false;
    }
    src = src.replace(anchor, `${anchor}\n\n${forwardDecl}`);
  }

  const needle =
    '    return [super application:application didFinishLaunchingWithOptions:launchOptions];';
  if (!src.includes(needle)) {
    console.warn(
      '[afqa-ios-simctl-deeplink-replay] Unexpected AppDelegate.m (return [super …] not found); skipping:',
      filePath
    );
    return false;
  }

  const block = [
    '    ' + begin,
    '    {',
    '      NSArray<NSString *> *argv = [NSProcessInfo processInfo].arguments;',
    '      __block NSURL *afqaReplayUrl = nil;',
    '      for (NSUInteger afqa_i = 0; afqa_i + 1 < argv.count; afqa_i++) {',
    '        if ([argv[afqa_i] isEqualToString:@"-deepLinkURL"]) {',
    '          NSString *afqaRaw = argv[afqa_i + 1];',
    '          if (afqaRaw.length > 0) {',
    '            afqaReplayUrl = [NSURL URLWithString:afqaRaw];',
    '            if (afqaReplayUrl == nil) {',
    '              afqaReplayUrl = [NSURLComponents componentsWithString:afqaRaw].URL;',
    '            }',
    '          }',
    '          break;',
    '        }',
    '      }',
    '      if (afqaReplayUrl == nil) {',
    '        NSString *afqaDef = [[NSUserDefaults standardUserDefaults] stringForKey:@"deepLinkURL"];',
    '        if (afqaDef.length > 0) {',
    '          afqaReplayUrl = [NSURL URLWithString:afqaDef];',
    '        }',
    '      }',
    '      if (afqaReplayUrl != nil) {',
    '        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{',
    '          [[AppsFlyerAttribution shared] handleOpen:afqaReplayUrl options:@{}];',
    '        });',
    '      }',
    '    }',
    '    ' + end,
    '',
    needle
  ].join('\n');

  src = src.replace(needle, block);
  fs.writeFileSync(filePath, src, 'utf8');
  console.log('[afqa-ios-simctl-deeplink-replay] Patched', filePath);
  return true;
}

module.exports = function (context) {
  const projectRoot = context.opts.projectRoot || context.opts.cordova?.projectRoot;
  if (!projectRoot) {
    console.warn('[afqa-ios-simctl-deeplink-replay] Missing projectRoot; skipping.');
    return;
  }

  const iosRoot = path.join(projectRoot, 'platforms', 'ios');
  if (!fs.existsSync(iosRoot)) {
    return;
  }

  const delegates = walkFiles(
    iosRoot,
    (p) => path.basename(p) === 'AppDelegate.m'
  );

  if (delegates.length === 0) {
    console.warn(
      '[afqa-ios-simctl-deeplink-replay] No AppDelegate.m under platforms/ios — add ios platform first.'
    );
    return;
  }

  for (const f of delegates) {
    patchAppDelegateM(f);
  }
};
