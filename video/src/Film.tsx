import React, {useEffect, useState} from 'react';
import {AbsoluteFill, Audio, continueRender, delayRender, interpolate, OffthreadVideo, Sequence, spring, staticFile, useCurrentFrame} from 'remotion';
import content from './content.json';

const C = {paper:'#FFF8ED', ink:'#171A20', blue:'#50C9EE', yellow:'#FFD629', coral:'#FF937C', lavender:'#BDB2F5', mint:'#CDF0F6', muted:'#62645F'};
const colors = [C.yellow,C.blue,C.coral,C.lavender];
const clamp = {extrapolateLeft:'clamp' as const,extrapolateRight:'clamp' as const};
const ramp = (f:number,a:number,b:number) => interpolate(f,[a,b],[0,1],clamp);
const pop = (f:number,delay=0) => spring({frame:f-delay,fps:30,config:{damping:17,stiffness:100,mass:0.8}});
const name = (i:number) => content.players[i];
type SlotId = keyof typeof content.slots;

function Burst({size=120,color=C.yellow}:{size?:number;color?:string}) {
  const points = Array.from({length:24},(_,i)=>{const a=i*Math.PI/12;const r=i%2?38:50;return `${50+Math.cos(a)*r},${50+Math.sin(a)*r}`;}).join(' ');
  return <svg width={size} height={size} viewBox="0 0 100 100"><polygon points={points} fill={color}/></svg>;
}

function Face({i,size=160,look=0}:{i:number;size?:number;look?:number}) {
  const f=useCurrentFrame();
  const blink=(f+i*19)%147<5;
  return <svg width={size} height={size} viewBox="0 0 160 160" style={{overflow:'visible'}}>
    <path d={i===0?'M27 40 L33 7 L62 26 Q84 16 104 28 L137 10 L134 56 Q155 132 83 145 Q13 145 27 40':i===2?'M39 58 Q4 -3 27 -8 Q48 -13 58 52 L95 52 Q105 -14 129 -8 Q151 7 120 62 Q149 136 80 145 Q15 140 39 58':i===3?'M24 50 Q0 7 32 12 Q50 13 53 33 Q80 22 108 34 Q120 4 144 19 Q166 40 137 58 Q151 141 82 146 Q6 144 24 50':'M20 55 L19 8 L66 34 L96 34 L141 8 L139 62 Q145 126 82 148 Q11 128 20 55'} fill={colors[i]} stroke={C.ink} strokeWidth="4" strokeLinejoin="round"/>
    {i===1?<path d="M24 76 Q35 101 77 109 Q124 100 137 76 Q133 137 81 145 Q25 125 24 76" fill={C.paper}/>:null}
    <ellipse cx="46" cy="105" rx="13" ry="8" fill={C.coral} opacity=".5"/><ellipse cx="115" cy="105" rx="13" ry="8" fill={C.coral} opacity=".5"/>
    <g transform={`translate(${look},0)`} fill={C.ink}>
      <ellipse cx="57" cy="80" rx="4.5" ry={blink?1.5:7}/><ellipse cx="104" cy="80" rx="4.5" ry={blink?1.5:7}/>
      <path d="M74 98 Q80 93 87 98 L80 105 Z"/><path d="M64 114 Q81 132 99 111" fill="none" stroke={C.ink} strokeWidth="4" strokeLinecap="round"/>
    </g>
  </svg>;
}

function Person({i,x,y,size=160,delay=0,label=true,rotate=0}:{i:number;x:number;y:number;size?:number;delay?:number;label?:boolean;rotate?:number}) {
  const f=useCurrentFrame();const p=pop(f,delay);
  return <div style={{position:'absolute',left:x,top:y,width:size,textAlign:'center',opacity:ramp(f,delay,delay+8),transform:`translateY(${(1-p)*70+Math.sin(f/24+i)*5}px) rotate(${rotate}deg) scale(${p})`}}>
    <Face i={i} size={size}/>{label?<div style={{fontSize:30,fontWeight:850,marginTop:16}}>{name(i)}</div>:null}
  </div>;
}

