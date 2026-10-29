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
