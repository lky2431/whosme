import React, {useEffect, useState} from 'react';
import {AbsoluteFill, Audio, continueRender, delayRender, Easing, Img, interpolate, OffthreadVideo, Sequence, spring, staticFile, useCurrentFrame} from 'remotion';
import data from './content-v2.json';
import {Hook, Why, Payoff} from './Film';

const ink='#171A20',paper='#FFF8ED',yellow='#FFD629',blue='#50C9EE';
const clamp={extrapolateLeft:'clamp' as const,extrapolateRight:'clamp' as const};
const smooth=(f:number,a:number,b:number)=>interpolate(f,[a,b],[0,1],{...clamp,easing:Easing.inOut(Easing.cubic)});
type Camera=[number,number,number];
type Shot={file:string;from:number;seconds:number;length:number;camera:Camera;to?:Camera};
// Source coordinates are measured against the supplied 1920x1080 recordings.
// Every crop excludes the browser sidebar. Speed changes preserve click/result order.
const shots:Record<string,Shot[]>={
 host:[{file:'host_build_room',from:.8,seconds:10.8,length:5,camera:[800,160,1100],to:[800,440,1100]}, {file:'host_build_room',from:12.25,seconds:1.35,length:2,camera:[290,180,1400],to:[325,230,1270]}],
 join:[{file:'friend_join_room',from:1.4,seconds:7.3,length:3.5,camera:[840,200,1080],to:[840,400,1080]},{file:'friend_join_room',from:8.7,seconds:1.4,length:1.5,camera:[280,115,1510]}],
 identity:[{file:'got the name',from:3.6,seconds:3,length:3,camera:[460,65,1180],to:[530,90,1020]}],
 answer:[{file:'lock-in-answer',from:0,seconds:1.6,length:1.5,camera:[490,120,1100],to:[490,420,1100]},{file:'lock-in-answer',from:7.9,seconds:2.2,length:3,camera:[490,430,1100]},{file:'lock-in-answer',from:10.1,seconds:2.4,length:2.5,camera:[490,90,1100],to:[520,90,1040]}],
 next:[{file:'other-answer',from:7.4,seconds:2.9,length:4,camera:[475,120,1200]}],
 guess:[{file:'guess-my-name',from:1.1,seconds:3.1,length:3.5,camera:[450,140,1220]},{file:'guess-my-name',from:10.7,seconds:3.1,length:3.5,camera:[460,390,1190],to:[490,440,1100]}],
 reveal:[{file:'reveal-result',from:.2,seconds:3.55,length:5,camera:[430,80,1270],to:[470,100,1180]}],
 sync:[{file:'other-answer-split-websocket',from:4.4,seconds:3.9,length:5,camera:[98,13,1810]}],
};