function Card({children,x,y,w=360,h=210,color='white',rotate=0,delay=0,style={}}:{children:React.ReactNode;x:number;y:number;w?:number;h?:number;color?:string;rotate?:number;delay?:number;style?:React.CSSProperties}) {
  const f=useCurrentFrame();const p=pop(f,delay);
  return <div style={{position:'absolute',left:x,top:y,width:w,height:h,background:color,border:`3px solid ${C.ink}`,borderRadius:28,padding:30,boxSizing:'border-box',boxShadow:`9px 10px 0 ${C.ink}`,opacity:ramp(f,delay,delay+8),transform:`translateY(${(1-p)*65}px) rotate(${rotate}deg) scale(${0.9+0.1*p})`,...style}}>{children}</div>;
}

function Heading({eyebrow,title,sub,width=1000}:{eyebrow?:string;title:string;sub?:string;width?:number}) {
 const f=useCurrentFrame();return <div style={{position:'absolute',left:100,top:150,width,transform:`translateY(${(1-pop(f))*36}px)`,opacity:ramp(f,0,10)}}>
   {eyebrow?<div style={{fontSize:24,fontWeight:900,letterSpacing:4,marginBottom:20}}>{eyebrow}</div>:null}
   <div style={{fontSize:80,fontWeight:950,lineHeight:1.06,letterSpacing:-3,whiteSpace:'pre-line'}}>{title}</div>
   {sub?<div style={{fontSize:31,color:C.muted,lineHeight:1.4,marginTop:24,maxWidth:760}}>{sub}</div>:null}
 </div>;
}

function Arrow({x,y,w=200,color=C.ink,delay=0,rotate=0}:{x:number;y:number;w?:number;color?:string;delay?:number;rotate?:number}) {
 const f=useCurrentFrame();return <svg width={w} height="80" viewBox="0 0 200 80" style={{position:'absolute',left:x,top:y,transform:`rotate(${rotate}deg)`,opacity:ramp(f,delay,delay+12)}}>
   <path d="M8 44 Q95 8 182 40 M157 19 L183 40 L151 54" fill="none" stroke={color} strokeWidth="5" strokeLinecap="round" strokeLinejoin="round" pathLength="1" strokeDasharray="1" strokeDashoffset={1-ramp(f,delay,delay+35)}/>
 </svg>;
}

function Footage({id,x=975,y=305,w=845,h=475}:{id:SlotId;x?:number;y?:number;w?:number;h?:number}) {
 const f=useCurrentFrame();const slot=content.slots[id];
 return <div style={{position:'absolute',left:x,top:y,width:w,height:h,borderRadius:28,background:C.ink,overflow:'hidden',boxShadow:'14px 16px 0 #171A2014',transform:`translateY(${(1-pop(f,8))*60}px)`}}>
  <div style={{height:48,display:'flex',alignItems:'center',gap:9,padding:'0 20px',background:'#292D32'}}>{[C.coral,C.yellow,C.blue].map(c=><span key={c} style={{width:10,height:10,borderRadius:20,background:c}}/>)}<span style={{fontSize:16,color:'#CFD4D7',marginLeft:14}}>who’s me? / web app</span></div>
  {slot.file?<OffthreadVideo src={staticFile(slot.file)} startFrom={slot.trimBefore} muted style={{width:'100%',height:h-48,objectFit:'contain'}}/>:<div style={{height:h-48,position:'relative',display:'flex',flexDirection:'column',alignItems:'center',justifyContent:'center',padding:'0 50px',textAlign:'center',boxSizing:'border-box',color:C.paper,backgroundImage:'radial-gradient(#ffffff17 1.3px, transparent 1.3px)',backgroundSize:'22px 22px'}}>
    <div style={{fontSize:16,fontWeight:900,letterSpacing:3,color:C.yellow,border:'1px solid #FFD62966',borderRadius:30,padding:'9px 20px'}}>RECORDING TO BE ADDED</div>
    <div style={{width:65,height:65,border:'2px solid #ffffff55',borderRadius:20,margin:'23px 0',display:'grid',placeItems:'center',transform:`rotate(${Math.sin(f/45)*5}deg)`}}><svg width="28" height="28" viewBox="0 0 28 28"><path d="M7 3 L25 14 L7 25Z" fill={C.paper}/></svg></div>
    <div style={{fontSize:29,fontWeight:900}}>{slot.label}</div>
    <div style={{fontSize:23,lineHeight:1.4,color:'#C8D0D3',marginTop:14}}>{slot.instruction}</div>
    <div style={{position:'absolute',bottom:20,left:24,right:24,height:3,background:'#ffffff22'}}><div style={{height:3,width:`${(f%(slot.duration*30))/(slot.duration*30)*100}%`,background:C.yellow}}/></div>
  </div>}
 </div>;
}

