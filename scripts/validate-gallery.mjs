// Validates one gallery submission issue and, on success, writes the files the
// approve workflow commits.
//
// Usage:
//   node scripts/validate-gallery.mjs <issue.json> [--emit <directory>]
//
// <issue.json> is the raw issue payload (`gh issue view --json`). Without
// --emit this only reports; with it, the extracted script and the downloaded
// media are written into <directory> ready to be committed.
//
// Every failure is collected rather than thrown at the first problem, so a
// submitter gets one comment listing everything to fix instead of discovering
// the limits one round trip at a time.

import { execFileSync } from "node:child_process";
import {
  existsSync,
  mkdirSync,
  readFileSync,
  readdirSync,
  renameSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { join } from "node:path";
import { extractScriptAttachment } from "./webmAttachment.mjs";

const kMaxVideoBytes = 8 * 1024 * 1024;
const kMaxVideoWidth = 1280;
const kMaxVideoHeight = 720;
const kMaxVideoSeconds = 15;

const kMaxThumbnailBytes = 500 * 1024;
const kMaxThumbnailWidth = 1280;
const kMaxThumbnailHeight = 720;

// Only GitHub's own attachment hosts are fetched. The issue body is
// attacker-controlled text, so an arbitrary URL here would turn this workflow
// into a request proxy for whatever the submitter names.
const kAllowedAssetHosts = ["github.com", "user-images.githubusercontent.com", "raw.githubusercontent.com"];

// GitHub rewrites uploads to extensionless URLs under
// /user-attachments/assets/<uuid>, so the file type cannot be read off the
// URL. Each field's expected type is established by ffprobe after download
// instead (validateVideo / validateThumbnail); the field the URL appeared in
// is what says which of the two it is meant to be.

class ValidationFailure extends Error {}

function fail(problems, message) {
  problems.push(message);
}

// Issue Forms render each field as a "### <label>" section, so the body is
// split on those headings rather than parsed as free text.
function parseIssueFormSections(body) {
  const sections = new Map();
  const pattern = /^###\s+(.+?)\s*$/gm;
  const headings = [...body.matchAll(pattern)];
  for (const [index, heading] of headings.entries()) {
    const start = heading.index + heading[0].length;
    const end = index + 1 < headings.length ? headings[index + 1].index : body.length;
    sections.set(heading[1].trim().toLowerCase(), body.slice(start, end).trim());
  }
  return sections;
}

// Accepts several headings for one field so a submission opened on an older
// version of the issue form still validates: the body is frozen at the
// wording that existed when it was posted, and a submitter should not have to
// repost because the form was reworded underneath them. The first heading is
// the current one; the rest are retired spellings.
function sectionText(sections, ...labels) {
  const matched = labels
    .map((label) => sections.get(label.toLowerCase()))
    .find((value) => value !== undefined);
  return matched === undefined || matched === "_No response_" ? "" : matched;
}

// Attachments appear in the body as bare links, as Markdown image syntax, or
// as an <img src="..."> tag (GitHub rewrites pasted images to the latter).
// The first URL in the field is taken as the attachment.
function findAssetUrl(sectionValue) {
  const match = /https?:\/\/[^\s)\]<>"']+/.exec(sectionValue);
  return match === null ? undefined : match[0];
}

function assertAllowedHost(url, problems, label) {
  let allowed = false;
  try {
    const { hostname } = new URL(url);
    allowed = kAllowedAssetHosts.includes(hostname);
    if (!allowed) {
      fail(problems, `${label}: attachments must be uploaded to the issue itself (got host \`${hostname}\`).`);
    }
  } catch {
    fail(problems, `${label}: could not be read as a URL.`);
  }
  return allowed;
}

// --max-filesize aborts oversized downloads mid-transfer, so a submission far
// over the limit never has to be pulled down in full to be rejected.
function download(url, destinationPath, maxBytes) {
  execFileSync(
    "curl",
    [
      "--silent",
      "--show-error",
      "--fail",
      "--location",
      "--max-time", "120",
      // Headroom over the limit so the size check below reports the real
      // overage rather than curl aborting first.
      "--max-filesize", String(maxBytes * 2),
      "--output", destinationPath,
      url,
    ],
    { stdio: ["ignore", "ignore", "pipe"] },
  );
}

