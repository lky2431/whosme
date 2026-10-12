"""Reproducible footage import, local neural VO, and original instrumental bed."""
import json, math, subprocess, wave
from pathlib import Path
import numpy as np

ROOT=Path(__file__).resolve().parent
FPS=30
# Each chapter gets breathing room; two minutes is only the submission ceiling.
chapters=[
 ('hook',6,"Your friends know your name. But how well do they know you?"),
 ('why',9,"I made Who's Me for friend gatherings. A game to get us laughing, talking, and knowing each other better."),
 ('host',7,"One friend creates a room and chooses the questions."),
 ('join',5,"Everyone else joins with the room code."),
 ('identity',6,"You secretly get another friend's name. Alice gets Ben. Her challenge? Think like him."),
 ('answer',7,"Which animal would Ben be for a day? Alice chooses Dog, and locks it in."),
 ('next',4,"Once everyone answers, the next question begins."),
 ('guess',7,"Read everyone's answers. Who was pretending to be you? Make your guess."),
 ('reveal',5,"Alice guesses David. And she's right!"),
 ('devices',6,"Flutter lets the same game adapt to different screens."),
 ('serverpod',9,"Serverpod takes care of the backend plumbing, so I can spend more time building the game in Flutter."),
 ('sync',5,"Its streams keep answers flowing between players, live."),
 ('payoff',7,"The best part isn't the score. It's asking, why did you think I'd choose that?"),
 ('outro',4,"Who's Me? Think like a friend.")
]

def wav(path,a,sr):
    a=np.clip(a,-.98,.98)
    with wave.open(str(path),'wb') as w:
        w.setnchannels(1 if a.ndim==1 else a.shape[1]);w.setsampwidth(2);w.setframerate(sr)
        w.writeframes((a*32767).astype('<i2').tobytes())