export function Hook() {
 const f=useCurrentFrame();return <>
  <div style={{position:'absolute',left:95,top:225,width:980,fontSize:122,fontWeight:950,lineHeight:1.01,letterSpacing:-5}}>They know<br/>your <span style={{background:C.yellow,padding:'0 20px',display:'inline-block',transform:'rotate(-3deg)'}}>name.</span></div>
  <div style={{position:'absolute',left:100,top:630,fontSize:69,fontWeight:900,opacity:ramp(f,85,105),transform:`translateY(${(1-pop(f,85))*40}px)`}}>Do they know <span style={{textDecoration:'underline',textDecorationColor:C.blue,textDecorationThickness:10}}>you?</span></div>
  <Person i={0} x={1170} y={290} size={245} rotate={-8}/><Person i={1} x={1500} y={490} size={220} delay={15} rotate={8}/>
  <Card x={1400} y={150} w={350} h={205} color={C.blue} rotate={7} delay={40}><div style={{fontSize:38,fontWeight:900,lineHeight:1.18}}>“Definitely<br/>a night owl.”</div></Card>
  <div style={{position:'absolute',left:1125,top:665,transform:`rotate(${f/5}deg)`}}><Burst size={140}/></div>
 </>;
}

export function Why() {
 const f=useCurrentFrame();return <>
  <Heading title={'Made for\nfriend gatherings.'} sub="A little imagination. A lot to talk about." width={840}/>
  <div style={{position:'absolute',left:970,top:375,width:730,height:370,background:C.blue,border:`4px solid ${C.ink}`,borderRadius:'50%',transform:'rotate(-10deg)',boxShadow:`0 18px 0 ${C.ink}`}}/>
  <Person i={0} x={975} y={220} size={165}/><Person i={1} x={1470} y={245} size={165} delay={12}/><Person i={2} x={990} y={670} size={165} delay={24}/><Person i={3} x={1540} y={635} size={165} delay={36}/>
  <Card x={1230} y={430} w={245} h={175} color={C.yellow} rotate={-12} delay={50}><div style={{fontSize:45,fontWeight:950,lineHeight:1.1}}>who’s<br/>me?</div></Card>
  {['Laugh together.','Start a conversation.','Know each other better.'].map((t,i)=><div key={t} style={{position:'absolute',left:105,top:525+i*106,fontSize:38,fontWeight:800,opacity:ramp(f,55+i*55,70+i*55),transform:`translateX(${(1-pop(f,55+i*55))*-70}px)`}}><span style={{color:[C.blue,C.coral,C.ink][i],marginRight:18}}>✳</span>{t}</div>)}
 </>;
}

function Join() {return <><Heading title={'One room.\nYour people.'} sub="4–20 friends · No account needed" width={800}/><div style={{position:'absolute',left:110,top:510,display:'flex',gap:18}}>{content.players.map((_,i)=><div key={i} style={{width:165,textAlign:'center'}}><Face i={i} size={145}/><div style={{fontSize:28,fontWeight:800,marginTop:18}}>{name(i)}</div></div>)}</div><Card x={210} y={755} w={470} h={95} color={C.yellow} rotate={-3}><div style={{fontSize:29,fontWeight:900,textAlign:'center'}}>One code brings everyone in.</div></Card><Footage id="join"/></>;}

function Identity() {
 const f=useCurrentFrame();const travel=ramp(f,28,90);return <>
  <Heading title={'Borrow a name.'} sub="Everyone gets someone else. Keep it secret." width={840}/>
  <Person i={0} x={115} y={520} size={200}/><Person i={1} x={640} y={520} size={200}/>
  <Arrow x={350} y={555} w={220} delay={16} rotate={180}/>
  <Card x={580-travel*275} y={445-Math.sin(travel*Math.PI)*80} w={260} h={180} color={C.blue} rotate={10-travel*16} delay={22}>
    <div style={{fontSize:19,letterSpacing:3}}>HELLO, TODAY I’M</div><div style={{fontSize:65,fontWeight:950,marginTop:8}}>{name(content.assignments[0])}</div>
  </Card><div style={{position:'absolute',left:260,top:840,fontSize:29,fontWeight:800,opacity:ramp(f,100,115)}}>Alice answers as Ben.</div><Footage id="identity"/>
 </>;
}

