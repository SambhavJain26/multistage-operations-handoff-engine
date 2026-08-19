"""Measure candidate payoff words at .pay size against the 888px column.

    python scripts/check-payoff-width.py

Edit the `words` list to test a deck's candidates. Character count does not
decide this: "evidence." fits with 23px to spare and "happened." is 90px
over at the same nine characters. Run this before building a payoff slide.
"""
import re,os,subprocess,tempfile
BS=chr(92)
kit=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
css='file:///'+os.path.join(kit,'carousel-template.css').replace(BS,'/')
words=["name.","portal.","nothing.","Silence.","evidence.","survives.","happened.","anywhere.","emergency.","delay.","alert.","duration."]
items="".join('<div class="body"><div><span class="pay" data-w="%s">%s</span></div></div>'%(w,w) for w in words)
html=f'''<!doctype html><html><head><meta charset="utf-8">
<link href="https://api.fontshare.com/v2/css?f[]=switzer@400,500,600,700,800,900&f[]=zodiak@700,701,800,801&display=swap" rel="stylesheet">
<link href="{css}" rel="stylesheet"></head><body>
<section class="slide">{items}</section>
<script>
window.addEventListener('load',function(){{setTimeout(function(){{
 var out=[]; var COL=1080-96*2;
 document.querySelectorAll('.pay').forEach(function(e){{
  var w=e.getBoundingClientRect().width;
  out.push('  '+(e.dataset.w+'          ').slice(0,12)+String(Math.round(w)).padStart(5)+'px  '+(w>COL?'*** OVER by '+Math.round(w-COL):'fits, '+Math.round(COL-w)+'px spare'));
 }});
 var d=document.createElement('pre'); d.id='m'; d.textContent='column = '+COL+'px'+String.fromCharCode(10)+out.join(String.fromCharCode(10));
 document.body.appendChild(d);
}},600);}});
</script></body></html>'''
tmp=os.path.join(tempfile.gettempdir(),'paywidth.html')
open(tmp,'w',encoding='utf-8').write(html)
chrome=os.path.join(os.environ['ProgramFiles'],'Google','Chrome','Application','chrome.exe')
prof=tempfile.mkdtemp()
r=subprocess.run([chrome,'--headless=new','--disable-gpu','--no-sandbox','--user-data-dir='+prof,
 '--virtual-time-budget=20000','--dump-dom','file:///'+tmp.replace(BS,'/')],
 capture_output=True,text=True,encoding='utf-8',errors='replace')
m=re.search(r'<pre id="m">(.*?)</pre>',r.stdout,re.S)
print(m.group(1) if m else 'NO MEASUREMENT')
