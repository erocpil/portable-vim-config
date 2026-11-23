"""Audit the center-out statusline palettes without external dependencies."""
import colorsys
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LEFT = ["StatuslineBufNr", "StatuslineFlag", "StatuslineFileName",
        "StatuslineFileEnc", "StatuslineFileFormat", "StatuslineFileType", "GetTagName"]
RIGHT = ["StatuslineChar", "StatuslineLine", "StatuslineLineColumnSep",
         "StatuslineColumn", "StatuslineColumnCountSep", "StatuslineLineCount",
         "StatuslinePercent", "StatuslineCapsBuddy", "StatuslineBuddy",
         "StatuslineHostName", "StatuslinePracticeStatus"]
GROUPS = LEFT + ["StatuslineFill"] + RIGHT
TAGBAR_GROUPS = ["TagbarStatusTitle", "TagbarStatusFill",
                 "TagbarStatusMode"]
SPECIAL_GROUPS = ["SpecialStatusTitle", "SpecialStatusInfo",
                  "SpecialStatusFill", "SpecialStatusMode"]


def rgb(value):
    return tuple(int(value[i:i + 2], 16) / 255 for i in (1, 3, 5))


def luminance(value):
    linear = [c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
              for c in rgb(value)]
    return sum(c * w for c, w in zip(linear, (0.2126, 0.7152, 0.0722)))


def contrast(fg, bg):
    lo, hi = sorted((luminance(fg), luminance(bg)))
    return (hi + 0.05) / (lo + 0.05)


def xterm(index):
    index = int(index)
    if index >= 232:
        values = [8 + (index - 232) * 10] * 3
    else:
        assert 16 <= index < 232
        index -= 16
        levels = (0, 95, 135, 175, 215, 255)
        values = [levels[index // 36], levels[index // 6 % 6], levels[index % 6]]
    return "#" + "".join(f"{c:02x}" for c in values)


def ordered_hues(colors, low, high, ascending=True):
    # Achromatic terminal stops fade into the neutral center and have no hue.
    hues = []
    for color in colors:
        h, saturation, _ = colorsys.rgb_to_hsv(*rgb(color))
        if saturation > 0.03:
            hues.append(h * 360)
    assert all(low <= h <= high for h in hues), hues
    pairs = zip(hues, hues[1:])
    if ascending:
        assert all(a <= b + 1 for a, b in pairs), hues
    else:
        assert all(a + 1 >= b for a, b in pairs), hues


for theme in ("ManShow", "Celibate"):
    text = (ROOT / "colors" / f"{theme}.vim").read_text()
    groups = {name: dict(re.findall(r"(\w+)=([^\s]+)", attrs))
              for name, attrs in re.findall(r"^highlight (\w+) (.+)$", text, re.M)}
    for mode, fg_key, bg_key, decode in (
        ("GUI", "guifg", "guibg", str),
        ("256-color", "ctermfg", "ctermbg", xterm),
    ):
        backgrounds = [decode(groups[g][bg_key]) for g in GROUPS]
        assert len(set(backgrounds)) == len(GROUPS), (theme, mode, "repeated panel")
        scores = [contrast(decode(groups[g][fg_key]), decode(groups[g][bg_key]))
                  for g in GROUPS]
        assert min(scores) >= 4.5, (theme, mode, min(scores))
        tagbar_scores = [contrast(decode(groups[g][fg_key]),
                                  decode(groups[g][bg_key]))
                         for g in TAGBAR_GROUPS]
        assert min(tagbar_scores) >= 4.5, (theme, mode, "Tagbar",
                                           min(tagbar_scores))
        special_scores = [contrast(decode(groups[g][fg_key]),
                                   decode(groups[g][bg_key]))
                          for g in SPECIAL_GROUPS]
        assert min(special_scores) >= 4.5, (theme, mode, "special",
                                            min(special_scores))
        if theme == "Celibate":
            ordered_hues([decode(groups[g][bg_key]) for g in LEFT], 175, 270,
                         ascending=False)
            ordered_hues([decode(groups[g][bg_key]) for g in RIGHT], 15, 125,
                         ascending=False)
        else:
            ordered_hues([decode(groups[g][bg_key]) for g in LEFT], 0, 125)
            ordered_hues([decode(groups[g][bg_key]) for g in RIGHT], 140, 270)
        center = rgb(decode(groups["StatuslineFill"][bg_key]))
        normal = rgb(decode(groups["Normal"][bg_key]))
        assert max(abs(a - b) for a, b in zip(center, normal)) <= 8 / 255
        print(f"{theme} {mode}: center, hue order, 19 distinct panels PASS; "
              f"minimum contrast {min(scores):.2f}:1; Tagbar "
              f"{min(tagbar_scores):.2f}:1; special "
              f"{min(special_scores):.2f}:1")
