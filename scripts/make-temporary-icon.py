#!/usr/bin/env python3
"""Generate an opaque temporary icon. Identity approval required before release."""
import math, struct, zlib, json
from pathlib import Path
root=Path(__file__).resolve().parents[1]/'App/Assets.xcassets'
root.mkdir(exist_ok=True)
(root/'Contents.json').write_text(json.dumps({'info':{'author':'xcode','version':1}}))
path=root/'AppIcon.appiconset'; path.mkdir(exist_ok=True)
# Quiet navy field and cream W, no organizer or brand marks.
n=1024
segments=[((245,340),(355,680)),((355,680),(512,435)),((512,435),(669,680)),((669,680),(779,340))]
def distance(x,y,a,b):
    dx=b[0]-a[0];dy=b[1]-a[1];t=max(0,min(1,((x-a[0])*dx+(y-a[1])*dy)/(dx*dx+dy*dy)))
    return math.hypot(x-a[0]-t*dx,y-a[1]-t*dy)
rows=[]
for y in range(n):
    row=bytearray([0])
    for x in range(n):
        d=min(distance(x,y,a,b) for a,b in segments)
        alpha=max(0,min(1,24.5-d))
        row.extend(round(bg+(fg-bg)*alpha) for bg,fg in zip((18,30,44),(244,233,210)))
    rows.append(bytes(row))
def chunk(kind,data): return struct.pack('>I',len(data))+kind+data+struct.pack('>I',zlib.crc32(kind+data)&0xffffffff)
(path/'AppIcon.png').write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',n,n,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(b''.join(rows)))+chunk(b'IEND',b''))
(path/'Contents.json').write_text(json.dumps({'images':[{'filename':'AppIcon.png','idiom':'universal','platform':'ios','size':'1024x1024'}],'info':{'author':'xcode','version':1}},indent=2))