def main():
    from kokoro_onnx import Kokoro
    import onnxruntime as ort
    model=ROOT.parent/'.local/kokoro-models'
    opts=ort.SessionOptions();opts.intra_op_num_threads=4
    engine=Kokoro.from_session(ort.InferenceSession(str(model/'kokoro-v1.0.onnx'),sess_options=opts,providers=['CPUExecutionProvider']),str(model/'voices-v1.0.bin'))
    audio=ROOT/'public/audio-v2';audio.mkdir(exist_ok=True)
    scenes=[];cues=[];cursor=0
    for i,(name,minimum,text) in enumerate(chapters):
        filename=f'{name}-v2.wav' if name=='guess' else f'{name}.wav'
        file=audio/filename
        if not file.exists():
            spoken=text.replace('Serverpod','Server pod')
            samples,sr=engine.create(spoken,voice='af_heart',speed=1.04,lang='en-us')
            samples=samples/max(1.,float(np.max(np.abs(samples)))/.85)
            wav(file,samples,sr)
        with wave.open(str(file),'rb') as w: seconds=w.getnframes()/w.getframerate()
        duration=max(minimum,math.ceil((seconds+.9)*FPS)/FPS)
        scenes.append(dict(id=name,start=cursor,duration=round(duration*FPS),seconds=duration))
        cues.append(dict(start=cursor+12,duration=math.ceil(seconds*FPS),text=text,file=f'audio-v2/{filename}'))
        cursor+=round(duration*FPS)
        print(name,round(seconds,2),'scene',duration,flush=True)
    data=dict(fps=FPS,duration=cursor,scenes=scenes,cues=cues,voice='Kokoro af_heart (local neural synthesis)',playUrl='https://whosme-511315.web.app')
    (ROOT/'src/content-v2.json').write_text(json.dumps(data,indent=2),encoding='utf-8')
    (ROOT/'out/narration-v2.txt').write_text('\n\n'.join(c['text'] for c in cues),encoding='utf-8')
    def stamp(fr):
        ms=round(fr/FPS*1000);return f'{ms//3600000:02}:{ms//60000%60:02}:{ms//1000%60:02},{ms%1000:03}'
    (ROOT/'out/captions-v2.srt').write_text('\n\n'.join(f'{i+1}\n{stamp(c["start"])} --> {stamp(c["start"]+c["duration"])}\n{c["text"]}' for i,c in enumerate(cues)),encoding='utf-8')
    # Original mellow electric-piano score, deterministic synthesis, no stock samples.
    sr=32000;duration=cursor/FPS;n=math.ceil(duration*sr);mix=np.zeros((n,2),dtype=np.float64);rng=np.random.default_rng(42)
    beat=60/88
    def add(tone,start,pan=0):
        a=int(start*sr);b=min(n,a+len(tone))
        if a>=n:return
        mix[a:b,0]+=tone[:b-a]*math.sqrt((1-pan)/2);mix[a:b,1]+=tone[:b-a]*math.sqrt((1+pan)/2)
    def note(midi,length,amp=.1):
        t=np.arange(int(length*sr))/sr;hz=440*2**((midi-69)/12)
        env=(1-np.exp(-t*90))*np.exp(-t/1.35)*np.minimum(1,(length-t)/.18)
        return amp*env*(np.sin(2*np.pi*hz*t)+.2*np.sin(2*np.pi*hz*2*t)*np.exp(-t*3)+.06*np.sin(2*np.pi*hz*3*t))
    chords=[[48,55,59,64],[45,52,55,60],[50,57,60,65],[43,53,57,62]]
    for bar,start in enumerate(np.arange(0,duration,beat*4)):
        chord=chords[bar%4]
        for j,key in enumerate(chord):add(note(key,3.4,.11),start+j*.045,(j-1.5)/3)
        add(note(chord[0]-12,beat*1.9,.15),start)
        add(note(chord[0]-12,beat*1.6,.09),start+beat*2.5)
        if bar%2==1:
            for j,key in enumerate([chord[2]+12,chord[1]+12]):add(note(key,1.2,.04),start+beat*(1.5+j),.35)
        for k in range(8):
            t=np.arange(int(.055*sr))/sr;noise=rng.normal(0,1,len(t));noise=np.r_[0,np.diff(noise)]
            add(noise*np.exp(-t*80)*.005,start+k*beat/2,(-1)**k*.55)
        for k in [0,2]:
            t=np.arange(int(.22*sr))/sr
            add(np.sin(2*np.pi*(48*t+1.8*(1-np.exp(-t*25))))*np.exp(-t*23)*.045,start+k*beat)
    time=np.arange(n)/sr;fade=np.minimum(1,time/1.4)*np.minimum(1,(duration-time)/2)
    duck=np.ones(n)*.6
    for c in cues:
        a=c['start']/FPS;b=(c['start']+c['duration'])/FPS
        mask=(time>a-.2)&(time<b+.35);duck[mask]=np.minimum(duck[mask],.32)
    # Slow gain edges prevent pumping/clicks.
    kernel=np.ones(int(sr*.15));kernel/=len(kernel);duck=np.convolve(duck[::320],np.ones(15)/15,'same').repeat(320)[:n]
    mix*=fade[:,None]*duck[:,None]
    wav(audio/'gathering-bed.wav',mix,sr)
    t=np.arange(int(.42*sr))/sr;chime=.10*np.sin(2*np.pi*880*t)*np.exp(-t*12)+.05*np.sin(2*np.pi*1320*t)*np.exp(-t*14)
    wav(audio/'reveal-chime.wav',chime,sr)
    ffmpeg=next((ROOT/'node_modules/.pnpm').glob('@remotion+compositor-win32*/node_modules/@remotion/compositor-win32*/ffmpeg.exe'))
    clips=['host_build_room','friend_join_room','got the name','lock-in-answer','other-answer','other-answer-split-websocket','guess-my-name','reveal-result']
    footage=ROOT/'public/footage';footage.mkdir(exist_ok=True)
    for clip in clips:
        target=footage/f'{clip}.mp4'
        if not target.exists():subprocess.run([str(ffmpeg),'-v','error','-y','-i',str(Path('C:/Users/lky24/Videos')/f'{clip}.mkv'),'-c:v','copy','-an','-movflags','+faststart',str(target)],check=True)
    print('TOTAL',cursor/FPS,'seconds',flush=True)

if __name__=='__main__':main()
