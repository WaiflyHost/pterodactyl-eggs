#!/usr/bin/env node
// Prints the newest published npm version whose own engines.node range is satisfied by the given
// Node.js major version - used by build.sh to pin a *compatible* npm in each nodejs:<version>
// image, instead of npm@latest (which can require a newer Node than an older NODE_VERSION has and
// leave that image with a broken npm).
//
// Usage: node resolve-npm-version.js <node-major> [path-to-cached-registry-metadata.json]

const https = require('https');
const fs = require('fs');
const semver = require('semver');

const nodeMajor = process.argv[2];
const cachePath = process.argv[3];
if (!nodeMajor) {
    console.error('usage: resolve-npm-version.js <node-major> [cache.json]');
    process.exit(1);
}
// Any recent patch of the major works - engines ranges are virtually always plain ">=X" style,
// so the exact patch picked doesn't change which range it satisfies.
const probeVersion = `${nodeMajor}.999.0`;

function withMeta(meta) {
    const versions = Object.keys(meta.versions)
        .filter((v) => semver.valid(v) && semver.prerelease(v) === null)
        .sort(semver.rcompare);
    for (const v of versions) {
        const range = meta.versions[v].engines && meta.versions[v].engines.node;
        if (!range) continue;
        try {
            if (semver.satisfies(probeVersion, range)) {
                console.log(v);
                return;
            }
        } catch (e) { /* unparsable range, skip */ }
    }
    console.error(`no compatible npm version found for node ${nodeMajor}`);
    process.exit(1);
}

if (cachePath && fs.existsSync(cachePath)) {
    withMeta(JSON.parse(fs.readFileSync(cachePath, 'utf8')));
} else {
    https.get('https://registry.npmjs.org/npm', { headers: { Accept: 'application/vnd.npm.install-v1+json' } }, (res) => {
        let data = '';
        res.on('data', (c) => { data += c; });
        res.on('end', () => {
            if (cachePath) fs.writeFileSync(cachePath, data);
            withMeta(JSON.parse(data));
        });
    }).on('error', (e) => { console.error(e.message); process.exit(1); });
}
