# Mug Typography — Gallery

Works made by users of the [Mug Typography scripting
simulator](https://mug-lab-3.github.io/mug-typography-docs/simulator/). Works
that land here appear in the simulator's sample browser under the **gallery**
tab.

## Submitting a work

1. Build your animation in the simulator.
2. Press **Record**. The resulting `.webm` has the Lua source embedded in it,
   so the script is read back out of the recording — there is nothing to paste.
3. Press the camera button above the preview to save a still for the card.
4. Open a [work submission
   issue](../../issues/new?template=work-submission.yml) and attach both files.

To replace a file after posting, edit the issue and swap it in the field —
files attached in a comment are not picked up.

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

1. A maintainer adds the `work:check` label. A workflow validates the
   attachments against the limits above, extracts the embedded script, and
   comments with the result.
2. A maintainer adds the `approved` label. A workflow re-validates, writes the
   work into `gallery/`, rebuilds `catalog.json`, and opens a pull request.
3. Merging that pull request publishes the work. The simulator fetches
   `catalog.json` at runtime, so no redeploy is needed.

## Repository layout

- `gallery/` — one `<slug>.lua`, `<slug>.json` (metadata), `<slug>.webm` and
  thumbnail per published work.
- `catalog.json` — an index generated from `gallery/` by
  `scripts/build-catalog.mjs`, naming each work's script rather than carrying
  it. Fetched directly by the simulator; do not edit by hand.
- `scripts/` — the validation and catalog tooling the workflows run.

## License

By submitting, you confirm the script is yours and agree to it being
distributed as part of this project.
