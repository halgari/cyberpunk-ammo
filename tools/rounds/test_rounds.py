from rounds import CALIBERS, KINDS, PRICE, QUALITY, FACTION_COMMON, FACTION_RARE, FACTION_EPIC, rounds, title, round_yaml

SPEC = {
    "Redliners": ("Maelstrom", FACTION_RARE, {"556", "762", "45"}),
    "ChromeCookers": ("Maelstrom", FACTION_RARE, {"5mm", "Heavy"}),
    "MeatGrinders": ("Maelstrom", FACTION_EPIC, {"45", "12mm", "12ga", "4ga"}),
    "Reloads": ("Scavengers", FACTION_COMMON, {"12mm", "45", "9mm"}),
    "Dirties": ("Scavengers", FACTION_RARE, {"12mm", "45", "9mm"}),
    "PartsPullers": ("Scavengers", FACTION_RARE, {"12mm", "45"}),
    "Kata": ("Arasaka", FACTION_EPIC, {"45", "556", "762", "5mm"}),
    "Kansatsu": ("Arasaka", FACTION_EPIC, {"10mm", "20mm", "25mm"}),
    "Shinobi": ("Arasaka", FACTION_RARE, {"9mm", "45"}),
}
TAGS = {"Maelstrom": "[Mael]", "Scavengers": "[Scav]", "Arasaka": "[Ara]"}


def faction_rounds():
    return [(t, k) for t, k in rounds() if k.get("faction")]


def test_twenty_six_rounds_as_specified():
    got = {}
    for tag, k in faction_rounds():
        got.setdefault(k["load"], (k["faction"], k["tier"], set()))[2].add(tag)
    assert got == SPEC
    assert len(faction_rounds()) == 26


def test_names_carry_the_tag_and_general_rounds_dont():
    for tag, k in rounds():
        if k.get("faction"):
            assert title(tag, k).endswith(" " + TAGS[k["faction"]])
        else:
            assert "[" not in title(tag, k)


def test_tier_qualities_and_prices():
    assert (QUALITY[FACTION_RARE], QUALITY[FACTION_EPIC], QUALITY[FACTION_COMMON]) == ("Rare", "Epic", "Common")
    # On the Uncommon base, so x4, x8 and half of the Common round.
    assert (PRICE[FACTION_RARE], PRICE[FACTION_EPIC], PRICE[FACTION_COMMON]) == (2, 4, 0.25)


def test_flats():
    by = {(t, k["load"]): round_yaml(t, k) for t, k in faction_rounds()}
    assert 'Ammo.AO_45_Redliners.aoFaction: "Maelstrom"' in by["45", "Redliners"]
    assert "Ammo.AO_45_Redliners.aoSelfJam: 0.02" in by["45", "Redliners"]
    assert "Ammo.AO_45_PartsPullers.aoPartsPuller: true" in by["45", "PartsPullers"]
    assert "Ammo.AO_45_Kata.rollMin: 0.99" in by["45", "Kata"]
    assert "quality: Quality.Common" in by["9mm", "Reloads"]


def test_no_runtime_record_switch():
    # Lesson from Heartseeker: a shared-record switch changes every gun of that record.
    for k in KINDS:
        if k.get("faction"):
            assert "ranged_attack" not in k.get("hit", {})
            assert not any("Evolution" in m[0] or "SmartGunTrack" in m[0] for m in k["stats"])


def test_every_faction_round_has_effect_lines():
    for _, k in faction_rounds():
        assert "\n\n" in k["desc"]