function Answer() {
 const f=useCurrentFrame();const selected=f>135;return <>
  <Heading title={'Think like Ben.'} sub="What would your friend choose?" width={800}/>
  <Person i={0} x={105} y={425} size={160}/>
  <div style={{position:'absolute',left:300,top:390,width:590,fontSize:35,fontWeight:900,lineHeight:1.2}}>{content.question}</div>
  {content.choices.map((c,i)=><div key={c} style={{position:'absolute',left:310,top:510+i*74,width:525,height:60,borderRadius:16,border:`2px solid ${C.ink}`,background:selected&&i===0?C.yellow:'white',display:'flex',alignItems:'center',gap:20,padding:'0 20px',fontSize:26,boxSizing:'border-box',opacity:ramp(f,20+i*12,32+i*12),transform:`translateX(${(1-pop(f,20+i*12))*45}px)`}}><b>{'ABCD'[i]}</b>{c}{selected&&i===0?<b style={{marginLeft:'auto'}}>✓</b>:null}</div>)}
  <div style={{position:'absolute',left:115,top:700,fontSize:23,fontWeight:800,width:160,textAlign:'center',opacity:ramp(f,130,155)}}>“That’s so<br/>Ben.”</div>
  <div style={{position:'absolute',left:310,top:837,fontSize:26,fontWeight:900,color:C.muted,opacity:ramp(f,240,260)}}>{f<350?'Answer locked. Waiting for friends…':'Everyone’s in. Next question →'}</div>
  <Footage id="answer"/>
 </>;
}

function Guess() {
 const f=useCurrentFrame();return <>
  <Heading title={'Who was\nplaying you?'} sub="Read their answers. Follow the clues." width={825}/>
  <Person i={1} x={120} y={620} size={180}/>
  {[0,2,3].map((i,j)=><Card key={i} x={390+j*145} y={535+j*30} w={205} h={235} rotate={-12+j*12} color={i===0&&f>145?C.yellow:'white'} delay={15+j*15}><div style={{fontSize:27,fontWeight:900}}>{name(i)}</div><div style={{marginTop:18,height:8,width:110,background:C.blue,borderRadius:5}}/><div style={{marginTop:16,height:8,width:85,background:C.coral,borderRadius:5}}/><div style={{fontSize:53,fontWeight:900,marginTop:12}}>{i===0&&f>145?'✓':'?'}</div></Card>)}
  <Arrow x={260} y={715} w={155} delay={135} rotate={-30}/><Footage id="guess"/>
 </>;
}

function Reveal() {
 const f=useCurrentFrame();return <>
  <Heading title={'It was Alice!'} sub="Alice was answering as Ben." width={830}/>
  <Person i={0} x={160} y={480} size={220}/><Person i={1} x={620} y={480} size={220} delay={15}/><Arrow x={390} y={560} delay={30}/>
  <div style={{position:'absolute',left:350,top:770,background:C.yellow,padding:'12px 30px',borderRadius:50,fontSize:38,fontWeight:950,transform:`scale(${pop(f,40)})`}}>Correct guess! +1</div>
  {Array.from({length:18},(_,i)=><div key={i} style={{position:'absolute',left:100+(i*137)%790,top:340+((f*2+i*71)%520),width:9,height:22,background:colors[i%4],opacity:ramp(f,35,45),transform:`rotate(${f*3+i*19}deg)`}}/>)}
  <Footage id="reveal"/>
 </>;
}

function Architecture() {
 const f=useCurrentFrame();const packets=(f%90)/90;return <>
  <Heading title={'A shared game.\nA Dart-powered backend.'} sub="Flutter + Serverpod + PostgreSQL" width={1650}/>
  <Card x={105} y={550} w={470} h={275} color={C.blue}><div style={{fontSize:41,fontWeight:950}}>Flutter</div><div style={{fontSize:26,marginTop:12}}>Four connected players</div><div style={{display:'flex',gap:14,marginTop:20}}>{[0,1,2,3].map(i=><Face key={i} i={i} size={70}/>)}</div></Card>
  <Card x={735} y={525} w={440} h={325} color={C.yellow} delay={20}><div style={{fontSize:48,fontWeight:950}}>Serverpod</div><div style={{fontSize:29,marginTop:17,lineHeight:1.5}}>Game rules<br/>Private player views<br/>Streaming updates</div></Card>
  <Card x={1345} y={550} w={470} h={275} color="white" delay={40}><div style={{fontSize:41,fontWeight:950}}>PostgreSQL</div><div style={{fontSize:29,marginTop:20,lineHeight:1.5}}>Question bank<br/>Saved room state</div></Card>
  <Arrow x={565} y={660} w={170} delay={20}/><Arrow x={1175} y={660} w={165} delay={40}/>
  <div style={{position:'absolute',left:590+packets*115,top:674,width:18,height:18,borderRadius:5,background:C.ink}}/>
  <div style={{position:'absolute',left:130,top:875,fontSize:23,fontWeight:800}}>Generated Dart client</div><div style={{position:'absolute',left:755,top:890,fontSize:23,fontWeight:800}}>The server is the referee.</div>
 </>;
}

