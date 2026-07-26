// Regenerates catalog.json from whatever currently sits in gallery/.
//
// The simulator fetches this file directly over raw.githubusercontent.com
// (see platform/web/galleryCatalog.ts in the main repository), so it is
// committed rather than built at deploy time: a merged pull request is all it
// takes for a new entry to appear, with no rebuild of the simulator.
//
// This is an index, not a bundle: it carries each entry's metadata and the
// path to its script, never the script body. Inlining the sources would mean
// every visitor downloading every submission just to see the card grid, and
// would keep a second copy of each script in a file that is regenerated on
// every merge.
//
// Each entry contributes <slug>.lua (the script), <slug>.json (the metadata
// the approve workflow derived from the submission) and its media. Entries are
// sorted newest-first by issue number so the gallery leads with recent
// submissions.

import { readdirSync, readFileSync, writeFileSync, existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const galleryDirectory = join(root, "gallery");

const kScriptFileName = "script.lua";
const kVideoFileName = "preview.webm";
const kMetadataFileName = "metadata.json";
const kThumbnailExtensions = [".webp", ".png", ".jpg", ".jpeg"];

function findEntryFile(entryPath, fileNames) {
  const match = fileNames.find((fileName) => existsSync(join(galleryDirectory, entryPath, fileName)));
  return match === undefined ? undefined : `gallery/${entryPath}/${match}`;
}

function listDirectories(directoryPath) {
  return existsSync(directoryPath)
    ? readdirSync(directoryPath, { withFileTypes: true })
        .filter((entry) => entry.isDirectory())
        .map((entry) => entry.name)
        .sort()
    : [];
}

// gallery/<author>/<title-slug>/, so every entry is addressed by who made it
// and what they called it. Both levels are walked rather than assumed, since
// an author directory may hold any number of entries.
const entryPaths = listDirectories(galleryDirectory).flatMap((author) =>
  listDirectories(join(galleryDirectory, author)).map((title) => `${author}/${title}`),
);

const entries = entryPaths
  // An entry directory without its script would index a card that fails to
  // open; fail the build instead of publishing it.
  .map((entryPath) => {
    if (!existsSync(join(galleryDirectory, entryPath, kScriptFileName))) {
      throw new Error(`gallery/${entryPath} has no ${kScriptFileName}`);
    }
    const metadata = JSON.parse(
      readFileSync(join(galleryDirectory, entryPath, kMetadataFileName), "utf8"),
    );
    return {
      name: `${entryPath.split("/")[1]}.lua`,
      // Where the script lives, not the script itself; the simulator fetches
      // this only for an entry the viewer actually opens.
      scriptPath: `gallery/${entryPath}/${kScriptFileName}`,
      title: metadata.title ?? "",
      description: metadata.description ?? "",
      author: metadata.author ?? "",
      version: metadata.version ?? "",
      apiLevel: metadata.apiLevel,
      thumbnailPath: findEntryFile(
        entryPath,
        kThumbnailExtensions.map((extension) => `thumbnail${extension}`),
      ),
      videoPath: findEntryFile(entryPath, [kVideoFileName]),
      sourceUrl: metadata.sourceUrl,
      publishedAt: metadata.publishedAt,
    };
  })
  // Newest first, so the gallery leads with recent submissions. Entries
  // predating publishedAt sort last rather than breaking the comparison.
  .sort((first, second) => (second.publishedAt ?? "").localeCompare(first.publishedAt ?? ""));

writeFileSync(join(root, "catalog.json"), `${JSON.stringify(entries, null, 2)}\n`);
console.log(`catalog.json written with ${entries.length} entr${entries.length === 1 ? "y" : "ies"}`);
