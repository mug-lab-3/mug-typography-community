# Mug Typography — Gallery

Animations made by users of the [Mug Typography scripting
simulator](https://mug-lab-3.github.io/mug-typography-docs/simulator/).
Everything published here appears in the simulator's sample browser under the
**gallery** tab.

## Adding yours to the gallery

1. Build your animation in the simulator.
2. Press **Record**. The resulting `.webm` has the Lua source embedded in it,
   so the script is read back out of the recording — there is nothing to paste.
3. Press the camera button above the preview to save a still for the card.
4. Open a [new gallery
   entry](../../issues/new?template=gallery-submission.yml) and attach both
   files.

The title you give becomes the name of your entry, so keep it in mind:
updating or removing it later means giving the same title again.

To fix a file before it is published, edit the issue and swap it in the field
— files attached in a comment are not picked up.

## Updating or removing your entry

Open a separate issue rather than editing a published one:

- [Update an entry](../../issues/new?template=gallery-update.yml) — replaces
  the recording, thumbnail and script in place, keeping the entry where it is.
- [Remove an entry](../../issues/new?template=gallery-removal.yml) — takes it
  out of the gallery. Nothing to attach.

Both find the entry by your GitHub username plus the title, so the title has
to match what was published. You can only reach your own entries: everything
you publish lives under `gallery/<your-username>/`, and that path comes from
who opened the issue.

### Limits

| File | Format | Max size | Max resolution | Max length |
| --- | --- | --- | --- | --- |
| Recording | WebM | 8 MB | 1280x720 | 15 s |
| Thumbnail | WebP, PNG or JPEG | 500 KB | 1280x720 | — |

Your script's own `-- @title`, `-- @author`, `-- @version` and
`--[[ @description ]]` header directives are used when present; the issue form
fields fill in the rest.

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
