# Mug Typography — Community Samples

User-submitted scripts for the [Mug Typography scripting
simulator](https://mug-lab-3.github.io/mug-typography-docs/simulator/). Samples
that land here appear in the simulator's sample browser under the
**community** tab.

## Submitting a sample

1. Build your animation in the simulator.
2. Press **Record**. The resulting `.webm` has the Lua source embedded in it,
   so the script is read back out of the recording — there is nothing to paste.
3. Save a still image for the card.
4. Open a [sample submission
   issue](../../issues/new?template=sample-submission.yml) and attach both
   files.

### Limits

| File | Format | Max size | Max resolution | Max length |
| --- | --- | --- | --- | --- |
| Recording | WebM | 8 MB | 1280x720 | 15 s |
| Thumbnail | PNG or JPEG | 500 KB | 1280x720 | — |

Your script's own `-- @title`, `-- @author`, `-- @version` and
`--[[ @description ]]` header directives are used when present; the issue form
fields fill in the rest.

## How a submission is published

Submissions are reviewed by hand — nothing runs automatically when an issue is
opened.

1. A maintainer adds the `sample:check` label. A workflow validates the
   attachments against the limits above, extracts the embedded script, and
   comments with the result.
2. A maintainer adds the `approved` label. A workflow re-validates, writes the
   sample into `samples/`, rebuilds `catalog.json`, and opens a pull request.
3. Merging that pull request publishes the sample. The simulator fetches
   `catalog.json` at runtime, so no redeploy is needed.

## Repository layout

- `samples/` — one `<slug>.lua`, `<slug>.json` (metadata), `<slug>.webm` and
  thumbnail per published sample.
- `catalog.json` — generated from `samples/` by `scripts/build-catalog.mjs`;
  fetched directly by the simulator. Do not edit by hand.
- `scripts/` — the validation and catalog tooling the workflows run.

## License

By submitting, you confirm the script is yours and agree to it being
distributed as part of this project.
