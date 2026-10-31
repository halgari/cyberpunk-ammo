from rounds import CALIBERS, KINDS, PRICE, QUALITY, FACTION_COMMON, FACTION_RARE, FACTION_EPIC, FACTION_UNCOMMON, rounds, title, round_yaml

SPEC = {
    "Redliners": ("Maelstrom", FACTION_RARE, {"556", "762", "45"}),
    "ChromeCookers": ("Maelstrom", FACTION_EPIC, {"5mm", "Heavy"}),
    "MeatGrinders": ("Maelstrom", FACTION_EPIC, {"45", "12mm", "12ga", "4ga"}),
    "Reloads": ("Scavengers", FACTION_COMMON, {"12mm", "45", "9mm"}),
    "GutterLead": ("Scavengers", FACTION_UNCOMMON, {"12mm", "45", "9mm"}),
    "PartsPullers": ("Scavengers", FACTION_RARE, {"12mm", "45"}),
    "Kata": ("Arasaka", FACTION_EPIC, {"45", "556", "762", "5mm"}),
    "Kansatsu": ("Arasaka", FACTION_EPIC, {"10mm", "20mm", "25mm"}),
    "Shinobi": ("Arasaka", FACTION_EPIC, {"9mm", "45"}),
    "ShinobiSeconds": ("TygerClaws", FACTION_UNCOMMON, {"9mm", "45"}),
    "Tanto": ("TygerClaws", FACTION_RARE, {"9mm", "45", "12mm"}),
    "GoldTips": ("Valentinos", FACTION_RARE, {"45", "12mm"}),
    "SantaMuerte": ("Valentinos", FACTION_EPIC, {"45", "12mm"}),
    "Surplus": ("SixthStreet", FACTION_UNCOMMON, {"9mm", "45", "12mm"}),
    "FourthOfJuly": ("SixthStreet", FACTION_RARE, {"9mm", "12mm", "10mm"}),
    "MilSpec": ("Militech", FACTION_RARE, {"9mm", "762", "5mm"}),
    "CeaseAndDesist": ("Militech", FACTION_EPIC, {"762", "12ga"}),
    "ProteinLoads": ("Animals", FACTION_RARE, {"12mm", "5mm", "Heavy"}),
    "LegDay": ("Animals", FACTION_EPIC, {"12mm", "Heavy"}),
}
TAGS = {"Maelstrom": "[Mael]", "Scavengers": "[Scav]", "Arasaka": "[Ara]", "TygerClaws": "[Tyger]",
        "Valentinos": "[Val]", "SixthStreet": "[6th]", "Militech": "[Mil]", "Animals": "[Animal]"}


def faction_rounds():
    return [(t, k) for t, k in rounds() if k.get("faction")]


def test_faction_rounds_as_specified():
    got = {}
    for tag, k in faction_rounds():
        got.setdefault(k["load"], (k["faction"], k["tier"], set()))[2].add(tag)
    assert got == SPEC
    assert len(faction_rounds()) == 51


def test_names_carry_the_tag_and_general_rounds_dont():
    for tag, k in rounds():
        if k.get("faction"):
            assert title(tag, k).endswith(" " + TAGS[k["faction"]])
        else:
            assert "[" not in title(tag, k)


def test_tier_qualities_and_prices():
    assert (QUALITY[FACTION_RARE], QUALITY[FACTION_EPIC], QUALITY[FACTION_COMMON], QUALITY[FACTION_UNCOMMON]) == \
        ("Rare", "Epic", "Common", "Uncommon")
    # On the Uncommon base, so x4, x8, half of and x2 of the Common round.
    assert (PRICE[FACTION_RARE], PRICE[FACTION_EPIC], PRICE[FACTION_COMMON], PRICE[FACTION_UNCOMMON]) == (2, 4, 0.25, 1)


def test_flats():
    by = {(t, k["load"]): round_yaml(t, k) for t, k in faction_rounds()}
    assert 'Ammo.AO_45_Redliners.aoFaction: "Maelstrom"' in by["45", "Redliners"]
    assert "Ammo.AO_45_Redliners.aoSelfJam: 0.02" in by["45", "Redliners"]
    assert "Ammo.AO_45_PartsPullers.aoPartsPuller: true" in by["45", "PartsPullers"]
    assert "Ammo.AO_45_Kata.rollMin: 0.99" in by["45", "Kata"]
    assert "quality: Quality.Common" in by["9mm", "Reloads"]


def test_second_batch_flats():
    by = {(t, k["load"]): round_yaml(t, k) for t, k in faction_rounds()}
    assert 'Ammo.AO_45_SantaMuerte.aoHeadEffect: "BaseStatusEffect.Burning"' in by["45", "SantaMuerte"]
    assert "Ammo.AO_762_CeaseAndDesist.aoStopChance: 0.3" in by["762", "CeaseAndDesist"]
    assert "Ammo.AO_12mm_LegDay.aoLegChance: 0.2" in by["12mm", "LegDay"]
    assert "Ammo.AO_12mm_ProteinLoads.aoPumped: true" in by["12mm", "ProteinLoads"]
    assert "Ammo.AO_9mm_ShinobiSeconds.rollDudChance: 0.05" in by["9mm", "ShinobiSeconds"]
    assert "Ammo.AO_9mm_ShinobiSeconds.rollDudMult: 0.25" in by["9mm", "ShinobiSeconds"]
    assert "Ammo.AO_TLight_MilSpec.rollMin: 0.95" in by["5mm", "MilSpec"]


def test_crit_stats_are_in_percent():
    # DamageSystem divides a gun's CritChance and CritDamage by 100.
    for k in KINDS:
        for m in k["stats"]:
            if m[0] in ("BaseStats.CritChance", "BaseStats.CritDamage"):
                assert m[2] >= 1.0, k["load"]


def test_gold_tips_sell_for_half_again_the_rare_price():
    y = round_yaml("45", next(k for t, k in faction_rounds() if k["load"] == "GoldTips"))
    assert y.count("value: 3\n") == 2


def test_no_runtime_record_switch():
    # Lesson from Heartseeker: a shared-record switch changes every gun of that record.
    for k in KINDS:
        if k.get("faction"):
            assert "ranged_attack" not in k.get("hit", {})
            assert not any("Evolution" in m[0] or "SmartGunTrack" in m[0] for m in k["stats"])


def test_every_faction_round_has_effect_lines():
    for _, k in faction_rounds():
        assert "\n\n" in k["desc"]
