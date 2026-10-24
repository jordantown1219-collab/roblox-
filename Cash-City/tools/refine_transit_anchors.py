from pathlib import Path
p=Path('tools/prepare_geography.py');s=p.read_text(encoding='utf-8');s=s.replace("'exit':chosen[-1]}","'exit':chosen[-1],'transit':chosen[-2]}");p.write_text(s,encoding='utf-8')