function Privacy() {
 const f=useCurrentFrame();return <>
  <Heading title={'Shared rules.\nPrivate identities.'} sub="The right information, to the right player." width={960}/>
  <Card x={190} y={515} w={620} h={310} color={C.yellow}><div style={{fontSize:43,fontWeight:950}}>Serverpod checks</div>{['Valid player & action','One locked answer per question','Advance when everyone is ready'].map((t,i)=><div key={t} style={{fontSize:28,marginTop:21,opacity:ramp(f,i*35+15,i*35+30)}}>✓ {t}</div>)}</Card>
  {[0,1,2,3].map((i)=><React.Fragment key={i}><div style={{position:'absolute',left:1175,top:190+i*170,display:'flex',alignItems:'center',gap:30,opacity:ramp(f,20+i*20,40+i*20)}}><Face i={i} size={115}/><div style={{background:colors[i],border:`2px solid ${C.ink}`,borderRadius:20,padding:'15px 28px',width:260,fontSize:25}}>For {name(i)} only<br/><b style={{fontSize:34}}>Play {name(content.assignments[i])}</b></div></div><Arrow x={970} y={235+i*170} w={170} delay={35+i*20}/></React.Fragment>)}
 </>;
}

function Sync() {
 const f=useCurrentFrame();const n=Math.min(4,Math.floor(f/38));return <>
  <Heading title={'Together,\nquestion by question.'} sub="Native WebSocket streams + persisted room state" width={870}/>
  <div style={{position:'absolute',left:110,top:495,display:'flex',gap:18}}>{[0,1,2,3].map(i=><div key={i} style={{width:163,padding:'24px 0',textAlign:'center',border:`2px solid ${C.ink}`,borderRadius:25,background:i<n?colors[i]:'white',transform:`translateY(${i<n?-12:0}px)`}}><Face i={i} size={100}/><div style={{fontSize:27,fontWeight:900,marginTop:18}}>{i<n?'Ready ✓':'Thinking…'}</div></div>)}</div>
  <div style={{position:'absolute',left:115,top:735,fontSize:40,fontWeight:950}}>{n<4?`${n} / 4 answers in`:'Next question →'}</div>
  <div style={{position:'absolute',left:115,top:815,fontSize:27,color:C.muted,opacity:ramp(f,170,190)}}>Refresh → reconnect → continue.</div><Footage id="sync"/>
 </>;
}

export function Payoff() {
 const f=useCurrentFrame();return <>
  <Heading title={'The reveal starts\na conversation.'} width={1300}/>
  <Person i={0} x={195} y={625} size={210}/><Person i={1} x={690} y={625} size={210} delay={15}/><Person i={2} x={1190} y={625} size={210} delay={30}/><Person i={3} x={1540} y={625} size={170} delay={45}/>
  <Card x={130} y={420} w={560} h={165} color={C.yellow} rotate={-4} delay={20}><div style={{fontSize:40,fontWeight:950}}>“You think I’d<br/>choose THAT?”</div></Card>
  <Card x={970} y={405} w={680} h={175} color={C.blue} rotate={4} delay={80}><div style={{fontSize:39,fontWeight:950,lineHeight:1.2}}>“Wait, let me explain…”</div><div style={{fontSize:26,marginTop:12}}>And suddenly, there’s a story.</div></Card>
 </>;
}

