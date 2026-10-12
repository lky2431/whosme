import json
from html import escape
from pathlib import Path

root = Path(__file__).resolve().parent
film = json.loads((root / 'src/content.json').read_text(encoding='utf-8'))
out = root / 'out'
out.mkdir(exist_ok=True)

def stamp(seconds):
    ms = round(seconds * 1000)
    return f'{ms//3600000:02}:{ms//60000%60:02}:{ms//1000%60:02},{ms%1000:03}'

out.joinpath('captions-en.srt').write_text('\n\n'.join(f'{i+1}\n{stamp(c["start"])} --> {stamp(c["end"])}\n{c["text"]}' for i,c in enumerate(film['cues']))+'\n',encoding='utf-8')
out.joinpath('narration-en.txt').write_text('TEMPORARY NARRATION SCRIPT — Who’s Me?\n\n'+'\n\n'.join(f'{c["start"]:05.1f}–{c["end"]:05.1f}s\n{c["text"]}' for c in film['cues']),encoding='utf-8')
out.joinpath('shot-list-zh.txt').write_text('''Who’s Me? 影片拍攝清單

先拍一小段測試：開答案選單 → 選答案 → 提交，約 10–15 秒。
使用英文介面，建議 1920×1080、30fps、MP4。錄原始畫面，先不要加字幕、音樂或轉場。
每個關鍵操作前後停留 2–3 秒。素材可比正式使用長，剪接時再取用。

01 join.mp4 — 正片 00:24–00:30（6秒）
建立房間、顯示房間碼、四人到齊。建議提供 12–20 秒原片。

02 identity.mp4 — 正片 00:30–00:38（8秒）
Alice 的視角，停留在「You’re playing Ben」。提供 10–15 秒。

03 answer.mp4 — 正片 00:38–00:55（17秒）
同一玩家：題目 → 開啟四個選項 → 選擇 → 提交 → 等待其他人。
提供 25–35 秒。暫定示例題目為 When do you have the most energy?；
若抽到不同題目，照實拍攝，我們會修改動畫與旁白，不需强求抽到相同題目。

04 guess.mp4 — 正片 00:55–01:05（10秒）
Ben 的視角：瀏覽各位朋友答案 → 猜 Alice → 鎖定。提供 15–25 秒。

05 reveal.mp4 — 正片 01:05–01:12（7秒）
Ben 的猜測結果、Alice 扮演 Ben 的關係，以及得分。提供 12–15 秒。

06 sync.mp4 — 正片 01:32–01:42（10秒）
先停留在 3/4 已回答；另一位提交後，拍到自動進入下一題。
再拍刷新頁面、恢復原座位與進度。可提供兩段，各 10–15 秒。
若要同時顯示四個畫面，需額外錄下同一時刻的四格畫面，不能將分開錄影說成同步實錄。

角色暫定：Alice、Ben、Chloe、David。
動畫目前是 Alice→Ben、Ben→Chloe、Chloe→David、David→Alice。
請把實際身份對應告訴我；如果不同，我會調整動畫，並檢查相關文字／旁白。
將原片放在 video/public/footage/。無需自己對時間軸，我會負責剪接。

正式旁白仍待錄製；目前預覽使用 Windows 電腦試配音，僅供節奏審閱。
結尾遊玩網址待確認。完成後才移除草稿標記。
''',encoding='utf-8')
print(f'Exported English script, SRT, and Traditional Chinese shot list to {out}')

frames = [200,500,780,1000,1420,1800,2080,2360,2660,2900,3310,3530]
labels = ['開場','創作動機','加入房間','秘密身份','代入作答','推理猜測','揭曉','Serverpod 架構','規則與隱私','同步與保存','朋友間的對話','結尾']
cards = ''.join(f'<button class="scene" data-time="{s["start"]}"><img src="frame-{frame}.png" alt="{label}分鏡" loading="lazy"><span><b>{s["start"]//60:02}:{s["start"]%60:02}</b> {label}</span></button>' for s,frame,label in zip(film['scenes'],frames,labels))
out.joinpath('preview.html').write_text('''<!doctype html><html lang="zh-Hant"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Who’s Me? — 影片粗版</title><style>
*{box-sizing:border-box}body{margin:0;background:#fff8ed;color:#171a20;font-family:system-ui,sans-serif}main{max-width:1240px;margin:auto;padding:40px 24px}header{display:flex;justify-content:space-between;align-items:center;gap:24px}h1{font-size:38px;letter-spacing:-1px;margin:0}p{line-height:1.7;color:#62645f}.badge{background:#ffd629;border-radius:30px;padding:10px 20px;font-size:14px;font-weight:800}video{width:100%;background:#171a20;border-radius:18px;margin:20px 0}nav{display:flex;gap:20px;flex-wrap:wrap}a{color:#171a20;text-underline-offset:4px}.grid{display:grid;grid-template-columns:repeat(3,1fr);gap:18px;margin-top:22px}.scene{padding:0;background:white;border:2px solid #171a20;border-radius:16px;overflow:hidden;text-align:left;font:inherit;cursor:pointer}.scene:hover,.scene:focus-visible{outline:4px solid #50c9ee}.scene img{width:100%;display:block}.scene span{display:block;padding:14px}.scene b{margin-right:12px;color:#62645f}h2{margin-top:38px;font-size:23px}footer{margin-top:30px;padding-top:20px;border-top:1px solid #ddd5c8;font-size:14px;line-height:1.8}@media(max-width:700px){.grid{grid-template-columns:1fr}header{align-items:flex-start;flex-direction:column}h1{font-size:30px}}@media(prefers-reduced-motion:reduce){html{scroll-behavior:auto}}
</style><main><header><div><h1>who’s me? / 影片粗版</h1><p>2:00 · 1920 × 1080 · 30 fps · 英文字幕</p></div><div class="badge">動畫已製作 · 實機錄影待補</div></header><video id="film" controls preload="metadata" poster="frame-200.png"><source src="whos-me-draft.mp4" type="video/mp4">請下載 MP4 播放。</video><p>目前使用臨時電腦配音。黑色區塊標明待補錄影，不是實機示範。點下方分鏡可跳到對應時間，播放由你控制。</p><nav><a href="whos-me-draft.mp4" download>下載 MP4</a><a href="shot-list-zh.txt">繁體中文拍攝清單</a><a href="narration-en.txt">英文旁白稿</a><a href="captions-en.srt" download>英文字幕 SRT</a></nav><h2>十二個場景</h2><div class="grid">'''+cards+'''</div><footer>收到錄影後會更新素材、人物身份與題目，調整配音節奏，再移除草稿標記。<br>可編輯內容：../src/content.json · 動畫來源：../src/Film.tsx</footer></main><script>const film=document.getElementById('film');document.querySelectorAll('[data-time]').forEach(button=>button.addEventListener('click',()=>{film.currentTime=Number(button.dataset.time);film.scrollIntoView({behavior:matchMedia('(prefers-reduced-motion: reduce)').matches?'auto':'smooth',block:'center'});}));</script></html>''',encoding='utf-8')
