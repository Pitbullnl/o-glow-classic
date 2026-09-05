# o-glow-classic

Original oGlow addon, maintained for current WoW Classic clients. This addon is a continuation of the great work of Haste.

oGlowClassic will light up your items, by adding a quality border to them. It will only display this border for common quality items and above.

It will currently only display the quality borders on the following places:
* Inventory
* Inspect
* Bank
* Guild bank
* Bags
* Mail
* Merchant
* Trade
* Professions
* Character fly-out
* Character
* Loot
* ~~Void storage~~

## Packaging

Use the helper script to create one validated ZIP per supported live client:

```
./package.sh           # builds Era, TBC Anniversary, and MoP zips into dist/
./package.sh era       # build only the Era package
./package.sh tbc       # build only the TBC Anniversary package
./package.sh mop       # build only the MoP package
```

Outputs are written to `dist/oGlowClassic-<addon-version>-<variant>.zip`. For version `0.3.15`, this produces:

* `oGlowClassic-0.3.15-era.zip` for Classic Era 1.15.9 (Interface `11509`)
* `oGlowClassic-0.3.15-tbc.zip` for TBC Anniversary 2.5.6 (Interface `20506`)
* `oGlowClassic-0.3.15-mop.zip` for MoP Classic 5.5.4 (Interface `50504`)

Each ZIP contains only the `oGlowClassic/` addon directory and a TOC with exactly its target Interface value. The script fails if that post-build validation does not pass.