function probeMedia(filePath) {
  const output = execFileSync(
    "ffprobe",
    [
      "-v", "error",
      "-select_streams", "v:0",
      "-show_entries", "stream=width,height,codec_name:format=duration,size,format_name",
      "-of", "json",
      filePath,
    ],
    { encoding: "utf8" },
  );
  const probed = JSON.parse(output);
  const stream = probed.streams?.[0] ?? {};
  return {
    width: Number(stream.width),
    height: Number(stream.height),
    codecName: stream.codec_name ?? "",
    formatName: probed.format?.format_name ?? "",
    // Images report no duration; treated as zero so only real videos are
    // measured against the length limit.
    durationSeconds: Number(probed.format?.duration ?? 0),
    sizeBytes: Number(probed.format?.size ?? 0),
  };
}

function formatMegabytes(bytes) {
  return `${(bytes / (1024 * 1024)).toFixed(2)} MB`;
}

function validateVideo(filePath, problems) {
  const probed = probeMedia(filePath);
  if (!probed.formatName.includes("webm") && !probed.formatName.includes("matroska")) {
    fail(problems, `Recording: must be a WebM file (detected \`${probed.formatName}\`).`);
  }
  if (probed.sizeBytes > kMaxVideoBytes) {
    fail(
      problems,
      `Recording: ${formatMegabytes(probed.sizeBytes)} exceeds the ${formatMegabytes(kMaxVideoBytes)} limit.`,
    );
  }
  if (probed.width > kMaxVideoWidth || probed.height > kMaxVideoHeight) {
    fail(
      problems,
      `Recording: ${probed.width}x${probed.height} exceeds the ${kMaxVideoWidth}x${kMaxVideoHeight} limit.`,
    );
  }
  if (probed.durationSeconds > kMaxVideoSeconds) {
    fail(
      problems,
      `Recording: ${probed.durationSeconds.toFixed(1)}s exceeds the ${kMaxVideoSeconds}s limit.`,
    );
  }
  return probed;
}

// The committed extension follows what the file actually is, since the
// attachment URL carries none to copy. WebP is what the simulator's Export
// Thumbnail button produces; PNG and JPEG stay accepted for stills prepared
// by hand.
const kThumbnailExtensionByCodec = { webp: ".webp", png: ".png", mjpeg: ".jpg" };

function validateThumbnail(filePath, problems) {
  const probed = probeMedia(filePath);
  if (kThumbnailExtensionByCodec[probed.codecName] === undefined) {
    fail(
      problems,
      `Thumbnail: must be a WebP, PNG or JPEG image (detected \`${probed.codecName}\`).`,
    );
  }
  if (probed.sizeBytes > kMaxThumbnailBytes) {
    fail(
      problems,
      `Thumbnail: ${Math.round(probed.sizeBytes / 1024)} KB exceeds the ${kMaxThumbnailBytes / 1024} KB limit.`,
    );
  }
  if (probed.width > kMaxThumbnailWidth || probed.height > kMaxThumbnailHeight) {
    fail(
      problems,
      `Thumbnail: ${probed.width}x${probed.height} exceeds the ${kMaxThumbnailWidth}x${kMaxThumbnailHeight} limit.`,
    );
  }
  return probed;
}

const kDescriptionBlockPattern = /--\[\[\s*@description\r?\n?([\s\S]*?)\]\]/;

function extractSingleLineDirective(source, directiveName) {
  // [^\S\r\n] is horizontal whitespace only. Plain \s would match the
  // newline too, so a directive left without a value ("-- @author", which is
  // how the simulator's new-script template ships it) would silently take the
  // next line as its own value.
  const pattern = new RegExp(`^--[^\\S\\r\\n]*@${directiveName}[^\\S\\r\\n]+(.+)$`, "m");
  const match = pattern.exec(source);
  return match === null ? "" : match[1].trim();
}

// Mirrors the directive conventions the simulator's own catalog step reads
// (writeSampleCatalog in the main repository's esbuild.config.mjs).
function extractScriptMetadata(source) {
  const descriptionMatch = kDescriptionBlockPattern.exec(source);
  const apiLevelRaw = parseInt(extractSingleLineDirective(source, "api_level"), 10);
  return {
    title: extractSingleLineDirective(source, "title"),
    author: extractSingleLineDirective(source, "author"),
    version: extractSingleLineDirective(source, "version"),
    apiLevel: Number.isFinite(apiLevelRaw) ? apiLevelRaw : undefined,
    description: descriptionMatch === null ? "" : descriptionMatch[1].trim(),
  };
}

// An entry lives at gallery/<author>/<title-slug>/, so the submitter and the
// title together address it. No issue number is involved: an update arrives
// as a separate issue, and it has to land on the directory the original
// submission created.
//
// Two people may therefore use the same title without colliding, and nobody
// can write outside their own directory, since the author segment comes from
// the issue's author rather than from anything in its body.
function buildTitleSlug(title) {
  const normalized = title
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 40);
  return normalized === "" ? "entry" : normalized;
}

