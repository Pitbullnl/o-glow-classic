# Changelog

## 0.3.17 - 2026-09-26

### New and improved

- Added quality borders to pooled item buttons in Blizzard's combined backpack and modern individual bag frames.
- Added modern player bank support for pooled bank tab buttons, including item changes and empty slots.
- Added modern loot frame support for visible, recycled item buttons.
- Updated mail borders when inbox contents change, when the mail UI loads, and when attachments are removed.
- Added modern profession output and reagent borders while retaining the older trade skill frame path.
- Added optional Bagnon and Bagnonium integration. Their inventory buttons use the bags pipe; their bank buttons use the bank pipe. Cached items use the addon's stored item data. Live inventory slots are rechecked after bag updates so borders clear when items move away.
- Fixed Fizzle detection so merely having Fizzle installed does not disable character and inspect borders.

### Support status

| Client | Package target | Status of 0.3.17 changes |
| --- | --- | --- |
| Classic Era 1.15.9 | `era`, Interface `11509` | Builds and mocked legacy paths pass; in-client regression check pending. |
| TBC Anniversary 2.5.6 | `tbc`, Interface `20506` | Builds and mocked legacy paths pass; in-client regression check pending. |
| MoP Classic 5.5.4 | `mop`, Interface `50504` | Builds and mocked legacy paths pass; in-client regression check pending. |
| WoW Forever beta 1.60.1 | `forever`, Interface `16001` | Combined bags confirmed working by the user. Bank, loot, mail, professions, and optional addon frames still need in-client checks. |

The addon has pipes for bags, player bank, character equipment, inspect equipment, mail, merchant, trade, professions, and loot. Baganator support was already present. Merchant and trade retain their existing frame paths. Guild bank, character fly-out, and void storage do not have dedicated pipes. BetterBags does not have an integration yet.

Local checks passed for modern bags, bank, loot, mail, professions, Bagnon, and legacy bank and profession behavior. All four packages build. These checks do not establish in-client behavior for the pending views or other client versions.

## 0.3.16

- Added a WoW Forever beta package target alongside Era, TBC Anniversary, and MoP Classic.
- Guarded legacy UI hooks and made loot frame handling safer when older frame functions are absent.
