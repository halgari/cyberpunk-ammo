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
    // draft, Task 8
    this.Text("AO-Ammo-45-Ball", ".45 Ball");
    this.Text("AO-Ammo-45-Ball-Desc", "Big, slow .45 FMJ. Hits harder than a 9, but armor stops more of it.\n\n+10% damage. Armor is 15% more effective against it. +10% recoil.");
    this.Text("AO-Ammo-45-Mushrooms", ".45 Mushrooms");
    // draft, Task 8
    this.Text("AO-Ammo-12mm-Ball", "12mm Ball");
    this.Text("AO-Ammo-12mm-Ball-Desc", "Magnum loads for revolvers and hand cannons. Heavy, pricey, and it kicks like a mule.\n\n+15% damage. Ignores 10% of armor. +35% recoil.");
    this.Text("AO-Ammo-12mm-Mushrooms", "12mm Mushrooms");
    this.Text("AO-Ammo-5mm-RailSlugs", "5mm Rail Slugs");
    this.Text("AO-Ammo-5mm-RailSlugs-Desc", "Steel slugs for light railguns. Nothing to them, the rails do all the work.\n\nStandard light rail ammo. No special effects.");
    this.Text("AO-Ammo-5mm-Sleevers", "5mm Sleevers");
    this.Text("AO-Ammo-5mm-Sleevers-Desc", "Skinny slug in a plastic sleeve. The rails grab it quicker, so you charge faster, but it hits a bit softer.\n\nCharges 30% faster. -5% damage.");
    this.Text("AO-Ammo-10mm-Seekers", "10mm Seekers");
    this.Text("AO-Ammo-10mm-Seekers-Desc", "Standard smart rockets. Get a lock and they chase the target for you.\n\nStandard smart ammo. Tracks locked targets.");
    this.Text("AO-Ammo-10mm-Dumbfires", "10mm Dumbfires");
    this.Text("AO-Ammo-10mm-Dumbfires-Desc", "Smart rockets with the chip pulled and extra propellant packed in. Hits harder, but it only goes where you point it.\n\n+25% damage. Doesn't track targets.");
  }
}
