import rounds as gen
from rounds import CALIBERS, KINDS, PRICE, QUALITY, FACTION_COMMON, FACTION_RARE, FACTION_EPIC, FACTION_UNCOMMON, FACTION_LEGENDARY, rounds, title, round_yaml

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
    "DogtownTax": ("Barghest", FACTION_RARE, {"9mm", "556"}),
    "ChimeraScrap": ("Barghest", FACTION_EPIC, {"762", "5mm"}),
    "BadJuju": ("VoodooBoys", FACTION_EPIC, {"45", "5mm", "10mm"}),
    "CollectCall": ("VoodooBoys", FACTION_LEGENDARY, {"5mm", "10mm"}),
    "PocketSand": ("Wraiths", FACTION_RARE, {"45", "12ga"}),
    "TheClap": ("Wraiths", FACTION_EPIC, {"5mm", "Heavy"}),
    "WasteNot": ("Aldecaldos", FACTION_RARE, {"9mm", "45", "12mm"}),
    "Speedloaders": ("Aldecaldos", FACTION_EPIC, {"45", "12mm"}),
    "CutOff": ("TheMox", FACTION_EPIC, {"9mm", "45", "12ga"}),
    "LastCall": ("TheMox", FACTION_EPIC, {"9mm", "12mm"}),
    "StandardIssue": ("NCPD", FACTION_UNCOMMON, {"9mm", "45"}),
    "ResistingArrest": ("NCPD", FACTION_RARE, {"9mm", "12ga"}),
    "WideAngle": ("KangTao", FACTION_RARE, {"10mm", "20mm"}),
    "SecondOpinion": ("KangTao", FACTION_EPIC, {"10mm", "20mm", "25mm"}),
    "Deniable": ("NUSA", FACTION_EPIC, {"45", "5mm", "10mm"}),
    "BlackBudget": ("NUSA", FACTION_EPIC, {"127", "Heavy"}),
}
TAGS = {"Maelstrom": "[Mael]", "Scavengers": "[Scav]", "Arasaka": "[Ara]", "TygerClaws": "[Tyger]",
        "Valentinos": "[Val]", "SixthStreet": "[6th]", "Militech": "[Mil]", "Animals": "[Animal]", "Barghest": "[Barghest]",
        "VoodooBoys": "[VDB]", "Wraiths": "[Wraith]", "Aldecaldos": "[Nomad]", "TheMox": "[Mox]", "NCPD": "[NCPD]",
        "KangTao": "[Kang]", "NUSA": "[NUSA]"}


def faction_rounds():
    return [(t, k) for t, k in rounds() if k.get("faction")]


def test_faction_rounds_as_specified():
    got = {}
    for tag, k in faction_rounds():
        got.setdefault(k["load"], (k["faction"], k["tier"], set()))[2].add(tag)
    assert got == SPEC
    assert len(faction_rounds()) == 88


def test_names_carry_the_tag_and_general_rounds_dont():
    for tag, k in rounds():
        if k.get("faction"):
            assert title(tag, k).endswith(" " + TAGS[k["faction"]])
        elif not k.get("hack"):
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


def test_third_batch_flats():
    by = {(t, k["load"]): round_yaml(t, k) for t, k in faction_rounds()}
    assert "Ammo.AO_9mm_DogtownTax.aoEddies: true" in by["9mm", "DogtownTax"]
    assert "Ammo.AO_9mm_WasteNot.aoFreeShot: 0.15" in by["9mm", "WasteNot"]
    assert "Ammo.AO_45_Deniable.aoUnawareBonus: 2.0" in by["45", "Deniable"]
    y = by["9mm", "CutOff"]
    assert 'aoRankEffect: "BaseStatusEffect.Unconscious"' in y and 'aoRankToughFrom: "Elite"' in y
    assert 'aoRankTough: "BaseStatusEffect.ForceStagger"' in y and "aoNonlethal: true" in y
    y = by["9mm", "LastCall"]
    assert "aoRankDelay: 4.0" in y and 'aoRankPlayer: "BaseStatusEffect.Knockdown"' in y
    assert "aoRankTough" not in by["45", "PocketSand"].replace("aoRankToughFrom", "")
    y = by["762", "ChimeraScrap"]
    assert "attackPackage: Attacks.ChimeraPowerModExplosiveBulletPackage" in y
    assert "weaponAttachmentSource: Items.AO_Feed_762_ChimeraScrap" in y


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
            assert not any("Evolution" in m[0] or "SmartGunTrack" in m[0] for m in k["stats"])


def test_every_faction_round_has_effect_lines():
    for _, k in faction_rounds():
        assert "\n\n" in k["desc"]


def hack_rounds():
    return [(t, k) for t, k in gen.rounds() if k.get("hack")]


def test_hack_round_counts():
    assert len(hack_rounds()) == 117
    assert {t for t, _ in hack_rounds()} == {"10mm", "20mm", "25mm"}


def test_hack_names_and_qualities():
    t, k = next((t, k) for t, k in hack_rounds() if k["load"] == "HackOptics1" and t == "10mm")
    assert gen.title(t, k) == "10mm Reboot Optics [Hack]"
    assert gen.QUALITY[k["tier"]] == "Uncommon"


def test_hack_chances():
    by = {k["load"]: k["hit"]["rank"]["chance"] for _, k in hack_rounds()}
    assert [by[f"HackOptics{n}"] for n in (1, 2, 3, 4)] == [0.10, 0.15, 0.20, 0.25]
    assert [by[f"HackContagion{n}"] for n in (1, 2, 3, 4)] == [0.04, 0.06, 0.08, 0.10]
    assert by["HackBurnout2"] == 0.06 and by["HackShort4"] == 0.10


def test_hack_flats():
    y = gen.round_yaml(*next((t, k) for t, k in hack_rounds() if k["load"] == "HackPsycho4"))
    assert 'aoHackProgram: "Items.MadnessLvl4Program"' in y
    assert 'aoRankEffect: "AmmoOverhaul.MadnessHack"' in y
    assert 'aoRankToughFrom: "Boss"' in y
    assert "aoRankPlayer" not in y


def test_hack_icons_shared_across_calibers():
    assert len({gen.ids(t, k)["icon"] for t, k in hack_rounds()}) == 39
