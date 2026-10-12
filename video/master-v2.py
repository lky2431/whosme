"""Master final audio, retaining the original render for comparison."""
import json, os, subprocess
from pathlib import Path
root=Path(__file__).resolve().parent
binary=next((root/'node_modules/.pnpm').glob('@remotion+compositor-win32*/node_modules/@remotion/compositor-win32*'))
source=root/'out/whos-me-v2.mp4';target=root/'out/whos-me-v2-mastered.mp4'
run=subprocess.run([str(binary/'ffmpeg.exe'),'-hide_banner','-y','-i',str(source),'-map','0:v:0','-map','0:a:0','-c:v','copy','-af','loudnorm=I=-16:TP=-1.5:LRA=11:print_format=json','-ar','48000','-c:a','aac','-b:a','192k','-movflags','+faststart',str(target)],capture_output=True,text=True,check=True)
stats=run.stderr[run.stderr.rfind('{'):]
report=json.JSONDecoder().raw_decode(stats)[0]
assert float(report['output_tp'])<=-1.0,report
(root/'out/audio-mastering-v2.json').write_text(json.dumps(report,indent=2))
os.replace(source,root/'out/whos-me-v2-unmastered.mp4')
os.replace(target,source)
print('Audio mastered:',report['output_i'],'LUFS;',report['output_tp'],'dBTP.')
