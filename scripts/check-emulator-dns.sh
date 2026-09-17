#!/usr/bin/env bash
# Connectivity precheck via DNS (UDP), NOT ping (ICMP). The Android emulator on Linux
# uses QEMU slirp NAT; ICMP echo often fails on hosted runners even when HTTPS works.
set -euo pipefail

adb shell 'getprop net.dns1; getprop net.dns2' || true
adb shell 'nslookup oyoxfj.conversions.appsflyersdk.com 2>&1 | head -5' || {
  sleep 10
  adb shell 'nslookup oyoxfj.conversions.appsflyersdk.com 2>&1 | head -5'
} || {
  echo "::error::Emulator DNS cannot resolve AppsFlyer hosts"
  exit 1
}
