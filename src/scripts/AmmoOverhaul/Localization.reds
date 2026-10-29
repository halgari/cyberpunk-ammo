module AmmoOverhaul.Localization
import Codeware.Localization.*

// Text for the LocKey#AO-* keys used in the tweaks, served through Codeware.
public class AmmoOverhaulLocalizationProvider extends ModLocalizationProvider {
  public func GetPackage(language: CName) -> ref<ModLocalizationPackage> {
    switch language {
      case n"en-us":
        return new AmmoOverhaulEnglish();
      default:
        return null;
    }
  }

  public func GetFallback() -> CName {
    return n"en-us";
  }
}

public class AmmoOverhaulEnglish extends ModLocalizationPackage {
  protected func DefineTexts() -> Void {
    this.Text("AO-Slot-AmmoFeed", "Ammo Feed");
    this.Text("AO-Section-Ammo", "Ammo");
    // Rounds and their selectors share a name and description. The last sentences are the
    // effect line, which must match the selector's stats.
    this.Text("AO-Ammo-9mm-Ball", "9mm Ball");
    this.Text("AO-Ammo-9mm-Ball-Desc", "Plain FMJ. Cheapest 9 in town, and every gun shop's got a crate of it.\n\nStandard 9mm. No special effects.");
    this.Text("AO-Ammo-9mm-Mushrooms", "9mm Mushrooms");
    this.Text("AO-Ammo-9mm-Mushrooms-Desc", "Hollow points. They open up on impact and tear through anyone not wearing armor. Hit plating and they just flatten out.\n\n+20% damage. Armor is 50% more effective against it.");
    // Shared by every caliber's Mushrooms.
    this.Text("AO-Ammo-Mushrooms-Desc", "Hollow points. They open up on impact and tear through anyone not wearing armor. Hit plating and they just flatten out.\n\n+20% damage. Armor is 50% more effective against it.");
    this.Text("AO-Ammo-45-Ball", ".45 Ball");
    this.Text("AO-Ammo-45-Ball-Desc", "Plain .45 FMJ for the Unity, Liberty and Nue.\n\nStandard .45. No special effects.");
    this.Text("AO-Ammo-45-Mushrooms", ".45 Mushrooms");
    this.Text("AO-Ammo-12mm-Ball", "12mm Ball");
    this.Text("AO-Ammo-12mm-Ball-Desc", "Magnum FMJ for revolvers and hand cannons.\n\nStandard 12mm. No special effects.");
    this.Text("AO-Ammo-12mm-Mushrooms", "12mm Mushrooms");
    this.Text("AO-Ammo-556-Ball", "5.56 Ball");
    this.Text("AO-Ammo-556-Ball-Desc", "Standard rifle FMJ. Every gun shop's got it.\n\nStandard 5.56. No special effects.");
    this.Text("AO-Ammo-556-Mushrooms", "5.56 Mushrooms");
    this.Text("AO-Ammo-762-Ball", "7.62 Ball");
    this.Text("AO-Ammo-762-Ball-Desc", "Full-size rifle FMJ for the Ajax, Kyubi and MA70.\n\nStandard 7.62. No special effects.");
    this.Text("AO-Ammo-762-Mushrooms", "7.62 Mushrooms");
    this.Text("AO-Ammo-127-Ball", "12.7 Ball");
    this.Text("AO-Ammo-127-Ball-Desc", "Half-inch rounds for anti-materiel rifles.\n\nStandard 12.7. No special effects.");
    this.Text("AO-Ammo-127-Mushrooms", "12.7 Mushrooms");
    // Shared by every caliber's Sleevers and Dumbfires.
    this.Text("AO-Ammo-Sleevers-Desc", "Skinny slug in a plastic sleeve. The rails grab it quicker, so you charge faster, but it hits a bit softer.\n\nCharges 30% faster. -5% damage.");
    this.Text("AO-Ammo-Dumbfires-Desc", "Smart rockets with the guidance chip swapped for a bigger warhead. Hits a lot harder, but it only goes where you point it.\n\n+80% damage. Doesn't track targets.");
    this.Text("AO-Ammo-Heavy-RailSlugs", "Heavy Rail Slugs");
    this.Text("AO-Ammo-Heavy-RailSlugs-Desc", "Steel slugs for full-size railguns.\n\nStandard heavy rail ammo. No special effects.");
    this.Text("AO-Ammo-Heavy-Sleevers", "Heavy Sleevers");
    this.Text("AO-Ammo-20mm-Seekers", "20mm Seekers");
    this.Text("AO-Ammo-20mm-Seekers-Desc", "Cluster rockets for smart shotguns. Lock on and the swarm goes after the target.\n\nStandard smart ammo. Tracks locked targets.");
    this.Text("AO-Ammo-20mm-Dumbfires", "20mm Dumbfires");
    this.Text("AO-Ammo-25mm-Seekers", "25mm Seekers");
    this.Text("AO-Ammo-25mm-Seekers-Desc", "Big smart darts for the Ashura.\n\nStandard smart ammo. Tracks locked targets.");
    this.Text("AO-Ammo-25mm-Dumbfires", "25mm Dumbfires");
    this.Text("AO-Ammo-Buckshot", "Buckshot");
    this.Text("AO-Ammo-Buckshot-Desc", "12-gauge buck. Nasty up close, falls off fast past a few meters.\n\nStandard 12-gauge. No special effects.");
    this.Text("AO-Ammo-Slugs", "Slugs");
    this.Text("AO-Ammo-Slugs-Desc", "One solid lead slug instead of pellets. Same punch in a single hit, and it flies straight.\n\nFires one projectile with the whole shot's damage. Much tighter spread. Double range.");
    this.Text("AO-Ammo-4ga-Buckshot", "4ga Buckshot");
    this.Text("AO-Ammo-4ga-Buckshot-Desc", "Big shells for the Carnage.\n\nStandard 4-gauge. No special effects.");
    this.Text("AO-Ammo-4ga-Slugs", "4ga Slugs");
    this.Text("AO-Ammo-4ga-Slugs-Desc", "One big slug for the Carnage. Most people it hits go down.\n\nFires one projectile with the whole shot's damage, +30%. Ignores 50% of armor. Knocks targets down. Double range. +60% recoil.");
    this.Text("AO-Ammo-5mm-RailSlugs", "5mm Rail Slugs");
    this.Text("AO-Ammo-5mm-RailSlugs-Desc", "Steel slugs for light railguns. Nothing to them, the rails do all the work.\n\nStandard light rail ammo. No special effects.");
    this.Text("AO-Ammo-5mm-Sleevers", "5mm Sleevers");
    this.Text("AO-Ammo-5mm-Sleevers-Desc", "Skinny slug in a plastic sleeve. The rails grab it quicker, so you charge faster, but it hits a bit softer.\n\nCharges 30% faster. -5% damage.");
    this.Text("AO-Ammo-10mm-Seekers", "10mm Seekers");
    this.Text("AO-Ammo-10mm-Seekers-Desc", "Standard smart rockets. Get a lock and they chase the target for you.\n\nStandard smart ammo. Tracks locked targets.");
    this.Text("AO-Ammo-10mm-Dumbfires", "10mm Dumbfires");
    this.Text("AO-Ammo-10mm-Dumbfires-Desc", "Smart rockets with the guidance chip swapped for a bigger warhead. Hits a lot harder, but it only goes where you point it.\n\n+80% damage. Doesn't track targets.");
    // Second Uncommon rounds. One description per load, shared across calibers.
    this.Text("AO-Ammo-9mm-PlusP", "9mm +P");
    this.Text("AO-Ammo-45-PlusP", ".45 +P");
    this.Text("AO-Ammo-12mm-PlusP", "12mm +P");
    this.Text("AO-Ammo-556-PlusP", "5.56 +P");
    this.Text("AO-Ammo-762-PlusP", "7.62 +P");
    this.Text("AO-Ammo-127-PlusP", "12.7 +P");
    this.Text("AO-Ammo-12ga-Birdshot", "Birdshot");
    this.Text("AO-Ammo-4ga-Birdshot", "4ga Birdshot");
    this.Text("AO-Ammo-5mm-Bricks", "5mm Bricks");
    this.Text("AO-Ammo-Heavy-Bricks", "Heavy Bricks");
    this.Text("AO-Ammo-10mm-ShortFuse", "10mm Short-Fuse");
    this.Text("AO-Ammo-20mm-ShortFuse", "20mm Short-Fuse");
    this.Text("AO-Ammo-25mm-ShortFuse", "25mm Short-Fuse");
    this.Text("AO-Ammo-PlusP-Desc", "Loaded hot, over standard pressure. More punch and more reach, but it kicks harder and wears you out faster.\n\n+10% damage. +15% range. +25% recoil. Costs more stamina per shot.");
    this.Text("AO-Ammo-Birdshot-Desc", "A shell full of small shot. It spreads wide and makes people flinch, but armor shrugs most of it off.\n\nTwice the pellets, each one weaker. Wider spread. Armor is 50% more effective against it. Targets flinch more.");
    this.Text("AO-Ammo-4ga-Birdshot-Desc", "Birdshot in a 4-gauge shell. More pellets and a wider spread than anything a 12-gauge throws.\n\n2.5x the pellets, each one weaker. Much wider spread. Armor is 50% more effective against it. Targets flinch more.");
    this.Text("AO-Ammo-Bricks-Desc", "Dense slugs, heavier than standard. They hit harder, but the rails take longer to get them moving.\n\n+15% damage. Charges 30% slower.");
    this.Text("AO-Ammo-ShortFuse-Desc", "Seekers with a bigger warhead and less fuel. They hit harder but burn out sooner, so keep your targets close.\n\n+20% damage. Shorter range.");
    // Rare and Epic rounds (LocalizationRounds.reds, generated by tools/rounds/rounds.py).
    let rounds: array<String> = AORoundTexts.Pairs();
    let i: Int32 = 0;
    while i + 1 < ArraySize(rounds) {
      this.Text(rounds[i], rounds[i + 1]);
      i += 2;
    }
    // Recipe items (LocalizationRecipes.reds, generated by tools/crafting/crafting.py).
    let recipes: array<String> = AORecipeTexts.Pairs();
    i = 0;
    while i + 1 < ArraySize(recipes) {
      this.Text(recipes[i], recipes[i + 1]);
      i += 2;
    }
  }
}
