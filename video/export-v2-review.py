import json, html, wave, math
from pathlib import Path
import numpy as np
root=Path(__file__).resolve().parent
data=json.loads((root/'src/content-v2.json').read_text())
chapters=''.join(f'<button onclick="jump({s["start"]/30})">{int(s["start"]/30)//60}:{int(s["start"]/30)%60:02} · {html.escape(s["id"])}</button>' for s in data['scenes'])
page='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>Who's Me · revised cut</title><style>body{margin:0;background:#fff8ed;color:#171a20;font:18px system-ui}main{max-width:1200px;margin:36px auto;padding:0 24px}h1{margin-bottom:8px}video{width:100%;background:#171a20;border-radius:18px;margin:20px 0}nav{display:flex;flex-wrap:wrap;gap:8px}button{border:2px solid #171a20;border-radius:20px;background:#50c9ee;padding:8px 15px;cursor:pointer;font:inherit}small{display:block;margin-top:20px;color:#62645f}a{color:#171a20}</style><main><h1>who’s me? · revised cut</h1><p>87 seconds · Real gameplay + animation · English neural narration</p><video id="film" controls preload="metadata" src="whos-me-v2.mp4"></video><nav>CHAPTERS</nav><p><a href="captions-v2.srt">English subtitles</a> · <a href="narration-v2.txt">Narration script</a></p><small>Device montage uses the real responsive web app in Chrome. Narration is local Kokoro neural synthesis; music is an original synthesized instrumental bed. Original recordings and the previous draft are preserved.</small></main><script>function jump(t){const v=document.getElementById('film');v.currentTime=t;v.play()}</script></html>'''.replace('CHAPTERS',chapters)
(root/'out/preview-v2.html').write_text(page,encoding='utf-8')
report=[]
for path in (root/'public/audio-v2').glob('*.wav'):
    with wave.open(str(path)) as w:
        duration=w.getnframes()/w.getframerate();a=np.frombuffer(w.readframes(w.getnframes()),dtype='<i2').astype(float)/32768
    peak=float(np.max(np.abs(a)));rms=float(np.sqrt(np.mean(a*a)))
    assert peak<.99 and rms>0,(path,peak,rms)
    report.append(dict(file=path.name,seconds=duration,peak_dbfs=round(20*math.log10(peak),2),rms_dbfs=round(20*math.log10(rms),2)))
for c in data['cues']:assert c['start']+c['duration']<=data['duration']
(root/'out/audio-validation-v2.json').write_text(json.dumps(report,indent=2))
print('Review page exported; all audio sources non-silent and below clipping.')
