/*
 * آفاق — Studio Engine v4 (Final)
 * ===========================================
 * Zero video. Zero zoom. Full-fill canvas.
 * Background renders directly on fabric canvas (no bg-layer).
 * Tools: Quran Search, Typography, Shadow, Layers, Snapping, Export, Guard.
 */

"use strict";
(function(){
var S={};

/* ---- STATE ---- */
S.state={
 canvasW:1080, canvasH:1080,
 bgType:'color', bgColor:'#1a1a2e', bgGradient:'midnight',
 bgImage:null, bgImageUrl:null,
 quranFontStyle:'new', fontSize:44, textColor:'#e9e3d3',
 opacity:100, shadowX:2, shadowY:2, shadowBlur:4, shadowOpacity:50,
 selectedObject:null,
 undoStack:[], redoStack:[],
 searchResults:[], searchAyahFrom:1, searchAyahTo:1, selectedAyah:null,
 isDirty:false
};

S.canvas=null; S.resizeObserver=null;
S.snapLines=[]; S.snapTimeout=null; S.els={}; S.loaderEl=null;

/* Gradients as fabric-friendly color-stop arrays (135deg diagonal) */
S.gradients={
 midnight:{angle:135,stops:[{offset:0,color:'#0a0a0a'},{offset:1,color:'#3a3a3a'}]},
 ocean:{angle:135,stops:[{offset:0,color:'#0f2027'},{offset:.5,color:'#203a43'},{offset:1,color:'#2c5364'}]},
 sunset:{angle:135,stops:[{offset:0,color:'#e96443'},{offset:1,color:'#904e95'}]},
 earth:{angle:135,stops:[{offset:0,color:'#134e5e'},{offset:1,color:'#71b280'}]},
 royal:{angle:135,stops:[{offset:0,color:'#42275a'},{offset:1,color:'#734b6d'}]},
 slate:{angle:135,stops:[{offset:0,color:'#16222a'},{offset:1,color:'#3a6073'}]}
};

/* ---- UTILITIES ---- */
function $(id){S.els[id]=document.getElementById(id);}
function qsa(id,s){var p=document.getElementById(id);return p?p.querySelectorAll(s):[];}
function ea(a,f){if(a)for(var i=0;i<a.length;i++)f(a[i],i);}
function on(el,ev,fn){if(el)el.addEventListener(ev,fn);}
function hide(id){var e=S.els[id]||document.getElementById(id);if(e)e.style.display='none';}
function showF(id){var e=S.els[id]||document.getElementById(id);if(e)e.style.display='flex';}
function txt(id,t){var e=S.els[id];if(e)e.textContent=t;}

/* ---- INIT ---- */
function init(){
 console.log('[Studio] v4');
 var ids='setup-wizard,studio-editor,s-sidebar,s-floor,studio-canvas,canvas-wrap,setup-launch,et-back,et-export,setup-presets,setup-bg-type,setup-bg-color,setup-bg-gradient,setup-bg-image,setup-bg-color-picker,setup-bg-color-hex,setup-bg-file,setup-bg-file-btn,setup-file-name,setup-gradients,et-dimensions,s-tab-bar,s-tools,s-layers,sb-quran-search,sb-quran-font,sb-font-size,sb-text-color,sb-opacity,sb-shadow-x,sb-shadow-y,sb-shadow-blur,sb-shadow-opacity,sb-shadow-blur-val,sb-shadow-opacity-val,sb-layers-list,quran-modal,qm-close,qm-input,qm-results,qm-ayah-from,qm-ayah-to,qm-insert,exit-modal,exit-cancel,exit-confirm'.split(',');
 ea(ids,function(id){$(id);});
 S.loaderEl=S.els['canvas-loader']||document.getElementById('canvas-loader');
 if(!S.els['setup-wizard']){console.error('[Studio] no wizard');return;}
 initWizard();initGuard();console.log('[Studio] ready');
}

/* ---- WIZARD ---- */
function initWizard(){
 var pb=qsa('setup-presets','button'),bb=qsa('setup-bg-type','button'),gb=qsa('setup-gradients','.setup-gradient-swatch'),ln=S.els['setup-launch'];
 ea(pb,function(b){on(b,'click',function(){ea(pb,function(x){x.classList.remove('active');});b.classList.add('active');S.state.canvasW=parseInt(b.getAttribute('data-w'),10)||1080;S.state.canvasH=parseInt(b.getAttribute('data-h'),10)||1080;});});
 ea(bb,function(b){on(b,'click',function(){ea(bb,function(x){x.classList.remove('active');});b.classList.add('active');var t=b.getAttribute('data-type');S.state.bgType=t;if(S.els['setup-bg-color'])S.els['setup-bg-color'].style.display=t==='color'?'flex':'none';if(S.els['setup-bg-gradient'])S.els['setup-bg-gradient'].style.display=t==='gradient'?'':'none';if(S.els['setup-bg-image'])S.els['setup-bg-image'].style.display=t==='image'?'':'none';});});
 var cp=S.els['setup-bg-color-picker'],ch=S.els['setup-bg-color-hex'];
 if(cp&&ch){var sy=function(){ch.value=cp.value;S.state.bgColor=cp.value;};on(cp,'input',sy);on(ch,'input',function(){if(/^#[0-9a-f]{6}$/i.test(ch.value)){cp.value=ch.value;S.state.bgColor=ch.value;}});sy();}
 ea(gb,function(el){on(el,'click',function(){ea(gb,function(s){s.classList.remove('active');});el.classList.add('active');S.state.bgGradient=el.getAttribute('data-grad')||'midnight';});});
 var fi=S.els['setup-bg-file'],fb=S.els['setup-bg-file-btn'];
 if(fi&&fb){
  on(fb,'click',function(){fi.click();});
  on(fi,'change',function(){
   var f=fi.files[0];if(!f)return;
   S.state.bgImage=f;
   if(S.state.bgImageUrl)URL.revokeObjectURL(S.state.bgImageUrl);
   S.state.bgImageUrl=URL.createObjectURL(f);
   if(S.els['setup-file-name'])S.els['setup-file-name'].textContent=f.name;
   S.state.bgType='image';
   ea(bb,function(x){x.classList.remove('active');});
   var imEl=Array.from(bb).find(function(b){return b.getAttribute('data-type')==='image';});
   if(imEl)imEl.classList.add('active');
   ['setup-bg-color','setup-bg-gradient'].forEach(function(id){var e=S.els[id];if(e)e.style.display='none';});
   if(S.els['setup-bg-image'])S.els['setup-bg-image'].style.display='';
  });
 }
 if(ln)on(ln,'click',launchEditor);
}

function launchEditor(){
 console.log('[Studio] launch');
 hide('setup-wizard');showF('studio-editor');
 var hdr=document.getElementById('studio-site-header');if(hdr)hdr.style.display='none';
 var dim=S.els['et-dimensions'];if(dim)dim.textContent=S.state.canvasW+'\u00D7'+S.state.canvasH;
 setTimeout(function(){initCanvas();if(typeof lucide!=='undefined')lucide.createIcons();},150);
}

/* ---- CANVAS ENGINE (Full-Fill, No Zoom) ---- */
function initCanvas(){
 var fl=S.els['s-floor'],ce=document.getElementById('studio-canvas');
 if(!fl||!ce){console.error('[Studio] missing elements');return;}
 if(typeof fabric==='undefined'){console.error('[Studio] fabric.js missing');return;}
 if(S.canvas){if(S.resizeObserver)S.resizeObserver.disconnect();S.canvas.dispose();S.canvas=null;}
 ce.width=S.state.canvasW;ce.height=S.state.canvasH;
 S.canvas=new fabric.Canvas(ce,{preserveObjectStacking:true,selection:true,defaultCursor:'default',backgroundColor:'transparent',renderOnAddRemove:true});
 applyBg();
 function fit(){
  if(!S.canvas)return;var f=fl.clientWidth,h=fl.clientHeight;
  if(f<=0||h<=0){setTimeout(fit,50);return;}
  var cw=S.state.canvasW,ch=S.state.canvasH,z=Math.min(f/cw,h/ch);
  S.canvas.setZoom(z);S.canvas.setWidth(cw*z);S.canvas.setHeight(ch*z);S.canvas.renderAll();
  var wr=S.els['canvas-wrap'];if(wr){wr.style.width=(cw*z)+'px';wr.style.height=(ch*z)+'px';}
 }
 fit();
 S.resizeObserver=new ResizeObserver(function(){fit();});S.resizeObserver.observe(fl);
 var rt=0;function wf(){if(fl.clientWidth>0&&fl.clientHeight>0)fit();else if(rt<10){rt++;setTimeout(wf,100);}}wf();
 attachEvts();initUndo();initSidebar();initQuran();initSnap();initExportBtn();initLayers();
 if(S.loaderEl)S.loaderEl.classList.remove('show');
 console.log('[Studio] canvas',S.state.canvasW,'x',S.state.canvasH);
}

/* ---- BACKGROUND (renders directly on fabric canvas) ---- */
function applyBg(){
 if(!S.canvas)return;
 var bg=S.state,cb=function(){S.canvas.renderAll();};
 if(bg.bgType==='color'){
  S.canvas.setBackgroundColor(bg.bgColor,cb);
 }else if(bg.bgType==='gradient'){
  var g=S.gradients[bg.bgGradient]||S.gradients.midnight;
  var grad=new fabric.Gradient({
   type:'linear',gradientUnits:'percentage',
   coords:{x1:0,y1:1,x2:1,y2:0},
   colorStops:g.stops
  });
  S.canvas.setBackgroundColor(grad,cb);
 }else if(bg.bgType==='image'&&bg.bgImageUrl){
  fabric.Image.fromURL(bg.bgImageUrl,function(img){
   var cw=S.state.canvasW,ch=S.state.canvasH;
   img.scaleX=cw/img.width;img.scaleY=ch/img.height;
   S.canvas.setBackgroundImage(img,cb);
  });
 }else{
  S.canvas.setBackgroundColor(bg.bgColor,cb);
 }
}

function attachEvts(){
 if(!S.canvas)return;
 S.canvas.on('selection:created',function(e){S.state.selectedObject=e.selected?e.selected[0]:null;});
 S.canvas.on('selection:updated',function(e){S.state.selectedObject=e.selected?e.selected[0]:null;});
 S.canvas.on('selection:cleared',function(){S.state.selectedObject=null;});
 S.canvas.on('object:modified',function(){pushHistory();S.state.isDirty=true;});
 S.canvas.on('object:moving',function(e){magSnap(e.target);});
 S.canvas.on('mouse:up',function(){updateLayers();});
}

/* ---- UNDO / REDO ---- */
function initUndo(){var u=S.els['et-undo'],r=S.els['et-redo'];if(u)on(u,'click',undo);if(r)on(r,'click',redo);setTimeout(pushHistory,300);}
function pushHistory(){if(!S.canvas)return;try{var j=JSON.stringify(S.canvas.toJSON(['id','quranAyah','quranSurah','quranFont']));S.state.undoStack.push(j);if(S.state.undoStack.length>50)S.state.undoStack.shift();S.state.redoStack=[];}catch(e){}}
function undo(){if(S.state.undoStack.length<2)return;S.state.redoStack.push(S.state.undoStack.pop());loadState(S.state.undoStack[S.state.undoStack.length-1]);}
function redo(){if(S.state.redoStack.length===0)return;S.state.undoStack.push(S.state.redoStack.pop());loadState(S.state.undoStack[S.state.undoStack.length-1]);}
function loadState(j){if(!S.canvas)return;try{S.canvas.loadFromJSON(JSON.parse(j),function(){S.canvas.renderAll();updateLayers();});}catch(e){}}

/* ---- NAVIGATION GUARD ---- */
function initGuard(){
 var bk=S.els['et-back'];if(bk)on(bk,'click',showExit);
 var ca=S.els['exit-cancel'],co=S.els['exit-confirm'];
 if(ca)on(ca,'click',hideExit);if(co)on(co,'click',function(){hideExit();exitStudio();});
 var em=document.getElementById('exit-modal');if(em)on(em,'click',function(e){if(e.target===e.currentTarget)hideExit();});
 window.addEventListener('popstate',function(e){if(S.state.isDirty){showExit();window.history.pushState(null,'',window.location.href);}});
 window.history.pushState({studio:true},'',window.location.href);
}
function showExit(){if(!S.state.isDirty){exitStudio();return;}var m=document.getElementById('exit-modal');if(m)m.classList.add('show');}
function hideExit(){var m=document.getElementById('exit-modal');if(m)m.classList.remove('show');}
function exitStudio(){
 if(S.canvas){S.canvas.dispose();S.canvas=null;}if(S.resizeObserver){S.resizeObserver.disconnect();S.resizeObserver=null;}
 S.state.isDirty=false;S.state.undoStack=[];S.state.redoStack=[];
 hide('studio-editor');showF('setup-wizard');
 var hdr=document.getElementById('studio-site-header');if(hdr)hdr.style.display='';
 S._pendingNav=null;
}

/* ---- SIDEBAR ---- */
function initSidebar(){
 var tb=S.els['s-tab-bar'];if(!tb)return;var bt=tb.querySelectorAll('.s-tab');
 ea(bt,function(t){on(t,'click',function(){ea(bt,function(x){x.classList.remove('active');});t.classList.add('active');var tg=t.getAttribute('data-panel');['s-tools','s-layers'].forEach(function(id){var el=S.els[id];if(el)el.style.display=id==='s-'+tg?'':'none';});});});
 var qs=S.els['sb-quran-search'];if(qs)on(qs,'click',showQuran);
 var qf=S.els['sb-quran-font'];if(qf)on(qf,'change',function(){S.state.quranFontStyle=qf.value;var o=S.state.selectedObject;if(o&&o.quranFont!==undefined)applyTypo(o);});
 var fs=S.els['sb-font-size'];if(fs)on(fs,'input',function(){S.state.fontSize=parseInt(fs.value,10)||44;applySel(function(o){if(o.fontSize!==undefined){o.set({fontSize:S.state.fontSize});S.canvas.renderAll();}});});
 var tc=S.els['sb-text-color'];if(tc)on(tc,'input',function(){S.state.textColor=tc.value;applySel(function(o){o.set({fill:S.state.textColor});S.canvas.renderAll();});});
 var op=S.els['sb-opacity'];if(op)on(op,'input',function(){S.state.opacity=parseInt(op.value,10);applySel(function(o){o.set({opacity:S.state.opacity/100});S.canvas.renderAll();});});
 var sx=S.els['sb-shadow-x'],sy=S.els['sb-shadow-y'],sb=S.els['sb-shadow-blur'],so=S.els['sb-shadow-opacity'],sbv=S.els['sb-shadow-blur-val'],sov=S.els['sb-shadow-opacity-val'];
 function us(){applyShadowSel();}
 if(sx)on(sx,'input',function(){S.state.shadowX=parseFloat(sx.value)||0;us();});
 if(sy)on(sy,'input',function(){S.state.shadowY=parseFloat(sy.value)||0;us();});
 if(sb)on(sb,'input',function(){S.state.shadowBlur=parseFloat(sb.value)||0;if(sbv)sbv.textContent=S.state.shadowBlur;us();});
 if(so)on(so,'input',function(){S.state.shadowOpacity=parseFloat(so.value)||0;if(sov)sov.textContent=S.state.shadowOpacity;us();});
}
function applySel(fn){var obj=S.canvas?S.canvas.getActiveObject():null;if(!obj)return;if(obj._objects&&Array.isArray(obj._objects))ea(obj._objects,fn);else fn(obj);if(S.canvas)S.canvas.renderAll();pushHistory();}
function applyShadowSel(){applySel(function(o){var s=S.state;if(s.shadowBlur===0&&s.shadowX===0&&s.shadowY===0)o.set({shadow:null});else o.set({shadow:new fabric.Shadow({color:'rgba(0,0,0,'+(s.shadowOpacity/100)+')',blur:s.shadowBlur,offsetX:s.shadowX,offsetY:s.shadowY})});if(S.canvas)S.canvas.renderAll();});}

/* ---- QURAN SEARCH ---- */
function initQuran(){var cl=S.els['qm-close'],inp=S.els['qm-input'],ins=S.els['qm-insert'],mod=document.getElementById('quran-modal');if(cl)on(cl,'click',hideQuran);if(inp)on(inp,'input',searchQuran);if(ins)on(ins,'click',insertQuran);if(mod)on(mod,'click',function(e){if(e.target===e.currentTarget)hideQuran();});}
function showQuran(){document.getElementById('quran-modal').classList.add('show');var inp=S.els['qm-input'],res=S.els['qm-results'];if(inp)inp.value='';if(res)res.innerHTML='<div style="padding:12px;text-align:center;color:var(--ivory-dark);opacity:0.5;">ابدأ بالكتابة للبحث...</div>';setTimeout(function(){if(inp)inp.focus();},100);}
function hideQuran(){document.getElementById('quran-modal').classList.remove('show');}
function normAr(s){if(!s)return'';return s.replace(/[\u064e-\u0652\u0670]/g,'').replace(/[\u0623\u0625\u0622\u0627]/g,'\u0627').replace(/[\u0624]/g,'\u0648').replace(/[\u064a\u0649]/g,'\u064a').replace(/[\u0629]/g,'\u0647').replace(/\s+/g,' ').trim();}
function searchQuran(){
 var inp=S.els['qm-input'],con=S.els['qm-results'];if(!inp||!con)return;
 var q=inp.value.trim();if(q.length<1){con.innerHTML='<div style="padding:12px;text-align:center;color:var(--ivory-dark);opacity:0.5;">ابدأ بالكتابة للبحث...</div>';return;}
 var norm=normAr(q),results=[];
 if(typeof QURAN_EMBEDDED_DATA!=='undefined'&&QURAN_EMBEDDED_DATA){try{for(var i=0;i<QURAN_EMBEDDED_DATA.length;i++){var e=QURAN_EMBEDDED_DATA[i];if(normAr(e.text).indexOf(norm)!==-1)results.push({surah:e.surah,ayah:e.ayah,text:e.text,surahName:e.surah_name});}}catch(ex){}}
 if(typeof QURAN_KHATT!=='undefined'&&QURAN_KHATT){try{for(var k=0;k<QURAN_KHATT.length;k++){var ke=QURAN_KHATT[k];if(normAr(ke.t).indexOf(norm)!==-1)results.push({surah:ke.s,ayah:ke.a,text:ke.t,isKhatt:true});}}catch(ex){}}
 S.state.searchResults=results.slice(0,50);
 if(results.length===0){con.innerHTML='<div style="padding:12px;text-align:center;color:var(--ivory-dark);opacity:0.4;">لا نتائج</div>';return;}
 con.innerHTML='';var max=Math.min(results.length,30);
 for(var ri=0;ri<max;ri++){(function(r,idx){var d=document.createElement('div');d.className='qm-result'+(idx===0?' active':'');d.innerHTML='<div class="qm-result-text">'+r.text+'</div><div class="qm-result-meta">سورة '+r.surah+'، آية '+r.ayah+'</div>';on(d,'click',function(){ea(con.querySelectorAll('.qm-result'),function(el){el.classList.remove('active');});d.classList.add('active');S.state.selectedAyah=r;S.state.searchAyahFrom=r.ayah;S.state.searchAyahTo=r.ayah;var af=S.els['qm-ayah-from'];if(af)af.value=r.ayah;var at=S.els['qm-ayah-to'];if(at)at.value=r.ayah;});if(idx===0){S.state.selectedAyah=r;S.state.searchAyahFrom=r.ayah;S.state.searchAyahTo=r.ayah;var af=S.els['qm-ayah-from'];if(af)af.value=r.ayah;var at=S.els['qm-ayah-to'];if(at)at.value=r.ayah;}con.appendChild(d);})(results[ri],ri);}
}
function insertQuran(){
 var ayah=S.state.selectedAyah;if(!ayah){alert('اختر آية أولاً');return;}
 var from=parseInt((S.els['qm-ayah-from']?S.els['qm-ayah-from'].value:ayah.ayah),10)||ayah.ayah;
 var to=parseInt((S.els['qm-ayah-to']?S.els['qm-ayah-to'].value:ayah.ayah),10)||ayah.ayah;
 var text=ayah.text;
 if(from!==to&&typeof QURAN_EMBEDDED_DATA!=='undefined'){var parts=[];try{for(var i=0;i<QURAN_EMBEDDED_DATA.length;i++){var e=QURAN_EMBEDDED_DATA[i];if(e.surah===ayah.surah&&e.ayah>=from&&e.ayah<=to)parts.push({ayah:e.ayah,text:e.text});}parts.sort(function(a,b){return a.ayah-b.ayah;});if(parts.length>1)text=parts.map(function(p){return p.text;}).join(' ۝ ');else if(parts.length===1)text=parts[0].text;}catch(ex){}}
 hideQuran();injectCenter(text,ayah);
}
function injectCenter(text,ayahMeta){
 if(!S.canvas)return;
 var fs=S.state.fontSize,color=S.state.textColor,style=S.state.quranFontStyle,family='Traditional Arabic';
 if(style==='new')family='DigitalNewMadina';else if(style==='old')family='DigitalOldMadina';
 var rtlText='\u202B'+text+'\u202C';
 function doIt(){
  if(!S.canvas)return;
  var c=S.canvas.getCenter();
  var txt=new fabric.Textbox(rtlText,{left:c.left,top:c.top,fontSize:fs,fill:color,fontFamily:family,textAlign:'center',originX:'center',originY:'center',direction:'rtl',rtlTextDirection:true,width:S.state.canvasW*0.8,splitByGrapheme:false,opacity:S.state.opacity/100,quranAyah:ayahMeta?ayahMeta.ayah:0,quranSurah:ayahMeta?ayahMeta.surah:0,quranFont:style});
  var s=S.state;if(s.shadowBlur>0||s.shadowX!==0||s.shadowY!==0)txt.set({shadow:new fabric.Shadow({color:'rgba(0,0,0,'+(s.shadowOpacity/100)+')',blur:s.shadowBlur,offsetX:s.shadowX,offsetY:s.shadowY})});
  S.canvas.add(txt);S.canvas.setActiveObject(txt);S.canvas.renderAll();pushHistory();S.state.isDirty=true;updateLayers();
 }
 doIt();
}
function applyTypo(obj){if(!obj||!S.canvas)return;var f='Traditional Arabic';if(S.state.quranFontStyle==='new')f='DigitalNewMadina';else if(S.state.quranFontStyle==='old')f='DigitalOldMadina';obj.set({fontFamily:f});S.canvas.renderAll();}

/* ---- SNAPPING ---- */
function initSnap(){}
function magSnap(target){
 if(!S.canvas||!target)return;
 var thr=8,z=S.canvas.getZoom(),cw=S.canvas.width/z,ch=S.canvas.height/z,ccx=cw/2,ccy=ch/2;
 var tb=target.getBoundingRect(),tcx=tb.left+tb.width/2,tcy=tb.top+tb.height/2;
 var sx=null,sy=null;
 if(Math.abs(tcx-ccx)<thr)sx=ccx-tb.width/2;
 if(Math.abs(tcy-ccy)<thr)sy=ccy-tb.height/2;
 var objs=S.canvas.getObjects().filter(function(o){return o!==target;});
 for(var i=0;i<objs.length;i++){var o=objs[i];if(!o)continue;var ob=o.getBoundingRect(),ocx=ob.left+ob.width/2,ocy=ob.top+ob.height/2;if(sy===null&&Math.abs(tcy-ocy)<thr)sy=ocy-tb.height/2;if(sx===null&&Math.abs(tcx-ocx)<thr)sx=ocx-tb.width/2;if(sx===null&&Math.abs(tb.left-ob.left)<thr)sx=ob.left;if(sx===null&&Math.abs(tb.left+tb.width-ob.left-ob.width)<thr)sx=ob.left+ob.width-tb.width;if(sy===null&&Math.abs(tb.top-ob.top)<thr)sy=ob.top;if(sy===null&&Math.abs(tb.top+tb.height-ob.top-ob.height)<thr)sy=ob.top+ob.height-tb.height;}
 if(sx!==null)target.set({left:sx});if(sy!==null)target.set({top:sy});drawSnap(sx,sy,target);
}
function drawSnap(x,y,target){clearSnap();if(x===null&&y===null)return;if(!S.canvas)return;var z=S.canvas.getZoom(),tb=target.getBoundingRect();if(x!==null){var vx=x+tb.width/2;var vl=new fabric.Line([vx,0,vx,S.canvas.height],{stroke:'rgba(79,156,247,0.7)',strokeWidth:1/z,strokeDashArray:[4/z,4/z],selectable:false,evented:false,excludeFromExport:true,opacity:0.9});S.canvas.add(vl);S.snapLines.push(vl);}if(y!==null){var hy=y+tb.height/2;var hl=new fabric.Line([0,hy,S.canvas.width,hy],{stroke:'rgba(79,156,247,0.7)',strokeWidth:1/z,strokeDashArray:[4/z,4/z],selectable:false,evented:false,excludeFromExport:true,opacity:0.9});S.canvas.add(hl);S.snapLines.push(hl);}S.canvas.renderAll();if(S.snapTimeout)clearTimeout(S.snapTimeout);S.snapTimeout=setTimeout(clearSnap,800);}
function clearSnap(){if(S.snapLines.length===0)return;if(!S.canvas){S.snapLines=[];return;}S.snapLines.forEach(function(l){S.canvas.remove(l);});S.snapLines=[];if(S.canvas)S.canvas.renderAll();}

/* ---- EXPORT ---- */
function initExportBtn(){var e=S.els['et-export'];if(e)on(e,'click',exportDes);}
function exportDes(){if(!S.canvas)return;var d=S.canvas.toDataURL({format:'png',multiplier:1,left:0,top:0,width:S.state.canvasW,height:S.state.canvasH});var a=document.createElement('a');a.download='afaq-design-'+Date.now()+'.png';a.href=d;document.body.appendChild(a);a.click();document.body.removeChild(a);}

/* ---- LAYERS ---- */
function initLayers(){}
function updateLayers(){var li=S.els['sb-layers-list'];if(!li||!S.canvas)return;li.innerHTML='';var objs=S.canvas.getObjects().slice().reverse(),act=S.canvas.getActiveObject();ea(objs,function(o){var d=document.createElement('div');d.style.cssText='padding:6px 8px;border-radius:6px;cursor:pointer;display:flex;align-items:center;gap:8px;font-size:12px;color:var(--ivory-dark);margin-bottom:2px;';d.innerHTML='<span style="color:var(--ivory);font-size:10px;">\u25CF</span> '+(o.type||'object');on(d,'click',function(){S.canvas.setActiveObject(o);S.canvas.renderAll();updateLayers();});if(o===act)d.style.background='var(--accent-dim)';li.appendChild(d);});}

/* ---- BOOT ---- */
window.StudioApp=S;
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',init);else init();
window.addEventListener('load',function(){if(typeof lucide!=='undefined')lucide.createIcons();});
})();