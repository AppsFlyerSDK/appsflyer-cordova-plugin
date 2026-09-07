#!/usr/bin/env node
'use strict';
// ponytail: hand-rolled .env parser -- two keys don't justify a dotenv dependency.
// Runs via package.json's "prebuild"/"prestart" scripts (npm's automatic pre-hooks), so
// `npm run build`/`start` always regenerate this from the current .env first.
const fs = require('fs');
const path = require('path');

const envPath = path.join(__dirname, '..', '.env');
const outPath = path.join(__dirname, '..', 'src', 'app', 'af-config.ts');

let raw;
try {
  raw = fs.readFileSync(envPath, 'utf8');
} catch (err) {
  console.error(`[gen-af-config] Missing ${envPath} -- copy .env.example to .env and fill in DEV_KEY/APP_ID.`);
  process.exit(1);
}

const env = {};
for (const line of raw.split('\n')) {
  const match = line.match(/^\s*([\w.]+)\s*=\s*(.*?)\s*$/);
  if (!match) continue;
  env[match[1]] = match[2].replace(/^["']|["']$/g, '');
}

const { DEV_KEY, APP_ID } = env;
if (!DEV_KEY || !APP_ID) {
  console.error(`[gen-af-config] DEV_KEY/APP_ID missing from ${envPath} -- see .env.example.`);
  process.exit(1);
}

fs.writeFileSync(outPath, `export const AF_CONFIG = ${JSON.stringify({ devKey: DEV_KEY, appId: APP_ID })};\n`);
console.log(`[gen-af-config] wrote ${outPath}`);
