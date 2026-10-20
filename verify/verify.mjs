import { readFile } from 'node:fs/promises';
import { findArtifact, verifyFileDigest, verifyRelease } from 'packslip';

const [bundlePath, archivePath, archiveName, tag] = process.argv.slice(2);
if (!bundlePath || !archivePath || !archiveName || !tag) {
  console.error('usage: verify.mjs <bundle> <archive-path> <archive-name> <tag>');
  process.exit(2);
}

try {
  // The signer policy is ours, never taken from the bundle: aube's release
  // workflow in aubepkg/aube, signed through GitHub's OIDC issuer.
  const statement = await verifyRelease(await readFile(bundlePath, 'utf8'), {
    identity: (san) => san.startsWith('https://github.com/aubepkg/aube/.github/workflows/'),
    issuer: 'https://token.actions.githubusercontent.com',
    project: 'github.com/aubepkg/aube',
    tag,
  });
  await verifyFileDigest(archivePath, findArtifact(statement, archiveName));
  console.log(`Verified ${archiveName} against the signed packslip for ${tag}`);
} catch (err) {
  console.error(`::error::aube release verification failed: ${err.message}`);
  process.exit(1);
}
