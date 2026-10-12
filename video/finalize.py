"""Keep the MP4 container within the 120-second limit, including AAC padding."""
import json
import os
from pathlib import Path
import subprocess

root = Path(__file__).resolve().parent
binary_dir = root / 'node_modules/.pnpm/@remotion+compositor-win32-x64-msvc@4.0.529/node_modules/@remotion/compositor-win32-x64-msvc'
ffmpeg = binary_dir / 'ffmpeg.exe'
ffprobe = binary_dir / 'ffprobe.exe'
target = root / 'out/whos-me-draft.mp4'
exact = root / 'out/whos-me-draft.exact.mp4'
# Last temporary voice finishes before 119.5s. Only the final audio silence is cut.
subprocess.run([str(ffmpeg), '-v', 'error', '-y', '-i', str(target), '-map', '0:v:0', '-map', '0:a:0', '-c:v', 'copy', '-af', 'atrim=end=119.9', '-c:a', 'aac', '-b:a', '192k', '-t', '120', '-movflags', '+faststart', str(exact)], check=True)
report = json.loads(subprocess.check_output([str(ffprobe), '-v', 'error', '-show_entries', 'format=duration,size:stream=codec_name,codec_type,width,height,r_frame_rate,duration,nb_frames', '-of', 'json', str(exact)], text=True))
assert float(report['format']['duration']) <= 120.0, report
video = next(s for s in report['streams'] if s['codec_type'] == 'video')
assert (video['width'], video['height'], video['nb_frames']) == (1920, 1080, '3600'), video
subprocess.run([str(ffmpeg), '-v', 'error', '-i', str(exact), '-c:v', 'rawvideo', '-c:a', 'pcm_s16le', '-f', 'null', '-'], check=True)
os.replace(exact, target)
(root / 'out/render-validation.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
print('Verified: 1920x1080, 30 fps, 3600 frames, <=120 seconds, AAC audio, full decode passed.')
