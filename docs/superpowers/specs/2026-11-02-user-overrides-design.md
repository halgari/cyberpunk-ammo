# User overrides: gun calibers and ammo weight

Approved in chat on 2026-11-02.

## Goal

Players and gun mods can, in their own YAML files:

- give a gun a caliber (for example a gun added by another mod), move a vanilla gun to a different
  caliber, or take a gun out of the ammo system;
- scale ammo weight, down to 0 (weightless, like vanilla).

With no override file, every gun, round and weight stays exactly as it is today. There is no
automatic fallback for guns nobody mapped: an unmapped gun stays unmanaged, as now.

## Why the settings get their own names

Probe in game, 2026-11-02 (TweakXL in the dev install):

- TweakXL reads files in plain alphabetical path order, folders and loose files together
  (`AAA_x\a.yaml`, then `AmmoOverhaul\*.yaml`, then `aoprobe_root.yaml`, then `zzz_x\z.yaml`).
- A file that sorts before `AmmoOverhaul\` loses. A value it sets is replaced by the mod's, and a
  `!append` to a list the mod defines fails with "Ambiguous definition. The value type cannot be
  determined."
- A file that sorts after it overrides values and appends fine.
- A value only the user's file sets reads back wherever the file sorts. A value nobody sets reads
  as unset.

So user settings go in flats that the mod never defines. The mod reads them at startup and falls
back to today's behaviour when one is missing. File names and load order then don't matter.
Each setting is keyed by one gun, one tag or one round, so two mods never write the same list.

User keys start with `BrassMarket.` (the public name, which users type). The mod's own settings
keep `AmmoOverhaul.`. Keys for one gun or one round go after the record name
(`<record>.brassMarketCaliber`, `<ammo>.brassMarketWeight`), like the mod's own `aoFaction`.
A record id is a hash, so scripts can only build a key by appending to it, not by prefixing it.
Values must be quoted: TweakXL drops a bare word as "Ambiguous definition".

## Gun calibers

```yaml
Items.Preset_MyGun_Default.brassMarketCaliber: "Power_45"   # this record only
BrassMarket.tag.MyGunTag: "Power_9mm"                       # every gun with this tag
Items.Preset_Unity_Default.brassMarketCaliber: "none"       # leave this gun alone
```

- The value is a caliber id from `AmmoOverhaul.calibers` (`Power_9mm` ... `Smart_25`) or `none`.
- A `weapon` line applies to exactly that record. Presets don't inherit a line set on their base
  record; a gun family is covered by a `tag` line.
- Order of checks for a gun: its own `weapon` line, then a `tag` line for each of its tags (in
  the record's tag order, first hit wins), then the built-in rules (`weaponTags`,
  `weaponRecords`, in `AmmoOverhaul.calibers` order, as today).
- A gun is only managed if it fires a vanilla ammo item (`Ammo` tag), as today. An override
  also needs the `RangedWeapon` tag (a Katana's record has `Ammo.Standard`), so melee weapons,
  grenades and cyberware stay out. Such a line is logged and ignored.
- An unknown caliber id is logged ("unknown caliber ... for ..., ignored") and that line is
  skipped, so the next check decides.
- Any family may go to any caliber (a Tech gun on 9mm is the user's call). That gun gets the
  caliber's feed slot, selectors and rounds like any other gun of that caliber.
- One lookup (`AOData.FindCaliber`) does all of this. The startup tweak, the runtime caliber
  cache, the tooltip caliber name and the ammo section all go through it, so they always agree.
  Today the tweak loops calibers and then guns (`AOData.Matches`). It becomes one pass over the
  guns calling `FindCaliber`.
- The startup log gives the number of guns overrides decided, plus one line per unknown caliber
  or override on a non-gun. Scripts can't list flats, so a line naming a record that doesn't
  exist can't be detected.

## Ammo weight

```yaml
BrassMarket.weight.all: 1.0
BrassMarket.weight.Smart: 0.5                    # family: Power, Tech, Smart
BrassMarket.weight.Power_127: 0.0                # caliber
BrassMarket.weight.Ammo.AO_9mm_Toxin: 2.0        # one round
```

- A round's weight is today's weight times all four multipliers that are set (missing = 1).
- Values below 0 are logged and treated as 1. Integers (`0`, `2`) are accepted as well as floats.
  A YAML `0` is an integer flat, and reading it as a float alone would silently ignore it.
- The startup tweak rescales the additive `BaseStats.Weight` constant modifiers on each of the
  mod's rounds: every caliber's `selectorAmmo` entries plus its `defaultAmmo` and `vanillaAmmo`,
  each round once. Most rounds share their weight modifier with the round they're based on (329
  of 354), so a rescaled round gets its own copy (`<ammo>.aoWeight<n>`) swapped into its
  `statModifiers`. Rounds at 1 are left as they are.
- Changes need a game restart, like any TweakDB setting. Nothing goes into saves.
- NPC loot cap: `NpcAmmo.NoteLoot` caps a body's loot at `npcLootWeight` carry points using the
  round's current weight, and skips the cap at weight 0. Lighter ammo must not mean bigger
  drops, so the cap uses the round's unscaled weight. The tweak stores it as
  `<ammo>.aoBaseWeight`, and the cap falls back to the stat when that isn't set.

## Shipping and docs

- Ship `r6/tweaks/AmmoOverhaul/user-overrides-example.yaml`, with every line commented out. It
  changes nothing and shows each key with a short note. Users copy it to their own file anywhere
  under `r6/tweaks` (for example `r6/tweaks/my-brass-market.yaml`), so updates never overwrite
  their settings.
- `docs/NEXUS.md` gets a short "Your own settings" section (written in the item-text voice, pasted by
  the user). It covers what the file can change, the restart, and the caliber ids.
- `docs/DESIGN.md` gets the lookup order and the load-order finding. `CHANGELOG.md` goes under
  Unreleased.

## Testing

New features only, in the dev build:

- A test script installs two override files, one sorting before `AmmoOverhaul\`
  (`aaa_aotest.yaml`) and one after (`zz_aotest.yaml`). It restarts the game and checks:
  - a test gun mapped by `weapon` line gets that caliber's ammo and feed slot;
  - a `tag` line maps the guns with that tag;
  - `none` leaves a vanilla gun unmanaged (vanilla ammo, no feed slot);
  - a `weapon` line beats a `tag` line, and a `tag` line beats the built-in rules;
  - an unknown caliber is ignored and logged;
  - the weight multipliers stack: a round's Weight stat equals its unscaled weight times the
    product, an integer `0` gives 0, and an unset round is unchanged;
  - the NPC loot cap gives the same count as with no overrides.
  It then removes both files and restarts, and checks that weights and calibers are back to
  today's (the existing `calibers/records.lua` passes).
- Existing `calibers/records.lua`, `calibers/crafting.lua`, `calibers/distribution.lua` pass with
  no override files (no behaviour change).

## Out of scope

- Rules by gun type, family or vanilla ammo type (a fallback for unmapped guns). The user chose
  overrides only.
- In-game settings menu (Mod Settings). The YAML is the interface.
- New calibers defined by users.
