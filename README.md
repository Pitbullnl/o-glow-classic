# o-glow-classic

Original oGlow addon, updated to work with TBC Classic - This addon is a continuation of the great works of Haste.

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

Use the helper script to build zips for CurseForge with the correct Interface numbers for Era and MoP:

```
./package.sh           # builds Era and MoP zips into dist/
./package.sh era       # build only the Era package
./package.sh mop       # build only the MoP package
```

Outputs are written to `dist/oGlowClassic-<interface-version>.zip`, e.g. `oGlowClassic-1.15.8.zip` (Interface 11508) and `oGlowClassic-5.5.2.zip` (Interface 50502). Adjust interface values in `package.sh` if Blizzard bumps the Classic/MoP interface IDs.
