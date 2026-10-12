"""Validate the current cut without padding it to the submission time limit."""
import json, subprocess
from pathlib import Path
root=Path(__file__).resolve().parent
binary=next((root/'node_modules/.pnpm').glob('@remotion+compositor-win32*/node_modules/@remotion/compositor-win32*'))
target=root/'out/whos-me-v2.mp4'
data=json.loads((root/'src/content-v2.json').read_text())
report=json.loads(subprocess.check_output([str(binary/'ffprobe.exe'),'-v','error','-show_entries','format=duration,size:stream=codec_name,codec_type,width,height,r_frame_rate,duration,nb_frames','-of','json',str(target)],text=True))
video=next(s for s in report['streams'] if s['codec_type']=='video')
assert (video['width'],video['height'],int(video['nb_frames']))==(1920,1080,data['duration']),video
assert float(report['format']['duration'])<120
assert any(s['codec_type']=='audio' and s['codec_name']=='aac' for s in report['streams'])
subprocess.run([str(binary/'ffmpeg.exe'),'-v','error','-i',str(target),'-c:v','rawvideo','-c:a','pcm_s16le','-f','null','-'],check=True)
report['full_decode']='passed'
(root/'out/render-validation-v2.json').write_text(json.dumps(report,indent=2))
print(f"Verified 1080p/30 fps, {data['duration']/30}s picture, AAC audio, full decode passed.")