// GitHub logins only contain alphanumerics and hyphens, so this merely stops
// anything that is not a real login from reaching a path.
function buildAuthorSlug(login) {
  return login.toLowerCase().replace(/[^a-z0-9-]+/g, "");
}

// Fixed names inside the entry directory: the directory already identifies
// the entry, so the files need not repeat the title, and an update that
// switches thumbnail format cannot leave the previous one orphaned beside it.
const kScriptFileName = "script.lua";
const kVideoFileName = "preview.webm";
const kMetadataFileName = "metadata.json";
const kThumbnailBaseName = "thumbnail";
const kGalleryDirectoryName = "gallery";

// Which of the three issue templates this came from. The label each template
// applies is the signal; the issue title prefix is a fallback for an issue
// whose labels were edited by hand.
function detectRequestKind(issue) {
  const labels = (issue.labels ?? []).map((label) => label.name ?? label);
  let kind = "new";
  if (labels.includes("gallery:update") || /^\[Gallery update\]/i.test(issue.title ?? "")) {
    kind = "update";
  } else if (labels.includes("gallery:remove") || /^\[Gallery removal\]/i.test(issue.title ?? "")) {
    kind = "remove";
  }
  return kind;
}

// The submitter's own entries, for telling them what they can name when a
// title does not match. Reads the working tree, which the workflow has
// checked out at the commit the pull request will be based on.
function listExistingEntries(authorSlug) {
  const authorDirectory = join(kGalleryDirectoryName, authorSlug);
  let entries = [];
  if (existsSync(authorDirectory)) {
    entries = readdirSync(authorDirectory, { withFileTypes: true })
      .filter((entry) => entry.isDirectory())
      .map((entry) => entry.name)
      .sort();
  }
  return entries;
}

// A removal emits nothing; it records the directory for the approve workflow
// to delete, so the two never disagree about what is being removed.
function reportRemoval(problems, entryDirectory, emitDirectory) {
  if (problems.length > 0) {
    console.log(`### Validation failed\n\n${problems.map((problem) => `- ${problem}`).join("\n")}`);
    process.exitCode = 1;
  } else {
    if (emitDirectory !== undefined) {
      mkdirSync(emitDirectory, { recursive: true });
      writeFileSync(join(emitDirectory, "removal.txt"), `${entryDirectory}\n`);
    }
    console.log(`### Validation passed\n\nReady to remove \`${entryDirectory}\`.`);
  }
}

