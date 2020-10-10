from pathlib import Path
import re

loc_regex = re.compile(r"L\[\"([^\"]+)\"\]")

p = Path(__file__).parent

# Read GlobalStrings.lua
# Needs to be downloaded from https://www.townlong-yak.com/framexml/live/GlobalStrings.lua
globals = {}
with (p / "GlobalStrings.lua").open("rt", encoding="utf8") as f:
    for line in f:
        if not line.strip() or line.lstrip().startswith("--"):
            continue

        tag, string = line.split("=", 1)
        tag = tag.strip()
        string = string.strip().strip(";").strip('"')
        globals[string] = tag

# Read lua code
phrases = set()
help = set()

for filename in p.glob("*.lua"):
    namespace = help if filename.name == "help.lua" else phrases
    with filename.open("rt", encoding="utf8") as f:
        for line in f:
            strings = loc_regex.findall(line)
            for s in strings:
                namespace.add(s)
                if s.startswith((" ", "\n")) or s.endswith((" ", "\n")):
                    print("Leading or closing whitespace in ", repr(s))
                if s in globals:
                    print(f'"{s}" exists in globals as', globals[s])

# Output phrases
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

# End
print("You can now update the translation data using 'phrases*.txt' files")
