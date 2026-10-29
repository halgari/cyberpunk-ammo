# Ammo Crafting and Disassembly Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Every round can be crafted (Common from the start, Uncommon+ from recipe items found in loot and gun shops) at a cost set by family and tier, and disassembly returns about half a batch's cost per full batch instead of 1 component per round.

**Architecture:** A new generator `tools/crafting/crafting.py` reads each caliber file's flats and writes a generated block into that file (cost packages, recipe records, per-round flats) plus `LocalizationRecipes.reds`. A new `Crafting.reds` wraps vanilla's batch-size lookup, ammo recipe setup, disassembly result and disassemble check. Loot, NPC body loot and gun shops gain recipe item rolls.

**Tech Stack:** Python 3 (generator, pytest), TweakXL YAML, redscript, CET Lua checks via `tools/linux/cet.sh`.

**Spec:** `docs/superpowers/specs/2026-10-29-ammo-crafting-design.md`

## Global Constraints

- Cost per batch: Tech 1, Power 2, Smart 4 components, of the round's tier (Common `Items.CommonMaterial1`, Uncommon `Items.UncommonMaterial1`, Rare `Items.RareMaterial1`, Epic `Items.EpicMaterial1`).
- Common batch: 9mm 90, .45 90, magnum 60, 5.56 90, 7.62 90, 12.7 20, 12ga 40, 4ga 20, light rail 90, heavy rail 40, 10mm Smart 90, 20mm cluster 20, 25mm dart 10.
- Tier batch: Uncommon 1/2, Rare 1/3, Epic 1/4 of the Common batch, rounded half up, at least 1.
- Disassembly per full Common batch (`floor(rounds / common batch)`), round's tier: Power 1 per batch, Smart 2 per batch, Tech `floor(batches / 2)`. Partial batches give nothing. Other items keep vanilla.
- Feed selectors (`AO_AmmoSelector` tag) can't be disassembled.
- `recipeDropFactor` 0.05, `recipeVendorChance` 0.10, `recipePriceBatches` 10, in `core.yaml`.
- Recipe item name "<round name>: load sheet"; description one plain line on what it makes, no effect lines.
- Vanilla's 4 ammo records (`Ammo.HandgunAmmo`, `RifleAmmo`, `ShotgunAmmo`, `SniperRifleAmmo`) keep their vanilla cost and recipe.
- Never deploy while the game runs: `restart-game.sh --kill`, `deploy.sh`, `restart-game.sh`. Game work goes through `tools/linux/game-lock.sh`. Close the game after each session.
- Commits end with `Claude-Session: https://claude.ai/code/session_01JwJvEAYGPc2WFWAem67MMf`. No push.

## Review Focus

