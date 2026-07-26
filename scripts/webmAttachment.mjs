// Recovers the Lua source the simulator embeds into its WebM recordings as a
// Matroska Attachments element.
//
// This is a plain-JS port of src/shared/webmAttachment.ts in the
// mug-text-dissector repository (the writer side lives there, in
// appendScriptAttachment). The two must stay in step: a change to the element
// layout there breaks extraction here. The logic is duplicated rather than
// shared because this repository intentionally has no build step and no
// dependency on the private main repository.

const kAttachmentsId = [0x19, 0x41, 0xa4, 0x69];
const kAttachedFileId = [0x61, 0xa7];
const kFileNameId = [0x46, 0x6e];
const kFileMimeTypeId = [0x46, 0x60];
const kFileDataId = [0x46, 0x5c];
const kMimeType = "text/x-lua";

// The Attachments element carries no offset index, so this scans for its ID
// pattern from the end of the file and validates the full element structure
// before trusting a match (raw video bytes can contain the same 4-byte
// sequence by chance).
export function extractScriptAttachment(webmBytes) {
  let result;
  let searchEnd = webmBytes.length;
  while (result === undefined && searchEnd > 0) {
    const candidate = lastIndexOfPattern(webmBytes, kAttachmentsId, searchEnd);
    if (candidate < 0) {
      break;
    }
    result = parseAttachments(webmBytes, candidate);
    searchEnd = candidate;
  }
  return result;
}

function parseAttachments(bytes, attachmentsOffset) {
  const decoder = new TextDecoder();
  let result;
  const attachments = readElement(bytes, attachmentsOffset, kAttachmentsId);
  const attachedFile =
    attachments === undefined ? undefined : readElement(bytes, attachments.payloadStart, kAttachedFileId);
  if (attachments !== undefined && attachedFile !== undefined) {
    let fileName;
    let mimeType;
    let fileData;
    let offset = attachedFile.payloadStart;
    while (offset < attachedFile.payloadEnd) {
      const id = Array.from(bytes.slice(offset, offset + 2));
      const size = readVint(bytes, offset + 2);
      if (size === undefined) {
        break;
      }
      const payloadStart = offset + 2 + size.width;
      const payload = bytes.slice(payloadStart, payloadStart + size.value);
      if (matchesId(id, kFileNameId)) {
        fileName = decoder.decode(payload);
      } else if (matchesId(id, kFileMimeTypeId)) {
        mimeType = decoder.decode(payload);
      } else if (matchesId(id, kFileDataId)) {
        fileData = payload;
      }
      offset = payloadStart + size.value;
    }
    if (fileName !== undefined && mimeType === kMimeType && fileData !== undefined) {
      result = { fileName, source: decoder.decode(fileData) };
    }
  }
  return result;
}

function readElement(bytes, offset, expectedId) {
  let result;
  const id = Array.from(bytes.slice(offset, offset + expectedId.length));
  if (matchesId(id, expectedId)) {
    const size = readVint(bytes, offset + expectedId.length);
    if (size !== undefined) {
      const payloadStart = offset + expectedId.length + size.width;
      const payloadEnd = payloadStart + size.value;
      if (payloadEnd <= bytes.length) {
        result = { payloadStart, payloadEnd };
      }
    }
  }
  return result;
}

// EBML variable-width size: the leading byte carries a marker bit at position
// (8 - width); the remaining bits hold the value's high bits.
function readVint(bytes, offset) {
  let result;
  const first = bytes[offset];
  if (first !== undefined && first !== 0) {
    let width = 1;
    while ((first & (1 << (8 - width))) === 0) {
      width += 1;
    }
    if (offset + width <= bytes.length) {
      let value = first & ((1 << (8 - width)) - 1);
      for (let index = 1; index < width; index += 1) {
        value = value * 256 + bytes[offset + index];
      }
      result = { value, width };
    }
  }
  return result;
}

function matchesId(candidate, expected) {
  return candidate.length === expected.length && expected.every((byte, index) => candidate[index] === byte);
}

function lastIndexOfPattern(bytes, pattern, searchEnd) {
  let result = -1;
  for (let offset = searchEnd - pattern.length; offset >= 0 && result < 0; offset -= 1) {
    if (pattern.every((byte, index) => bytes[offset + index] === byte)) {
      result = offset;
    }
  }
  return result;
}