function main() {
  const args = process.argv.slice(2);
  const issuePath = args[0];
  const emitIndex = args.indexOf("--emit");
  const emitDirectory = emitIndex >= 0 ? args[emitIndex + 1] : undefined;
  if (issuePath === undefined) {
    throw new ValidationFailure("usage: validate-gallery.mjs <issue.json> [--emit <directory>]");
  }

  const issue = JSON.parse(readFileSync(issuePath, "utf8"));
  const body = issue.body ?? "";
  const sections = parseIssueFormSections(body);
  const problems = [];

  const authorLogin = issue.author?.login ?? "";
  const authorSlug = buildAuthorSlug(authorLogin);
  if (authorSlug === "") {
    throw new ValidationFailure("issue payload carries no usable author login");
  }

  const submittedTitle = sectionText(sections, "Title", "Work title", "Sample title");
  if (submittedTitle === "") {
    fail(problems, "Title: missing.");
  }

  // Which template the issue came from decides what is required of it: a
  // removal names an entry and nothing else, while a new submission and an
  // update both carry a full set of files.
  const requestKind = detectRequestKind(issue);
  const titleSlug = buildTitleSlug(submittedTitle);
  const entryDirectory = join(kGalleryDirectoryName, authorSlug, titleSlug);
  const existingEntries = listExistingEntries(authorSlug);
  const entryExists = existingEntries.includes(titleSlug);

  // An update or a removal has to name something that is actually there;
  // otherwise the submitter has mistyped the title, and the entries they do
  // have are the most useful thing to say back.
  if (requestKind !== "new" && !entryExists && submittedTitle !== "") {
    fail(
      problems,
      `Title: no entry named \`${submittedTitle}\` under \`${kGalleryDirectoryName}/${authorSlug}/\`.` +
        (existingEntries.length === 0
          ? " You have no published entries yet — submit it as a new entry instead."
          : ` Yours are: ${existingEntries.map((entry) => `\`${entry}\``).join(", ")}.`),
    );
  }

  if (requestKind === "remove") {
    reportRemoval(problems, entryDirectory, emitDirectory);
    return;
  }

  const submittedDescription = sectionText(sections, "Description");
  if (submittedDescription === "") {
    fail(problems, "Description: missing.");
  }

  const videoUrl = findAssetUrl(sectionText(sections, "Recording", "Recording (.webm)"));
  const thumbnailUrl = findAssetUrl(sectionText(sections, "Thumbnail", "Thumbnail (.png / .jpg)"));
  if (videoUrl === undefined) {
    fail(problems, "Recording: no attachment found. Drag the `.webm` file into that field.");
  }
  if (thumbnailUrl === undefined) {
    fail(problems, "Thumbnail: no attachment found. Drag the image file into that field.");
  }

  // Emitting straight into the entry's own directory means an update
  // overwrites in place, so the approve workflow's commit is the diff.
  const workDirectory =
    emitDirectory === undefined
      ? join(process.env.RUNNER_TEMP ?? "/tmp", `submission-${issue.number}`)
      : join(emitDirectory, authorSlug, titleSlug);
  mkdirSync(workDirectory, { recursive: true });
  let scriptSource;

  if (videoUrl !== undefined && assertAllowedHost(videoUrl, problems, "Recording")) {
    const videoPath = join(workDirectory, kVideoFileName);
    try {
      download(videoUrl, videoPath, kMaxVideoBytes);
      validateVideo(videoPath, problems);
      const attachment = extractScriptAttachment(new Uint8Array(readFileSync(videoPath)));
      if (attachment === undefined) {
        fail(
          problems,
          "Recording: no embedded script found. Record with the simulator's " +
            "**Record** button, which embeds the Lua source into the file.",
        );
      } else {
        scriptSource = attachment.source;
      }
    } catch (error) {
      fail(problems, `Recording: could not be downloaded or read (${String(error.message ?? error)}).`);
    }
  }

  if (thumbnailUrl !== undefined && assertAllowedHost(thumbnailUrl, problems, "Thumbnail")) {
    // Downloaded under a neutral name first, then renamed to match the image
    // type ffprobe reports: the attachment URL has no extension to copy.
    const downloadPath = join(workDirectory, `${kThumbnailBaseName}.download`);
    try {
      download(thumbnailUrl, downloadPath, kMaxThumbnailBytes);
      const probed = validateThumbnail(downloadPath, problems);
      const extension = kThumbnailExtensionByCodec[probed.codecName];
      if (extension === undefined) {
        rmSync(downloadPath, { force: true });
      } else {
        // An update may arrive in a different format from the one already
        // committed; the stale file has to go, or the entry would carry two
        // thumbnails and the catalog would pick by extension order.
        for (const staleExtension of Object.values(kThumbnailExtensionByCodec)) {
          if (staleExtension !== extension) {
            rmSync(join(workDirectory, `${kThumbnailBaseName}${staleExtension}`), { force: true });
          }
        }
        renameSync(downloadPath, join(workDirectory, `${kThumbnailBaseName}${extension}`));
      }
    } catch (error) {
      fail(problems, `Thumbnail: could not be downloaded or read (${String(error.message ?? error)}).`);
    }
  }

  if (scriptSource !== undefined && emitDirectory !== undefined) {
    const metadata = extractScriptMetadata(scriptSource);
    writeFileSync(join(workDirectory, kScriptFileName), scriptSource);
    writeFileSync(
      join(workDirectory, kMetadataFileName),
      `${JSON.stringify(
        {
          // The submitter's own header directives win when present; the issue
          // form supplies the fallback.
          title: metadata.title !== "" ? metadata.title : submittedTitle,
          description: metadata.description !== "" ? metadata.description : submittedDescription,
          // The credit shown on the card. "-- @author" exists to override the
          // GitHub login with whatever name the author publishes under, so an
          // absent or valueless directive falls back to the login rather than
          // leaving the card unattributed.
          author: metadata.author !== "" ? metadata.author : authorLogin,
          // Who the entry belongs to, which is what addresses its directory
          // and decides who may update or remove it. Always the login, never
          // the display name above.
          submitter: authorLogin,
          version: metadata.version,
          apiLevel: metadata.apiLevel,
          sourceUrl: issue.url,
          // Sorts the gallery newest-first. An update refreshes it, so a
          // revised entry resurfaces rather than staying where it first
          // landed.
          publishedAt: new Date().toISOString(),
        },
        null,
        2,
      )}\n`,
    );
  }

  if (problems.length > 0) {
    console.log(`### Validation failed\n\n${problems.map((problem) => `- ${problem}`).join("\n")}`);
    process.exitCode = 1;
  } else {
    console.log(`### Validation passed\n\nReady to publish as \`${entryDirectory}\`.`);
  }
}

main();
