# Ammo crafting and disassembly: design

Date: 2026-10-29. Status: designed in conversation; written for the user's review.

## Why

What 2.50 does now, read from the game's records and `craftingSystem.script`:

- Every ammo item, ours included, carries `ItemAction.Disassemble`. Disassembly reads
  `Crafting.Con_Ammo`: **1 Common component per round**, whatever the tier. Quality bonuses only
  apply to weapons. A stack is broken down by count, each round paying 1 component.
- Crafting a batch costs 2 Common components (`Ammo.AmmoBase_inline0`) and makes 90 (9mm),
  90 (5.56), 40 (12ga) or 20 (12.7) rounds. So crafting 90 rounds costs 2 components and
  breaking them down returns 90: a free loop.
- `AddAmmoRecipes` and `GetAmmoBulletAmount` know only the 4 vanilla ammo IDs (our Common 9mm,
  5.56, 12ga, 12.7). The other 9 calibers and every Uncommon, Rare and Epic round can't be
  crafted; `GetAmmoBulletAmount` returns from an invalid recipe for any other ID, and the ammo
  cap check divides by it.
- The hidden feed selectors (`Items.AO_Feed_*`, Prt_Magazine) also carry Disassemble.
  Breaking one down would drop that gun's ammo choice.

## Binding rules

- **Cost to make follows what the round is: Tech < Power < Smart.** Tech is a shaped slug,
  Power has a case, primer and powder, Smart is a guided micro-rocket. (User, 2026-10-29.)
- Common rounds stay vanilla: the 4 vanilla rounds keep their vanilla cost and batch.
- NPCs don't craft; nothing here touches combat.
- Item text: slang names, plain gun-counter text, no invented lore.

## Rules

**Cost per batch.** The family sets the count, the tier sets the grade:

- Tech 1, Power 2, Smart 4 components.
- Common rounds use Common components (`Items.CommonMaterial1`), Uncommon use Uncommon, Rare use
  Rare, Epic use Epic.
- Crafting perks keep cutting costs as they do now (vanilla's `GetItemCraftingCost`).

**Batch size.** Per caliber, for the Common round:

- 9mm 90, .45 90, magnum 60, 5.56 90, 7.62 90, 12.7 20, 12ga 40, 4ga 20;
- light rail 90, heavy rail 40;
- 10mm Smart 90, 20mm cluster 20, 25mm dart 10.

Higher tiers make a fraction of that: Uncommon 1/2, Rare 1/3, Epic 1/4, rounded half up, at
least 1. Example: Rare 9mm makes 30 rounds for 2 Rare components.

**Ammo cap.** Vanilla's cap still limits crafting (`(cap - held) / batch` batches).

**Disassembly.** Per full Common-size batch of the caliber (`floor(rounds / common batch)`),
in components of the round's own tier:

- Power 1 per batch, Smart 2 per batch, Tech 1 per 2 full batches (`floor(batches / 2)`).
- Rounds beyond the last full batch give nothing.
- The 1/2, 1/3, 1/4 crafting batches don't change the disassembly count.
- Any other item keeps vanilla's result.
- The feed selectors lose `ItemAction.Disassemble`.

**Recipes.**

- Every caliber's Common round is known from the start, as vanilla does for its 4.
- Each Uncommon, Rare and Epic round has a recipe item (`Recipe` tag, Learn action, vanilla's
  blueprint look). Name: "<round name>: load sheet". Description: one plain line on what it
  makes; no effect lines.
- Recipe items drop where that tier's rounds drop, at `recipeDropFactor` (0.05) of the round's
  chance, and vendors that stock a tier list its recipes at `recipeVendorChance` (0.10) per
  recipe per restock. Both in `core.yaml`.
- Price: `recipePriceBatches` (10) times the price of one crafted batch of the round.

## Build

- **Records** (`tools/rounds/rounds.py`, generated with the rounds):
  - per round: a `CraftingPackage` (family count × tier material) set as its `craftingData`;
  - per round: an `ItemRecipe` record `Ammo.AO_Recipe_<round>` whose `craftingResult` is the
    round × its batch size;
  - per Uncommon+ round: a recipe item `Items.AO_RecipeItem_<round>`;
  - feed selectors: `objectActions` without Disassemble;
  - per-caliber `craftBatch` in `core.yaml`'s caliber entries; Common rounds of the 9 new
    calibers get the same records as the rest.
- **Script** (new `src/scripts/AmmoOverhaul/Crafting.reds`):
  - wrap `CraftingSystem.GetAmmoBulletAmount`: for our rounds, read `Ammo.AO_Recipe_<round>`;
    vanilla IDs keep the vanilla path;
  - wrap `AddAmmoRecipes`: after vanilla, add every caliber's Common recipe. It runs on new
    games and on load, so existing saves pick them up;
  - wrap `GetDisassemblyResultItems`: for `AO_Ammo`-tagged items, return the per-batch result
    above; anything else goes to vanilla.
- **Drops** (`AmmoDistribution.reds`): recipe items join the loot and vendor rolls of their
  rounds, scaled by the two factors.

## Probe first

`ItemAction.Learn` runs in native code; what it reads to pick the recipe a blueprint teaches is
unknown. Before building on it: copy a vanilla blueprint record onto one of our rounds, learn it
in game, and check `CraftBook.KnowsRecipe` for our round. If that fails, our recipe items get a
script hook on the Learn action that calls `CraftBook.AddRecipe` with the round and its batch.

## Testing

New mechanisms only.

- **Static records check** (`tools/snippets/calibers/`, offline like `hitdata.lua`):
  - every round has a crafting cost, a batch size and a recipe record;
  - every Uncommon+ round has a recipe item;
  - no feed selector carries Disassemble;
  - per tier and caliber, Tech cost < Power < Smart.
- **One batched game session:**
  - a new game or load shows the Common .45 recipe; craft a batch and get 90 rounds for
    2 Common components;
  - learn a Rare recipe item and craft a batch: the right count for 2 Rare components;
  - disassemble 2 full boxes plus a partial one of a Power Rare, one Smart and one Tech, and
    check the components;
  - with the stack near the cap, crafting is limited as vanilla.
- **Playtest steps** for the user in `docs/TESTING.md`.

## Out of scope

- Legendary and faction rounds (none exist yet).
- Upgrading ammo tiers by crafting.
- Changing vanilla component costs or perks.
