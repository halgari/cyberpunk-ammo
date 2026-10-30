from crafting import tier_batch, cost, scrap, recipe_price


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


def test_recipe_price():
    # Price multiplier on Price.Ammo for 10 batches: the caliber's Common factor, the tier's
    # x1/x2/x4/x8, the tier batch. Epic 9mm Match: 1 x 8 x 23 x 10.
    assert recipe_price(1.0, 3, 23, 10) == 1840.0
    assert recipe_price(1.2, 1, 45, 10) == 1080.0


def test_legendary_has_scrap_but_no_recipe():
    from crafting import caliber_block
    text = ('AmmoOverhaul.Power_9mm.family: "Power"\nAmmoOverhaul.Power_9mm.craftBatch: 90\n'
            'AmmoOverhaul.Power_9mm.selectorAmmo: ["Ammo.AO_9mm_Ball", "Ammo.AO_9mm_CookOff"]\n'
            'AmmoOverhaul.Power_9mm.selectorTiers: [0, 4]\n')
    loc = {"AO-Ammo-9mm-Ball": "9mm Ball"}
    block, pairs, costs = caliber_block("Power_9mm", text, loc, lambda a: "AO-Ammo-9mm-Ball", 10)
    assert "Ammo.AO_9mm_CookOff.aoScrapRounds: 90" in block
    assert 'Ammo.AO_9mm_CookOff.aoRecipe: ""' in block
    assert "AO_Recipe_AO_9mm_CookOff" not in block
    assert "AO_Cost_Power_4" not in block
    assert not any("CookOff" in c for c in costs)
