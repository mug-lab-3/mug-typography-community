// Regenerates catalog.json from whatever currently sits in samples/.
//
// The simulator fetches this file directly over raw.githubusercontent.com
// (see platform/web/communityCatalog.ts in the main repository), so it is
// committed rather than built at deploy time: a merged pull request is all it
// takes for a new sample to appear, with no rebuild of the simulator.
//
// Each sample contributes <slug>.lua (the script), <slug>.json (the metadata
// the approve workflow derived from the submission) and its media. Entries are
// sorted newest-first by issue number so the sample browser leads with recent
// submissions.

import { readdirSync, readFileSync, writeFileSync, existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const samplesDirectory = join(root, "samples");

function findMediaPath(slug, extensions) {
  const match = extensions.find((extension) => existsSync(join(samplesDirectory, `${slug}${extension}`)));
  return match === undefined ? undefined : `samples/${slug}${match}`;
}

// The trailing "-<issueNumber>" that buildSlug in validate-submission.mjs
// appends; absent or malformed slugs sort last rather than breaking the sort.
function issueNumberOf(slug) {
  const match = /-(\d+)$/.exec(slug);
  return match === null ? 0 : Number(match[1]);
}

const entries = readdirSync(samplesDirectory)
  .filter((name) => name.endsWith(".json"))
  .map((name) => name.slice(0, -".json".length))
  .sort((first, second) => issueNumberOf(second) - issueNumberOf(first))
  .map((slug) => {
    const metadata = JSON.parse(readFileSync(join(samplesDirectory, `${slug}.json`), "utf8"));
    return {
      name: metadata.name ?? `${slug}.lua`,
      source: readFileSync(join(samplesDirectory, `${slug}.lua`), "utf8"),
      title: metadata.title ?? "",
      description: metadata.description ?? "",
      author: metadata.author ?? "",
      version: metadata.version ?? "",
      apiLevel: metadata.apiLevel,
      thumbnailPath: findMediaPath(slug, [".png", ".jpg", ".jpeg"]),
      videoPath: findMediaPath(slug, [".webm"]),
      sourceUrl: metadata.sourceUrl,
    };
  });

writeFileSync(join(root, "catalog.json"), `${JSON.stringify(entries, null, 2)}\n`);
console.log(`catalog.json written with ${entries.length} sample(s)`);