- A save made before the mod update: Common recipes must appear on load (AddAmmoRecipes runs on load), and recipes already known must not duplicate. Pinned in Task 5's live check (load, count recipes for Common .45 = 1).
- Learning the same recipe item twice: the second must not add a second entry or break the first. Pinned in Task 5 (learn twice, `KnowsRecipe` true, one entry).
- Disassembling fewer rounds than a batch: the UI must not offer a free action that eats rounds for nothing silently. The rounds are removed and nothing given, per spec; Task 5's partial-box check pins the count.
- Ammo at or above the cap: crafting is blocked, no divide-by-zero on our IDs. Pinned in Task 5 (stack at cap, `CanItemBeCrafted` false).
- Vanilla items other than ammo: disassembly unchanged. Pinned in Task 5 (a Common weapon still yields vanilla's result).

---

### Task 1: Probe recipe learning, write the checks (RED)

**Files:**
- Create: `tools/snippets/calibers/crafting.lua` (static), `tools/snippets/calibers/crafting.sh` (live)
- Create (scratch, not committed): the probe Lua in the scratchpad

**Interfaces:**
- Produces: the probe answer, ledgered as `Task 1: Ruling: learn path = A|B`. A: a vanilla recipe item's Learn teaches the record's `craftingResult.item` with its `amount`, so our recipe item can be an `ItemRecipe` record with `$base` of that vanilla item. B: it doesn't, and Task 3 hooks `ItemActionsHelper.LearnItem`.
- Produces for Task 2/3: record names `Items.AO_Recipe_<round>` (round = ammo record name without `Ammo.`), flats `<ammo>.aoRecipe` (String, recipe record), `<ammo>.aoScrapRounds` (Int), `<ammo>.aoScrapGive` (Int), `AmmoOverhaul.<caliber>.craftBatch` (Int).

- [ ] **Step 1: Write `crafting.lua`** (runs through `check.sh`, uses `slice/common.lua` helpers). Checks, over every caliber's `selectorAmmo`/`selectorTiers`:
  - `craftBatch` per caliber equals the Global Constraints value;
  - every non-vanilla round's `craftingData` recipe is one element: the tier's material, amount Tech 1 / Power 2 / Smart 4;
  - every round has `aoRecipe` naming an `ItemRecipe` record whose `craftingResult.amount` is the tier batch (9mm: 90/45/30/23) and whose `craftingResult.item` is the round;
  - every round has `aoScrapRounds`/`aoScrapGive`: Power (b,1), Smart (b,2), Tech (2b,1), b = Common batch;
  - every Uncommon+ recipe record has the `Recipe` tag and a Learn object action, and a name ending ": load sheet";
  - Tech cost < Power cost < Smart cost for each tier;
  - `AmmoOverhaul.recipeDropFactor` 0.05, `recipeVendorChance` 0.10, `recipePriceBatches` 10.
- [ ] **Step 2: Write `crafting.sh`** (sourcing `npc-lib.sh` like `hitdata.sh`, EXPECT set to the count of checks) for the live phase. Checks:
  - `CraftBook.KnowsRecipe(Ammo.AO_45_Ball)` and the craft book's amount 90;
  - give 2 Common components, `CraftingSystem` craft one batch of .45 Ball (`CraftItemRequest` with amount 1): +90 rounds, −2 components;
  - give and learn `Items.AO_Recipe_AO_9mm_Match` twice: known, one entry; craft one batch: +23 rounds, −2 Epic components;
  - disassemble 200 rounds of a Power Rare 9mm (2 full batches): +2 Rare components; 100 rounds of Smart 10mm Common: +2 Common; 360 rounds light rail Common (4 batches): +2 Common; 50 rounds 9mm Ball: +0;
  - a Common weapon disassembles to vanilla's result (`GetDisassemblyResultItems` non-empty, unchanged ingredient IDs);
  - `CanItemBeDisassembled` false on a held `Items.AO_Feed_9mm_Match`;
  - with .45 Ball at its Quantity cap, `CanItemBeCrafted` is false.
- [ ] **Step 3: Probe** (game up, `game-lock.sh`): list a vanilla recipe item (`TweakDB` records with tag `Recipe` and `ItemType`… print 3 with their `objectActions`, `craftingResult`); clone one in CET with `craftingResult` → `Ammo.AO_9mm_Match` amount 23, give it, `ItemActionsHelper.LearnItem(player, id, true)`, then `KnowsRecipe`. Ledger A or B.
- [ ] **Step 4: Run both checks** before any implementation.
  Run: `tools/linux/game-lock.sh tools/snippets/calibers/check.sh calibers/crafting.lua; tools/linux/game-lock.sh tools/snippets/calibers/crafting.sh`
  Expected: FAILs on every new record and behaviour (missing flats, no recipe, 90 components from disassembly). Close the game.
- [ ] **Step 5: Commit** the two checks: `test: crafting checks (red)`.

### Task 2: Generator and records

**Files:**
- Create: `tools/crafting/crafting.py`, `tools/crafting/test_crafting.py`
- Modify: the 13 caliber files in `src/tweaks/AmmoOverhaul/` (hand-written `craftBatch` flat after `selectorTiers`; generated block appended), `src/tweaks/AmmoOverhaul/core.yaml` (the three recipe settings under a `# --- Crafting` heading)
- Create: `src/scripts/AmmoOverhaul/LocalizationRecipes.reds` (generated)
- Modify: `src/scripts/AmmoOverhaul/Localization.reds` (serve the generated recipe texts, as it serves `AORoundTexts`)

**Interfaces:**
- Consumes: caliber flats `family`, `selectorAmmo`, `selectorTiers`, `craftBatch`; round names from `Localization.reds` and `LocalizationRounds.reds` (key → text pairs); Task 1's learn-path ruling.
- Produces: `tier_batch(common: int, tier: int) -> int`, `cost(family: str) -> int`, `scrap(family: str, common: int) -> tuple[int, int]` (rounds, give); generated per round: `Crafting.AO_Cost_<family>_<tier>` (CraftingPackage, shared), `<ammo>.craftingData`, `Items.AO_Recipe_<round>` (ItemRecipe; for Uncommon+ also the learnable item per path A, price `recipePriceBatches` × batch price), `<ammo>.aoRecipe`, `<ammo>.aoScrapRounds`, `<ammo>.aoScrapGive`. Vanilla ammo IDs get only `aoRecipe` (its vanilla recipe record) and the scrap flats.

- [ ] **Step 1: Write `test_crafting.py`**:

```python
from crafting import tier_batch, cost, scrap
def test_tier_batch():
    assert [tier_batch(90, t) for t in range(4)] == [90, 45, 30, 23]
    assert [tier_batch(10, t) for t in range(4)] == [10, 5, 3, 3]
    assert tier_batch(1, 3) == 1
def test_cost_order():
    assert (cost("Tech"), cost("Power"), cost("Smart")) == (1, 2, 4)
def test_scrap():
    assert scrap("Power", 90) == (90, 1)
    assert scrap("Smart", 90) == (90, 2)
    assert scrap("Tech", 90) == (180, 1)
```

- [ ] **Step 2: Run** `python3 -m pytest tools/crafting -q`. Expected: FAIL, `ModuleNotFoundError: crafting`.
- [ ] **Step 3: Implement `crafting.py`**: the three functions (half up: `floor(common / div + 0.5)`, min 1), parsing of caliber flats with regex, generated block between `# === GENERATED by tools/crafting/crafting.py: crafting. Edit there. ===` and `# === END GENERATED CRAFTING ===` at each caliber file's end, `LocalizationRecipes.reds` as `AORecipeTexts` (keys `AO-Recipe-<round>` and `AO-Recipe-<round>-Desc`, desc "Makes <n> rounds of <round name>."). Re-running must be idempotent.
- [ ] **Step 4: Run** `python3 -m pytest tools/crafting -q && python3 tools/crafting/crafting.py && python3 tools/crafting/crafting.py && git diff --stat`. Expected: 3 passed; the second run changes nothing beyond the first.
- [ ] **Step 5: Commit** `feat: crafting records generator`.

### Task 3: Crafting.reds

**Files:**
- Create: `src/scripts/AmmoOverhaul/Crafting.reds`
- Modify: `src/scripts/AmmoOverhaul/AOData.reds` (accessors)

**Interfaces:**
- Consumes: Task 2's flats and records.
- Produces: `AOData.Recipe(ammo: TweakDBID) -> TweakDBID`, `AOData.ScrapRounds(ammo) -> Int32`, `AOData.ScrapGive(ammo) -> Int32`, `AOData.CraftBatch(caliber: String) -> Int32`, `AOData.RecipeDropFactor() -> Float`, `AOData.RecipeVendorChance() -> Float`, `AOData.IsAmmoRecipeItem(item: TweakDBID) -> Bool` (record tagged `AO_Recipe`).

- [ ] **Step 1: Wraps**, each falling through to `wrappedMethod` for anything not ours:
  - `CraftingSystem.GetAmmoBulletAmount(ammoId)` (static): if `AOData.Recipe` is valid and not one of the 4 vanilla IDs, return its `craftingResult.amount`;
  - `CraftingSystem.AddAmmoRecipes()`: after vanilla, for each caliber, its tier-0 round if not a vanilla ID and not known: `m_playerCraftBook.AddRecipe(ammo, [], AOData.CraftBatch(caliber))`;
  - `CraftingSystem.GetDisassemblyResultItems(...)`: if `ScrapRounds(ammo) > 0`, return one `IngredientData` of `RPGManager.GetCraftingMaterialRecord(quality)` × `(amount / rounds) * give` (empty when 0); restoredAttachments untouched;
  - `CraftingSystem.CanItemBeDisassembled(owner, itemID)`: false for items tagged `AO_AmmoSelector`;
  - path B only: `ItemActionsHelper.LearnItem` for `AO_Recipe` items: `AddRecipe(round, [], batch)` unless known, remove one item.
- [ ] **Step 2: Compile check** `tools/linux/deploy.sh --check-only` if it exists, else the compile step `deploy.sh` runs (game closed). Expected: no errors.
- [ ] **Step 3: Commit** `feat: crafting and disassembly hooks`.

### Task 4: Recipe drops

**Files:**
- Modify: `src/scripts/AmmoOverhaul/LootConvert.reds`, `NpcAmmo.reds` (body loot), `Vendors.reds`

**Interfaces:**
- Consumes: Task 3's AOData accessors; `AmmoDistribution` tier lookups (`AOData.AmmosForTier`).
- Produces: `AmmoDistribution.RecipeRoll(ammo: TweakDBID) -> TweakDBID` (the round's recipe item with chance `recipeDropFactor` if tier ≥ 1, else invalid); `AmmoFeedSystem.DebugRecipeStock(vendor)` style debug through the existing vendor debug hooks if needed by checks.

- [ ] **Step 1:** Loot: after `Pick` gives a round, `RecipeRoll` it and give 1 recipe item to the container. NPC body loot: same for each round left. Gun shops (`AOSplitAmmo`, maxTier 2): each caliber's tier 1..2 rounds, chance `recipeVendorChance`, one `SItemStack` of the recipe item.
- [ ] **Step 2:** Add to `crafting.lua` a statistical check: 2000 `RecipeRoll` calls on a Rare round land 0.03..0.07; on a Common round 0.
- [ ] **Step 3:** Compile check as Task 3. Commit `feat: recipe items in loot and gun shops`.

### Task 5: Deploy, go green, docs

**Files:**
- Modify: `tools/snippets/calibers/suite.sh` (add `calibers/crafting.lua` and `crafting.sh`), `docs/TESTING.md` (playtest steps), `docs/CATALOG.md` (Open question 2 answered), `docs/DESIGN.md` (crafting section)

- [ ] **Step 1:** `restart-game.sh --kill; deploy.sh; restart-game.sh`.
- [ ] **Step 2:** Run `check.sh calibers/crafting.lua` and `crafting.sh`. Expected: all PASS. Add the Review Focus checks to `crafting.sh` (they are listed in Task 1's live checks plus: reload the save and count Common .45 recipes = 1). Close the game.
- [ ] **Step 3:** Playtest steps in `docs/TESTING.md`: craft a Common .45 at the crafting screen; learn a found recipe; disassemble a full and a partial box in the backpack and read the components gained.
- [ ] **Step 4:** Commit `docs: crafting tests and notes`.
