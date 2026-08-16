#!/usr/bin/env python3
"""gen-layout-map.py — 從 pptx 範本產生「版型名 → 檔案 → master」對照表。

範本換版時重跑一次，把輸出蓋回 skills/vcf-whats-new/references/layout-map.md。
有了這張表，做 deck 時就不必再開檔掃 100+ 個 slideLayout 檔。

用法：
  gen-layout-map.py out.md "標題A=deckA.pptx" "標題B=deckB.pptx"
"""
import argparse, collections, os, re, shutil, sys, tempfile, zipfile


NS_P='{http://schemas.openxmlformats.org/presentationml/2006/main}'

def rd(p): return open(p,encoding='utf-8').read()

def layout_name(p):
    m=re.search(r'<p:cSld[^>]*name="([^"]*)"',rd(p))
    return (m.group(1).strip() if m else '?')

def deck_info(root):
    lay_dir=os.path.join(root,'ppt/slideLayouts')
    mst_dir=os.path.join(root,'ppt/slideMasters')
    # master -> theme name
    m2theme={}
    m2layouts={}
    for mf in sorted(os.listdir(mst_dir)):
        if not mf.endswith('.xml'): continue
        rels=rd(os.path.join(mst_dir,'_rels',mf+'.rels'))
        th=re.search(r'theme/(theme\d+\.xml)',rels)
        tname='?'
        if th:
            d=rd(os.path.join(root,'ppt/theme',th.group(1)))
            tname=re.search(r'<a:theme[^>]*name="([^"]+)"',d).group(1)
        m2theme[mf]=tname
        m2layouts[mf]=re.findall(r'Target="\.\./slideLayouts/(slideLayout\d+\.xml)"',rels)
    lay2master={}
    for mf,lst in m2layouts.items():
        for l in lst: lay2master[l]=mf
    # slide -> layout
    sl_dir=os.path.join(root,'ppt/slides')
    slide2lay={}
    n=len([f for f in os.listdir(sl_dir) if f.endswith('.xml')])
    for i in range(1,n+1):
        r=os.path.join(sl_dir,'_rels',f'slide{i}.xml.rels')
        if not os.path.exists(r): continue
        m=re.search(r'slideLayouts/(slideLayout\d+\.xml)',rd(r))
        if m: slide2lay[i]=m.group(1)
    return m2theme,lay2master,slide2lay,n

def placeholders(p):
    out=[]
    for sp in re.findall(r'<p:sp>.*?</p:sp>',rd(p),re.S):
        ph=re.search(r'<p:ph([^>]*)/>',sp)
        if not ph: continue
        t=re.search(r'type="([^"]*)"',ph.group(1))
        idx=re.search(r'idx="(\d+)"',ph.group(1))
        nm=re.search(r'name="([^"]*)"',sp)
        off=re.search(r'<a:off x="(-?\d+)" y="(-?\d+)"/><a:ext cx="(\d+)" cy="(\d+)"',sp)
        sz=sorted({int(x) for x in re.findall(r'sz="(\d+)"',sp)})
        out.append(dict(type=(t.group(1) if t else 'body'),idx=(idx.group(1) if idx else '-'),
                        name=(nm.group(1) if nm else '')[:30],
                        geom=(off.groups() if off else None),
                        sz=[s//100 for s in sz][:4]))
    return out

def emit(title,fname,root,fh):
    m2theme,lay2master,slide2lay,nslides=deck_info(root)
    mkeys=sorted(m2theme)
    mshort={k:f'M{i+1}' for i,k in enumerate(mkeys)}
    print(f'\n## {title}\n',file=fh)
    print(f'檔案：`{fname}`　slides: {nslides}　layouts: {len(lay2master)}\n',file=fh)
    print('| Master | Theme | 版型數 |',file=fh); print('|---|---|---|',file=fh)
    for k in mkeys:
        print(f'| {mshort[k]} (`{k}`) | `{m2theme[k]}` | {sum(1 for v in lay2master.values() if v==k)} |',file=fh)
    used=collections.Counter(slide2lay.values())
    print(f'\n### 本 deck 實際使用的版型（{len(used)} 種 / {nslides} 頁）\n',file=fh)
    print('| 版型名 | 檔案 | Master | 用了幾頁 | 頁碼 |',file=fh); print('|---|---|---|---|---|',file=fh)
    for lay,cnt in used.most_common():
        pages=[str(s) for s,l in sorted(slide2lay.items()) if l==lay]
        pg=','.join(pages) if len(pages)<=8 else ','.join(pages[:8])+'…'
        print(f'| {layout_name(os.path.join(root,"ppt/slideLayouts",lay))} | `{lay}` | {mshort[lay2master[lay]]} | {cnt} | {pg} |',file=fh)
    print('\n### 全部版型索引（名稱 → 檔案）\n',file=fh)
    rows=sorted(((layout_name(os.path.join(root,'ppt/slideLayouts',l)),l,mshort[m]) for l,m in lay2master.items()))
    print('| 版型名 | 檔案 | M |',file=fh); print('|---|---|---|',file=fh)
    for nm,l,m in rows: print(f'| {nm} | `{l}` | {m} |',file=fh)
    print('\n### 常用版型的 placeholder 幾何（EMU）\n',file=fh)
    for lay,_ in used.most_common(6):
        nm=layout_name(os.path.join(root,'ppt/slideLayouts',lay))
        print(f'**{nm}** — `{lay}`\n',file=fh)
        print('| ph type | idx | off x,y | ext cx,cy | 字級 (pt) |',file=fh); print('|---|---|---|---|---|',file=fh)
        for ph in placeholders(os.path.join(root,'ppt/slideLayouts',lay)):
            g=ph['geom']
            print(f"| {ph['type']} | {ph['idx']} | {g[0]}, {g[1]} | {g[2]}, {g[3]} | {', '.join(map(str,ph['sz'])) or '—'} |" if g
                  else f"| {ph['type']} | {ph['idx']} | (繼承 master) | — | {', '.join(map(str,ph['sz'])) or '—'} |",file=fh)
        print('',file=fh)


def main():
    ap=argparse.ArgumentParser(description='產生 pptx 版型對照表')
    ap.add_argument('out')
    ap.add_argument('decks',nargs='+',help='格式：標題=path/to/deck.pptx')
    a=ap.parse_args()
    tmp=tempfile.mkdtemp()
    try:
        with open(a.out,'w',encoding='utf-8') as fh:
            print("""# Tech Tuesday 範本 — 版型對照表 (layout map)

> **這份表的用途：省掉每次開檔掃 100+ 個 layout 檔的成本。**
> `slideLayoutNN.xml` 的編號是每份 deck 各自的 — 同名版型在不同範本編號完全不同，
> 所以永遠用「版型名」查這張表，不要背編號。
>
> 產生方式：`scripts/gen-layout-map.py`。範本換版時重跑一次即可。""",file=fh)
            for spec in a.decks:
                title,_,path=spec.partition('=')
                if not path or not os.path.exists(path):
                    sys.exit('找不到檔案：%s' % path)
                d=os.path.join(tmp,re.sub(r'\W+','_',title))
                with zipfile.ZipFile(path) as z: z.extractall(d)
                emit(title,os.path.basename(path),d,fh)
    finally:
        shutil.rmtree(tmp,ignore_errors=True)
    print('OK', a.out, os.path.getsize(a.out), 'bytes')

if __name__=='__main__':
    main()
