# o-glow-classic

Original oGlow addon, maintained for current WoW Classic clients. This addon is a continuation of the great work of Haste.

oGlowClassic will light up your items, by adding a quality border to them. It will only display this border for common quality items and above.

The quality border pipes cover:

* Bags, including Blizzard's combined backpack
* Player bank
* Character and inspect equipment
* Mail, merchant, and trade frames
* Professions and loot

Baganator, Bagnon, and Bagnonium item buttons have optional integration. Bagnon and Bagnonium bank buttons follow the bank pipe setting. Guild bank, character fly-out, and void storage have no dedicated pipe.

See the [changelog](CHANGELOG.md) for 0.3.18 changes and their validation status.

## Packaging

Use the helper script to create one validated ZIP per supported live client:

```
./package.sh           # builds Era, TBC Anniversary, MoP, and Forever zips into dist/
./package.sh era       # build only the Era package
./package.sh tbc       # build only the TBC Anniversary package
./package.sh mop       # build only the MoP package
./package.sh forever   # build only the WoW Forever package
```

Outputs are written to `dist/oGlowClassic-<addon-version>-<variant>.zip`. For version `0.3.18`, this produces:

* `oGlowClassic-0.3.18-era.zip` for Classic Era 1.15.9 (Interface `11509`)
* `oGlowClassic-0.3.18-tbc.zip` for TBC Anniversary 2.5.6 (Interface `20506`)
* `oGlowClassic-0.3.18-mop.zip` for MoP Classic 5.5.4 (Interface `50504`)
* `oGlowClassic-0.3.18-forever.zip` for WoW Forever 1.60.1.70790 (Interface `16001`)

The Forever target follows the [latest listed build](https://theforeverera.com/en/builds), checked on 2026-11-07. Packaging checks validate the archive; in-client verification on build 70790 is pending.

Each ZIP contains only the `oGlowClassic/` addon directory and a TOC with exactly its target Interface value. The script fails if that post-build validation does not pass.
Markdown documentation is excluded from the ZIPs.
