from pathlib import Path
import re

loc_regex = re.compile(r"L\[\"([^\"]+)\"\]")

p = Path(__file__).parent
phrases = set()
help = set()

for filename in p.glob("*.lua"):
    namespace = help if filename.name == "help.lua" else phrases
    with filename.open("rt", encoding="utf8") as f:
        for line in f:
            strings = loc_regex.findall(line)
            for s in strings:
                namespace.add(s)

phrases = sorted(phrases)
help = sorted(help)
output = p / "phrases.txt"
output_help = p / "phrases_help.txt"

with output.open("wt", encoding="utf8") as f:
    for s in phrases:
        f.write(f'L["{s}"]=true\n')

with output_help.open("wt", encoding="utf8") as f:
    for s in help:
        f.write(f'L["{s}"]=true\n')

print("You can now update the translation data using 'phrases*.txt' files")
