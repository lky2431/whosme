# Who's Me? — hackathon film

**Current version: [87-second revised cut](README-v2.md).** Run `./run.ps1 render` for WhosMeV2, with real footage, local neural narration, music, and responsive device screenshots. The notes below describe the preserved original draft only.

Editable Remotion animation draft. The Flutter application is not changed by this project.

## Deliverables and boundary

- Composition: `WhosMe`, 1920 × 1080, 30 fps, exactly 3600 frames / 120 seconds.
- Twelve animated scenes: hook, creator motivation, join, identity, answer, guess, reveal, architecture, privacy, synchronization, social payoff, end card.
- English captions and a temporary Microsoft Zira computer voice for timing review. This is **not final voiceover**.
- Six clearly labelled footage placeholders. These are not real gameplay demonstrations.
- Character assignments and example question are illustrative and centrally editable. Align them to the actual recording before final delivery.
- The public play URL is intentionally blank until confirmed. No fabricated URL or QR code.

## Run

Use Node.js and pnpm. From this directory:

```powershell
pnpm install --frozen-lockfile
pnpm typecheck
pnpm studio
pnpm render
python finalize.py
```

If Chrome is not discovered, append `--browser-executable="C:\Program Files\Google\Chrome\Application\chrome.exe"` to the Remotion command. Output is `out/whos-me-draft.mp4`.

For this Windows environment, `run.ps1` locates the bundled Node/pnpm runtime; run `./run.ps1 typecheck`, `./run.ps1 studio`, or `./run.ps1 render`. The render task also invokes `finalize.py`: this trims trailing audio silence to avoid AAC padding taking the container past 120 seconds, preserves all 3600 video frames, and verifies full decoding. The finalizer uses the pinned Windows compositor binaries.

## Edit the film

`src/content.json` contains narration, cue timing (seconds), scene timing, player names, identity mapping, question, answer choices, footage slots, URL, and draft/audio switches. `src/Film.tsx` contains the animated scenes and reusable character/card/arrow/footage components.

Assignments `[1,2,3,0]` mean Alice plays Ben, Ben plays Chloe, Chloe plays David, David plays Alice. Update the corresponding explanatory text if a different example is used.

### Replace a recording

1. Copy footage to `public/footage/`, for example `public/footage/answer.mp4`.
2. In `content.json`, set `slots.answer.file` to `footage/answer.mp4`.
3. Set `trimBefore` to the source frame offset (30 fps). A 2-second lead-in is 60 frames.
4. Ensure the recording is at least the slot duration after trimming. Original audio is muted; video uses `objectFit: contain`, preserving the whole app view.
5. Preview its scene, check identities/questions match the narration, then render again.

The placeholder disappears when a file is configured. Keep `draft: true` until all required footage and final voiceover are verified. Change `playUrl` only to the actual public game URL.

### Voice and subtitles

`make-scratch-voice.ps1` generates 21 local WAV clips. It increases the Windows voice rate only where needed to fit each caption window and fails if a clip cannot fit. This is temporary timing audio. `out/voice-timing.json` records its timing. Set `scratchVoice` to false for a silent export. Replace the corresponding audio clips with recorded narration, or update the audio layer for a continuous mastered recording.

`out/narration-en.txt`, `out/captions-en.srt`, and `out/shot-list-zh.txt` are generated from content or project instructions. Rerun `export-text.py` after changing cue timing.

## Visual direction

Bundled Nunito font (OFL included), cream paper, cyan blue, yellow, coral and lilac. Original SVG animal characters, name cards, thought-like speech cards, animated arrows and server diagrams. All animation is derived from the Remotion frame, so preview and export are deterministic. No live external assets required during rendering.

## Final checks before submission

Replace placeholders, match names/question/answers, confirm public URL, replace temporary voice, review all captions, inspect full-length playback, and keep runtime at or below 120 seconds. The current technical story is based on the local Serverpod implementation, not a claim of load testing or zero-latency synchronization.

Implementation references: https://www.remotion.dev/docs/sequence, https://www.remotion.dev/docs/offthreadvideo, https://www.remotion.dev/docs/cli/render
