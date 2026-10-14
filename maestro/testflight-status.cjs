// Read-only delivery receipt. Never prints credentials, JWTs or tester identities.
const { createPrivateKey, sign } = require('node:crypto');
const { writeFileSync } = require('node:fs');

async function main() {
  const buildNumber = process.argv[2];
  if (!/^\d+$/.test(buildNumber || '')) throw new Error('Provide a numeric iOS build number.');
  for (const name of ['ASC_KEY_ID', 'ASC_ISSUER_ID', 'ASC_API_KEY_BASE64']) {
    if (!process.env[name]) throw new Error(`Missing ${name}.`);
  }
  const encode = (value) => Buffer.from(JSON.stringify(value)).toString('base64url');
  const now = Math.floor(Date.now() / 1000);
  const payload = `${encode({ alg: 'ES256', kid: process.env.ASC_KEY_ID, typ: 'JWT' })}.${encode({ iss: process.env.ASC_ISSUER_ID, iat: now, exp: now + 600, aud: 'appstoreconnect-v1' })}`;
  const key = createPrivateKey(Buffer.from(process.env.ASC_API_KEY_BASE64, 'base64'));
  const jwt = `${payload}.${sign('sha256', Buffer.from(payload), { key, dsaEncoding: 'ieee-p1363' }).toString('base64url')}`;
  async function get(path, query = {}) {
    const url = new URL(path, 'https://api.appstoreconnect.apple.com');
    url.search = new URLSearchParams(query).toString();
    const response = await fetch(url, { method: 'GET', headers: { Authorization: `Bearer ${jwt}` }, signal: AbortSignal.timeout(30000) });
    if (!response.ok) {
      const body = await response.json().catch(() => ({}));
      const codes = (body.errors || []).map((error) => error.code).filter((code) => /^[A-Z0-9_]+$/.test(code)).join(', ');
      throw new Error(`Apple read failed on ${path}: HTTP ${response.status}${codes ? ` (${codes})` : ''}.`);
    }
    return response.json();
  }
  const apps = await get('/v1/apps', { 'filter[bundleId]': 'app.monologue.mobile', 'fields[apps]': 'bundleId', limit: '2' });
  if (apps.data.length !== 1) throw new Error('Expected one Monologue app.');
  const builds = await get('/v1/builds', { 'filter[app]': apps.data[0].id, 'filter[version]': buildNumber, include: 'buildBetaDetail,preReleaseVersion', limit: '10' });
  const included = new Map((builds.included || []).map((item) => [item.id, item]));
  const results = [];
  for (const build of builds.data) {
    const version = included.get(build.relationships.preReleaseVersion?.data?.id)?.attributes;
    if (version?.platform !== 'IOS') continue;
    const detail = included.get(build.relationships.buildBetaDetail?.data?.id)?.attributes;
    const groups = await get(`/v1/builds/${build.id}/betaGroups`, { 'fields[betaGroups]': 'isInternalGroup', limit: '200' });
    const internalGroups = groups.data.filter((group) => group.attributes.isInternalGroup).length;
    const externalGroups = groups.data.length - internalGroups;
    results.push({ version: version.version, buildNumber: build.attributes.version, processingState: build.attributes.processingState, expired: build.attributes.expired,
      internalBuildState: detail?.internalBuildState, externalBuildState: detail?.externalBuildState,
      assignedInternalGroups: internalGroups, assignedExternalGroups: externalGroups,
      availableToInternalTesters: !build.attributes.expired && detail?.internalBuildState === 'IN_BETA_TESTING' && internalGroups > 0,
      availableToExternalTesters: !build.attributes.expired && detail?.externalBuildState === 'IN_BETA_TESTING' && externalGroups > 0 });
  }
  const report = { status: 'READ_OK', checkedAt: new Date().toISOString(), requestedBuild: buildNumber, builds: results };
  writeFileSync('testflight-status.json', JSON.stringify(report, null, 2));
  console.log(JSON.stringify(report, null, 2));
}
main().catch((error) => {
  // Only our safe messages are printed; key parsing exceptions may contain input.
  const message = /^(Provide|Missing|Apple read failed|Expected)/.test(error.message) ? error.message : 'Unable to read TestFlight status.';
  console.error(message);
  // Readiness is separate from the UI gate. A permission error is explicitly
  // unverified, never an assertion that the build is available to testers.
  writeFileSync('testflight-status.json', JSON.stringify({ status: 'UNVERIFIED', requestedBuild: process.argv[2], checkedAt: new Date().toISOString(), reason: message }, null, 2));
  if (!/^Apple read failed.*HTTP (401|403)/.test(message)) process.exitCode = 1;
});