function Outro() {
 const f=useCurrentFrame();return <>
  <div style={{position:'absolute',left:130,top:190,transform:`rotate(${f/8}deg)`}}><Burst size={190}/></div>
  <div style={{position:'absolute',left:0,right:0,top:210,textAlign:'center',transform:`scale(${.94+.06*pop(f)})`}}>
    <div style={{fontSize:170,fontWeight:950,letterSpacing:-8}}>{content.title}</div><div style={{fontSize:56,fontWeight:850,marginTop:30}}>{content.tagline}</div><div style={{fontSize:37,color:C.muted,marginTop:10}}>Discover how they see you.</div>
    <div style={{display:'inline-flex',alignItems:'center',gap:24,background:C.blue,borderRadius:50,padding:'16px 34px',fontSize:29,fontWeight:900,marginTop:52}}>Built with Flutter <span>+</span> Serverpod</div>
    {content.playUrl?<div style={{fontSize:28,marginTop:24}}>{content.playUrl}</div>:null}
  </div><Person i={0} x={95} y={710} size={175} label={false}/><Person i={1} x={1620} y={635} size={190} label={false} delay={15}/>
 </>;
}

const scenes:Record<string,React.ComponentType>={hook:Hook,why:Why,join:Join,identity:Identity,answer:Answer,guess:Guess,reveal:Reveal,architecture:Architecture,privacy:Privacy,sync:Sync,payoff:Payoff,outro:Outro};

function Scene({id,chapter,duration}:{id:string;chapter:string;duration:number}) {
 const f=useCurrentFrame();const Component=scenes[id];const blue=id==='outro';
 return <AbsoluteFill style={{background:C.paper,opacity:interpolate(f,[0,7,duration-7,duration-1],[0,1,1,0],clamp)}}>
   <div style={{position:'absolute',inset:0,backgroundImage:'radial-gradient(#171A2014 1px, transparent 1px)',backgroundSize:'25px 25px',opacity:.45}}/>
   <div style={{position:'absolute',right:-190,top:-360,width:780,height:780,borderRadius:'50%',background:blue?C.yellow:'#CDF0F633'}}/>
   <div style={{position:'absolute',left:100,right:100,top:48,display:'flex',alignItems:'center',justifyContent:'space-between'}}><div style={{fontSize:32,fontWeight:950}}>{content.title}</div><div style={{fontSize:19,fontWeight:850,letterSpacing:3}}>{chapter}</div></div>
   <Component/>
 </AbsoluteFill>;
}

export function Film() {
 const f=useCurrentFrame();const [fontHandle]=useState(()=>delayRender('Loading bundled Nunito'));
 useEffect(()=>{let disposed=false; const face=new FontFace('Nunito',`url(${staticFile('fonts/Nunito.ttf')})`,{weight:'200 1000'});face.load().then(font=>{document.fonts.add(font);if(!disposed)continueRender(fontHandle);}).catch(()=>continueRender(fontHandle));return()=>{disposed=true;};},[fontHandle]);
 const cue=content.cues.find(c=>f>=Math.round(c.start*30)&&f<Math.round(c.end*30));
 return <AbsoluteFill style={{background:C.paper,color:C.ink,fontFamily:'Nunito, sans-serif'}}>
  {content.scenes.map(s=><Sequence key={s.id} name={s.chapter} from={s.start*30} durationInFrames={(s.end-s.start)*30}><Scene id={s.id} chapter={s.chapter} duration={(s.end-s.start)*30}/></Sequence>)}
  {content.scratchVoice?content.cues.map((c,i)=><Sequence key={i} name={`Scratch VO ${i+1}`} from={Math.round(c.start*30)} durationInFrames={Math.round((c.end-c.start)*30)}><Audio src={staticFile(`audio/vo-${String(i+1).padStart(2,'0')}.wav`)}/></Sequence>):null}
  {cue?<div style={{position:'absolute',left:180,right:180,bottom:44,display:'flex',justifyContent:'center'}}><div style={{background:C.ink,color:C.paper,padding:'14px 28px',borderRadius:16,fontSize:29,fontWeight:650,textAlign:'center',lineHeight:1.35,maxWidth:1460}}>{cue.text}</div></div>:null}
  {content.draft?<div style={{position:'absolute',left:100,bottom:12,fontSize:14,fontWeight:750,color:C.muted,letterSpacing:1.4}}>ANIMATION DRAFT · {content.scratchVoice?'TEMPORARY COMPUTER VOICE · ':''}GAMEPLAY RECORDINGS PENDING</div>:null}
  <div style={{position:'absolute',bottom:0,left:0,height:5,width:`${f/3599*100}%`,background:C.blue}}/>
 </AbsoluteFill>;
}
