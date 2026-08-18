"""Report how close each slide's content sits to the eyebrow and the footer.

    python scripts/check-fit.py post-05-seven-ordering-rules [...]

The 918px band is not the limit: the centred block overflows it symmetrically
and the margin below absorbs some of that, so a slide can exceed the band and
still be right on the page. What matters is clearance to the furniture, which is
what this prints. Under about 24px the last line crowds the footer rule.

This finds oversets a contact sheet hides, but it says nothing about where a
mark landed. Keep looking at the slides.
"""
import sys,re,os,subprocess,tempfile
BS=chr(92)
kit=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
for name in sys.argv[1:]:
    html=open(os.path.join(kit,name+'.html'),encoding='utf-8').read()
    css='file:///'+os.path.join(kit,'carousel-template.css').replace(BS,'/')
    html=html.replace('href="carousel-template.css"','href="'+css+'"')
    probe = """
<script>
window.addEventListener('load',function(){setTimeout(function(){
 var out=[];
 document.querySelectorAll('.slide').forEach(function(s,i){
  var top=s.getBoundingClientRect().top;
  var b=s.querySelector('.body'), kids=b.children;
  var eb=s.querySelector('.eyebrow').getBoundingClientRect().bottom-top;
  var ft=s.querySelector('.footer').getBoundingClientRect().top-top;
  var by=s.querySelector('.byline');
  var lim=by?by.getBoundingClientRect().top-top:ft;
  var c0=kids[0].getBoundingClientRect().top-top;
  var c1=kids[kids.length-1].getBoundingClientRect().bottom-top;
  var flags=[];
  if(c0-eb<24) flags.push('*** TOP tight '+Math.round(c0-eb));
  if(lim-c1<24) flags.push('*** BOTTOM tight '+Math.round(lim-c1)+(by?' (byline)':' (footer)'));
  out.push('  slide '+(i+1)+'  headroom='+Math.round(c0-eb)+'  footroom='+Math.round(lim-c1)+'  '+(flags.length?flags.join(' '):'ok'));
 });
 var d=document.createElement('pre'); d.id='measure'; d.textContent=out.join(String.fromCharCode(10));
 document.body.appendChild(d);
},600);});
</script>
</body>"""
    html=html.replace('</body>',probe,1)
    tmp=os.path.join(tempfile.gettempdir(),'clear-'+name+'.html')
    open(tmp,'w',encoding='utf-8').write(html)
    chrome=os.path.join(os.environ['ProgramFiles'],'Google','Chrome','Application','chrome.exe')
    prof=tempfile.mkdtemp()
    r=subprocess.run([chrome,'--headless=new','--disable-gpu','--no-sandbox','--user-data-dir='+prof,
     '--virtual-time-budget=20000','--dump-dom','file:///'+tmp.replace(BS,'/')],
     capture_output=True,text=True,encoding='utf-8',errors='replace')
    m=re.search(r'<pre id="measure">(.*?)</pre>',r.stdout,re.S)
    print(name); print(m.group(1) if m else '  NO MEASUREMENT (webfonts or Chrome failed)')
