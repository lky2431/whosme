# Who's Me — revised submission film

The current composition is **WhosMeV2**, 87 seconds at 1920×1080 / 30 fps. The original WhosMe composition and draft MP4 remain available.

## Preview and render

Run `./run.ps1 studio` and select WhosMeV2. Run `./run.ps1 render` to produce `out/whos-me-v2.mp4`; the command masters audio toward -16 LUFS / -1.5 dBTP, then verifies duration, video frames, AAC audio, and full decode. `./run.ps1 typecheck` checks TypeScript. `out/preview-v2.html` provides a player with chapter navigation.

## Editing

- `src/FilmV2.tsx`: source trims, playback speeds, measured crop rectangles, camera moves, device montage, and the Serverpod page.
- `src/content-v2.json`: frame-based scene and narration timing.
- `prepare-v2.py`: English script, local neural voice generation, original instrumental synthesis, SRT export, and lossless footage import.
- `public/footage`: MP4 copies remuxed from the supplied MKVs with their original audio removed. Original user files are unchanged.
- `public/audio-v2`: Kokoro neural voice, original synthesized instrumental bed, reveal chime. The music is ducked during narration.
- `public/devices`: actual deployed web app screenshots. Device frames are presentation mockups; this is responsive web evidence, not native iOS/Android certification.

The edit removes the refresh demonstration and standalone privacy/validation slide. Serverpod's developer benefits fit on one page. Alice answers Dog as Ben, then correctly identifies David as her double. The split-screen clip demonstrates live delivery of an answer, not a next-question transition.

## Voice provenance

Voice is locally generated using Kokoro `af_heart` with kokoro-onnx; it is synthetic neural narration, not a human recording. Sources: https://github.com/thewh1teagle/kokoro-onnx and https://huggingface.co/hexgrad/Kokoro-82M . The initial Edge neural service attempt failed with HTTP 403 and is not used. Old SAPI files are only used by the legacy composition.

To regenerate on this workspace, use bundled Python with PYTHONPATH set to `../.local/kokoro-python`, then run `prepare-v2.py`. Model files reside outside the video deliverable in `../.local/kokoro-models`. Delete only a specific generated voice WAV if deliberately regenerating changed script text, then rerun; existing voice files are cached.

## Footage decisions

Host and joining are accelerated. Repeated exploratory answer/guess selections are cut. The identity animation explains the rule before its real screen appears. Room creation, answering, guessing and reveal use full-canvas crops, with gentle camera movement. The double-session recording remains wide so both sides can be compared.
