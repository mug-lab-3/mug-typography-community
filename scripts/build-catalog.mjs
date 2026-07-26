// Regenerates catalog.json from whatever currently sits in gallery/.
//
// The simulator fetches this file directly over raw.githubusercontent.com
// (see platform/web/galleryCatalog.ts in the main repository), so it is
// committed rather than built at deploy time: a merged pull request is all it
// takes for a new work to appear, with no rebuild of the simulator.
//
// This is an index, not a bundle: it carries each work's metadata and the
// path to its script, never the script body. Inlining the sources would mean
// every visitor downloading every submission just to see the card grid, and
// would keep a second copy of each script in a file that is regenerated on
// every merge.
//
// Each work contributes <slug>.lua (the script), <slug>.json (the metadata
// the approve workflow derived from the submission) and its media. Entries are
// sorted newest-first by issue number so the gallery leads with recent
// submissions.

import { readdirSync, readFileSync, writeFileSync, existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const galleryDirectory = join(root, "gallery");

function findMediaPath(slug, extensions) {
  const match = extensions.find((extension) => existsSync(join(galleryDirectory, `${slug}${extension}`)));
  return match === undefined ? undefined : `gallery/${slug}${match}`;
}

// The trailing "-<issueNumber>" that buildSlug in validate-submission.mjs
// appends; absent or malformed slugs sort last rather than breaking the sort.
function issueNumberOf(slug) {
  const match = /-(\d+)$/.exec(slug);
  return match === null ? 0 : Number(match[1]);
}

const entries = readdirSync(galleryDirectory)
  .filter((name) => name.endsWith(".json"))
  .map((name) => name.slice(0, -".json".length))
  // A metadata file whose script is missing would index a card that fails to
  // open; fail the build instead of publishing it.
  .filter((slug) => {
    const hasScript = existsSync(join(galleryDirectory, `${slug}.lua`));
    if (!hasScript) {
      throw new Error(`gallery/${slug}.json has no matching ${slug}.lua`);
    }
    return hasScript;
  })
  .sort((first, second) => issueNumberOf(second) - issueNumberOf(first))
  .map((slug) => {
    const metadata = JSON.parse(readFileSync(join(galleryDirectory, `${slug}.json`), "utf8"));
    return {
      name: metadata.name ?? `${slug}.lua`,
      // Where the script lives, not the script itself; the simulator fetches
      // this only for a work the viewer actually opens.
      scriptPath: `gallery/${slug}.lua`,
      title: metadata.title ?? "",
      description: metadata.description ?? "",
      author: metadata.author ?? "",
      version: metadata.version ?? "",
      apiLevel: metadata.apiLevel,
      thumbnailPath: findMediaPath(slug, [".webp", ".png", ".jpg", ".jpeg"]),
      videoPath: findMediaPath(slug, [".webm"]),
      sourceUrl: metadata.sourceUrl,
    };
  });

writeFileSync(join(root, "catalog.json"), `${JSON.stringify(entries, null, 2)}\n`);
console.log(`catalog.json written with ${entries.length} work(s)`);
