# Mug Typography — Gallery

[日本語](README.md)

Animations made by users of the [Mug Typography scripting
simulator](https://mug-lab-3.github.io/mug-typography-docs/simulator/).
Everything published here appears in the simulator's sample browser under the
**gallery** tab.

## Adding yours to the gallery

1. Build your animation in the simulator, and put its name in the script's
   `-- @title`.
2. Press **Record**. The resulting `.webm` has the Lua source embedded in it,
   so the script is read back out of the recording — there is nothing to paste.
3. Capture the thumbnail: the camera button above the preview saves **the
   frame currently on screen** as the card's still, so show the moment you
   want on the card before pressing it.
4. Open a [new gallery
   entry](../../issues/new?template=gallery-submission.yml) and attach the two
   files — **the recording (`.webm`) and the thumbnail image**.

Your entry is named after the script's `-- @title`, so keep it in mind:
updating or removing it later means naming it again.

To fix a file before it is published, edit the issue and swap it in the field
— files attached in a comment are not picked up.

## Updating or removing your entry

Open a separate issue rather than editing a published one:

- [Update an entry](../../issues/new?template=gallery-update.yml) — replaces
  the recording, thumbnail and script in place, keeping the entry where it is.
- [Remove an entry](../../issues/new?template=gallery-removal.yml) — takes it
  out of the gallery. Nothing to attach.

Both find the entry by your GitHub username plus its name, so the form's Title
has to match the name it was published under. You can only reach your own
entries: everything you publish lives under `gallery/<your-username>/`, and
that path comes from who opened the issue.

## Requirements

All of the following are checked automatically, and anything unmet is reported
back on the issue. Problems are collected into one comment, so you can fix
them in a single pass.

### Recording (`.webm`)

| Property | Requirement |
| --- | --- |
| Format | WebM |
| File size | up to 8 MB |
| Resolution | up to 1280x720 |
| Length | up to 15 seconds |
| Script | Lua source embedded in the file |

The simulator's **Record** satisfies all of these on its own, resolution
included, since a scene starts out 1280x720. A video made with anything else
cannot be accepted, as it carries no embedded script.

### Thumbnail

| Property | Requirement |
| --- | --- |
| Format | WebP, PNG or JPEG |
| File size | up to 500 KB |
| Resolution | up to 1280x720 |

The camera button above the preview produces a conforming file.

### Script header

These are read from the script recovered out of the recording.

| Directive | Required | Purpose |
| --- | --- | --- |
| `-- @title` | **yes** | The entry's name: it heads the card and names the directory it is stored in |
| `-- @author` | no | The credit on the card. Defaults to your GitHub username |
| `-- @version` | no | Shown on the card |
| `-- @api_level` | no | The API level shown on the card |
| `--[[ @description ]]` | no | The card's blurb. Falls back to the issue form's Description |

An absent or empty `-- @title` is rejected. New Script in the simulator starts
you off with all of these in place, so normally there is nothing to add.

### Attachments

- Drag files into **the fields of the issue body**. Files attached in a
  comment are not picked up.
- Only files uploaded to GitHub are fetched; external URLs are rejected.

### For updates and removals

- Put the **published entry's name** (its `-- @title` at the time) in the
  form's Title. That is what identifies the entry.
- For an update, the attached script's `-- @title` has to match it too. A
  mismatch is rejected, since it would otherwise publish a second copy
  alongside the original. To rename an entry, remove it and submit it anew.

## How a submission is published

Submissions are reviewed by hand — nothing runs automatically when an issue is
opened.

1. A maintainer adds the `gallery:check` label. A workflow validates the
   attachments against the limits above, extracts the embedded script, and
   comments with the result.
2. A maintainer adds the `approved` label. A workflow re-validates, applies
   the change under `gallery/`, rebuilds `catalog.json`, and opens a pull
   request.
3. Merging that pull request publishes it. The simulator fetches
   `catalog.json` at runtime, so no redeploy is needed.

## Repository layout

- `gallery/<username>/<title>/` — one directory per published entry, holding
  `script.lua`, `preview.webm`, `thumbnail.*` and `metadata.json`.
- `catalog.json` — an index generated from `gallery/` by
  `scripts/build-catalog.mjs`, naming each entry's script rather than carrying
  it. Fetched directly by the simulator; do not edit by hand.
- `scripts/` — the validation and catalog tooling the workflows run.

## License

By submitting, you confirm the script is yours and agree to it being
distributed as part of this project.
