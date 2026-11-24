# Translating LI Freight Distribution Network (FDN)

Thank you for helping. FDN 1.03 ships English plus **machine-drafted** translations for 12 languages. They are drafts: they have not been checked by native speakers yet, so corrections are very welcome, from a single word to a whole file.

## Where the text lives

All player-facing FDN text is on text page **477605** in the `t/` folder:

| File | Language | X4 language id |
| --- | --- | --- |
| `t/0001-l044.xml` | English (source text) | 44 |
| `t/0001.xml` | Default copy of English, used for any language without its own file. Must stay identical to `t/0001-l044.xml` | – |
| `t/0001-l007.xml` | Russian | 7 |
| `t/0001-l033.xml` | French | 33 |
| `t/0001-l034.xml` | Spanish | 34 |
| `t/0001-l039.xml` | Italian | 39 |
| `t/0001-l042.xml` | Czech | 42 |
| `t/0001-l048.xml` | Polish | 48 |
| `t/0001-l049.xml` | German | 49 |
| `t/0001-l055.xml` | Brazilian Portuguese | 55 |
| `t/0001-l081.xml` | Japanese | 81 |
| `t/0001-l082.xml` | Korean | 82 |
| `t/0001-l086.xml` | Simplified Chinese | 86 |
| `t/0001-l088.xml` | Traditional Chinese | 88 |

The file name is `0001-l` plus the three-digit X4 language id (for example `0001-l049.xml` for language id 49). These are the same ids the game uses for its own text files.

The extension description shown in the game's Extensions menu is in `content.xml`, one `<text language="NN" description="..." />` line per language. The extension name stays in English.

## File layout

Each language file looks like this (UTF-8, no BOM):

```xml
<?xml version="1.0" encoding="utf-8"?>
<!-- header comment: language, machine-draft note, rules -->
<language id="49">
  <page id="477605" title="LI Freight Distribution Network (FDN)" descr="0" voice="no">
    <t id="1">unbekannte Station</t>
    ...
  </page>
</language>
```

Only change the text between `<t id="...">` and `</t>`. Keep every id, and do not add or remove entries. The comments that group the ids are the same in every file and say where each text is shown.

## Rules

- **Slots:** `%1`, `%2` … are filled in by the game (station names, ware names, amounts, credits, minutes). Keep every slot that the English text has, with the same numbers. You may move them to suit your word order, for example `%2 of %1` is fine.
- **Brackets:** in X4 text files a plain `( … )` is a comment and is **not shown**. Write a bracket you want to show as `\(` and `\)`. Full-width brackets `（ ）` are ordinary characters and need no escape.
- **Percent sign:** a text that has slots (`%1` …) must not contain a plain `%` sign (the game would read it as a slot). Write the word instead, for example `%5 Prozent`. Texts without slots, such as `Keep %`, may use `%`.
- **No spaces at the start or end** of a text. Spaces around inserted parts are added by the scripts.
- **No `{` or `}`.** In XML, write `&` as `&amp;` and `<` as `&lt;`.
- **Do not translate:** `FDN`, `Cr`, `fdn.log`, `SirNukes Mod Support APIs`, and the abbreviation `DC` (Distribution Centre) is kept as `DC` in all drafts so labels stay short. Station, sector and ware names are inserted by the game in the player's language.
- **Use the game's own words** where the game has them (station, ware, sector, logbook, station manager, credits, storage, police, reputation …). Look them up in the game's own text file for your language.
- **Keep labels short.** Option names, column headings, buttons and the station menu have limited width. If a translation is much longer than the English, look for a shorter word.
- `fdn.log` stays in English on purpose. It is not in these files.
- Text already stored in a save (History, Alerts and logbook entries) stays in the language it was written in; that is expected.

## Check your file

Run the check from the repo folder (Python 3, no extra packages):

```
python tools/check_l10n.py
```

It must end with `PASS`. For every language file it checks that the XML parses, that the root is `<language id="NN">` with the right id, that the file has exactly the English ids (none missing, none extra, no duplicates), that each text has the same `%n` slots as the English, and that there are no unescaped brackets, `{` `}`, empty texts or leading/trailing spaces. It also checks the English file against the scripts in `md/`.

Then test in the game: switch the game language (Steam: right-click X4: Foundations > **Properties** > **General** > **Language**), restart, and open the FDN settings page, the FDN Overview pages and an FDN station's right-click menu. Look for raw codes such as `{477605,1101}`, missing characters, text that does not fit, and `FDN ERROR` lines in `fdn.log`.

## Adding a new language

1. Copy `t/0001-l044.xml` to `t/0001-lNNN.xml`, where NNN is the three-digit X4 language id (the id of the game's own text file for that language).
2. Change `<language>` to `<language id="NNN">` and update the header comment.
3. Translate the texts, following the rules above.
4. Add the language id and name to `LANGS` at the top of `tools/check_l10n.py`, and a `<text language="NNN" description="..." />` line to `content.xml`.
5. Run `python tools/check_l10n.py` until it says `PASS`.

## Sending your changes

- **GitHub:** fork https://github.com/mattryan72/FDN_X4, change the file, run the check and open a pull request. Please say which language and which ids you changed.
- **Forum:** if you do not use GitHub, post your corrections in the FDN thread on the Egosoft forum (https://forum.egosoft.com/viewtopic.php?t=477605). The id and the corrected text is enough, for example `id 1105: Engpasswarnungen`.

Contributions are released under the project's MIT licence. Thank you!