function ShotView({shot}:{shot:Shot}){
 const f=useCurrentFrame();const p=smooth(f,8,shot.length*30-12);const dest=shot.to??shot.camera;
 const [x,y,w]=shot.camera.map((v,i)=>v+(dest[i]-v)*p);const scale=1920/w;
 return <AbsoluteFill style={{overflow:'hidden',background:paper}}><OffthreadVideo src={staticFile(`footage/${shot.file}.mp4`)} startFrom={Math.round(shot.from*30)} playbackRate={shot.seconds/shot.length} muted style={{position:'absolute',width:1920,height:1080,maxWidth:'none',transformOrigin:'0 0',transform:`translate(${-x*scale}px,${-y*scale}px) scale(${scale})`}}/></AbsoluteFill>;
}
function Footage({id}:{id:string}){let cursor=0;return <>{shots[id].map((shot,i)=>{const start=cursor;cursor+=Math.round(shot.length*30);return <Sequence key={i} from={start} durationInFrames={Math.round(shot.length*30)}><ShotView shot={shot}/></Sequence>;})}</>;}
function Badge({children}:{children:React.ReactNode}){return <div style={{position:'absolute',left:36,top:28,background:ink,color:paper,padding:'12px 22px',borderRadius:40,fontSize:23,fontWeight:850,boxShadow:'0 3px 18px #0002'}}>{children}</div>;}
function Identity(){const f=useCurrentFrame();return <AbsoluteFill style={{background:paper}}><div style={{position:'absolute',left:100,top:180,fontSize:76,fontWeight:950}}>Borrow a friend's name.</div><div style={{position:'absolute',left:220,top:425,display:'flex',gap:100,alignItems:'center',transform:`scale(${.9+.1*spring({frame:f,fps:30})})`}}><div style={{background:yellow,padding:'55px 85px',border:'3px solid',borderRadius:32,fontSize:62,fontWeight:900}}>Alice</div><span style={{fontSize:95}}>→</span><div style={{background:blue,padding:'55px 85px',border:'3px solid',borderRadius:32,fontSize:62,fontWeight:900}}>Play Ben</div></div><div style={{position:'absolute',top:735,left:230,fontSize:37}}>Keep it secret. Answer as your friend.</div></AbsoluteFill>;}

function Devices(){const f=useCurrentFrame();return <AbsoluteFill style={{background:paper}}><div style={{position:'absolute',left:90,top:115,fontSize:60,fontWeight:950,lineHeight:1.1}}>One Flutter game.<br/>Different screens.</div><div style={{position:'absolute',left:95,top:295,fontSize:23,color:'#62645F'}}>Responsive web · captured in Chrome</div>{[
 {file:'desktop',x:690,y:360,w:1120,h:511.7,r:18,delay:0},
 {file:'tablet',x:110,y:495,w:570,h:406.9,r:26,delay:10},
 {file:'phone',x:1450,y:400,w:260,h:487.3,r:36,delay:20},
 ].map(d=><div key={d.file} style={{position:'absolute',left:d.x,top:d.y,width:d.w,height:d.h,border:'12px solid #171A20',borderRadius:d.r,overflow:'hidden',background:paper,boxShadow:'10px 16px 0 #171A2020',transform:`translateY(${(1-spring({frame:f-d.delay,fps:30,config:{damping:19}}))*90}px)`}}>{d.file==='desktop'&&<div style={{position:'absolute',zIndex:1,top:0,left:0,right:0,height:28,background:ink,color:'#eee',fontSize:13,paddingLeft:18}}>● ● ●　 whosme-511315.web.app</div>}<Img src={staticFile(`devices/${d.file}.png`)} style={{width: d.file==='phone'?'420.26%':d.file==='tablet'?'160.06%':'102.44%',height:'auto',maxWidth:'none'}}/></div>)}</AbsoluteFill>;}

function Serverpod(){const f=useCurrentFrame();const items=[['Dart end to end','One language, app to server.',yellow],['Generated Flutter client','Typed calls. Less glue code.',blue],['Models + migrations','Typed models. Managed migrations.','#FF937C'],['Built-in streaming','Live answers across the room.','#BDB2F5']];return <AbsoluteFill style={{background:paper}}><div style={{position:'absolute',left:100,top:135,fontSize:80,fontWeight:950,lineHeight:1.07}}>More game.<br/>Less backend plumbing.</div><div style={{position:'absolute',right:110,top:175,fontSize:40,fontWeight:950,background:yellow,border:'3px solid',borderRadius:50,padding:'20px 35px'}}>Flutter + Serverpod</div><div style={{position:'absolute',left:100,right:100,top:395,display:'grid',gridTemplateColumns:'1fr 1fr',gap:28}}>{items.map(([title,sub,color],i)=><div key={title} style={{background:color,border:'3px solid',borderRadius:28,padding:'32px 36px',height:165,boxSizing:'border-box',boxShadow:'7px 8px 0 #171A20',opacity:interpolate(f,[i*8,i*8+10],[0,1],clamp),transform:`translateY(${(1-spring({frame:f-i*8,fps:30,config:{damping:20}}))*30}px)`}}><div style={{fontSize:37,fontWeight:950}}>{title}</div><div style={{fontSize:27,marginTop:10}}>{sub}</div></div>)}</div></AbsoluteFill>;}
function Outro(){return <AbsoluteFill style={{background:blue,alignItems:'center',justifyContent:'center'}}><div style={{fontSize:165,fontWeight:950,letterSpacing:-7}}>who’s me?</div><div style={{fontSize:60,fontWeight:900,margin:'20px 0'}}>Think like a friend.</div><div style={{fontSize:30,padding:'16px 30px',borderRadius:50,background:yellow,fontWeight:900}}>Built with Flutter + Serverpod</div><div style={{fontSize:32,marginTop:35}}>whosme-511315.web.app</div></AbsoluteFill>;}
const labels:Record<string,string>={host:'01 / Create a room',join:'02 / Bring your friends',identity:'03 / Think like them',answer:'04 / Lock in your answer',next:'Together, question by question',guess:'05 / Find your double',reveal:'06 / The reveal',sync:'Two live sessions · Serverpod streams'};
function Scene({id,duration}:{id:string;duration:number}){const f=useCurrentFrame();let body:React.ReactNode;
 if(id==='identity')body=<><Sequence durationInFrames={90}><Identity/></Sequence><Sequence from={90} durationInFrames={duration-90}><Footage id={id}/></Sequence></>;
 else if(shots[id])body=<Footage id={id}/>;
 else body=id==='hook'?<Hook/>:id==='why'?<Why/>:id==='devices'?<Devices/>:id==='serverpod'?<Serverpod/>:id==='payoff'?<Payoff/>:<Outro/>;
 return <AbsoluteFill style={{background:paper,opacity:interpolate(f,[0,5],[0,1],clamp)}}>{body}{labels[id]&&<Badge>{labels[id]}</Badge>}{!labels[id]&&id!=='outro'&&<div style={{position:'absolute',left:90,top:40,fontSize:30,fontWeight:950}}>who’s me?</div>}</AbsoluteFill>;
}
export function FilmV2(){const f=useCurrentFrame();const [handle]=useState(()=>delayRender('Nunito'));useEffect(()=>{const font=new FontFace('Nunito',`url(${staticFile('fonts/Nunito.ttf')})`,{weight:'200 1000'});font.load().then(v=>{document.fonts.add(v);continueRender(handle);}).catch(()=>continueRender(handle));},[handle]);const cue=data.cues.find(c=>f>=c.start&&f<c.start+c.duration);
 return <AbsoluteFill style={{background:paper,color:ink,fontFamily:'Nunito, sans-serif'}}>{data.scenes.map(s=><Sequence key={s.id} from={s.start} durationInFrames={s.duration}><Scene id={s.id} duration={s.duration}/></Sequence>)}<Audio src={staticFile('audio-v2/gathering-bed.wav')}/>{data.cues.map(c=><Sequence key={c.file} from={c.start} durationInFrames={c.duration}><Audio src={staticFile(c.file)} volume={.95}/></Sequence>)}<Sequence from={1538} durationInFrames={15}><Audio src={staticFile('audio-v2/reveal-chime.wav')} volume={.5}/></Sequence>{cue&&<div style={{position:'absolute',left:180,right:180,bottom:30,display:'flex',justifyContent:'center',pointerEvents:'none'}}><div style={{background:'#171A20ee',color:paper,padding:'12px 26px',borderRadius:16,fontSize:29,fontWeight:700,textAlign:'center',lineHeight:1.3,maxWidth:1480}}>{cue.text}</div></div>}</AbsoluteFill>;
}
