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
    // draft, Task 8
    this.Text("AO-Ammo-556-Ball", "5.56 Ball");
    this.Text("AO-Ammo-556-Ball-Desc", "Standard rifle FMJ. Light, cheap, and it gets through vests better than pistol rounds.\n\nIgnores 15% of armor.");
    this.Text("AO-Ammo-556-Mushrooms", "5.56 Mushrooms");
    // draft, Task 8
    this.Text("AO-Ammo-762-Ball", "7.62 Ball");
    this.Text("AO-Ammo-762-Ball-Desc", "Full-power rifle rounds. Hits harder and reaches further than 5.56, and kicks more.\n\n+5% damage. Ignores 25% of armor. +20% recoil. +10% range.");
    this.Text("AO-Ammo-762-Mushrooms", "7.62 Mushrooms");
    // draft, Task 8
    this.Text("AO-Ammo-127-Ball", "12.7 Ball");
    this.Text("AO-Ammo-127-Ball-Desc", "Half-inch rounds for anti-materiel rifles. Heavy and pricey, and they punch through plating.\n\nIgnores 40% of armor. +25% recoil.");
    this.Text("AO-Ammo-127-Mushrooms", "12.7 Mushrooms");
    // Shared by every caliber's Sleevers and Dumbfires.
    this.Text("AO-Ammo-Sleevers-Desc", "Skinny slug in a plastic sleeve. The rails grab it quicker, so you charge faster, but it hits a bit softer.\n\nCharges 30% faster. -5% damage.");
    this.Text("AO-Ammo-Dumbfires-Desc", "Smart rockets with the chip pulled and extra propellant packed in. Hits harder, but it only goes where you point it.\n\n+25% damage. Doesn't track targets.");
    // draft, Task 8
    this.Text("AO-Ammo-Heavy-RailSlugs", "Heavy Rail Slugs");
    this.Text("AO-Ammo-Heavy-RailSlugs-Desc", "Dense steel slugs for full-size rails. Heavier than the 5mm stuff and better against plating.\n\nIgnores 20% of armor. +20% recoil.");
    this.Text("AO-Ammo-Heavy-Sleevers", "Heavy Sleevers");
    // draft, Task 8
    this.Text("AO-Ammo-20mm-Seekers", "20mm Seekers");
    this.Text("AO-Ammo-20mm-Seekers-Desc", "Cluster rockets for smart shotguns. Lock on and the whole swarm goes after the target, but armor soaks a lot of it.\n\nArmor is 20% more effective against it. Tracks locked targets.");
    this.Text("AO-Ammo-20mm-Dumbfires", "20mm Dumbfires");
    // draft, Task 8
    this.Text("AO-Ammo-25mm-Seekers", "25mm Seekers");
    this.Text("AO-Ammo-25mm-Seekers-Desc", "Big smart darts for the Ashura. Heavy, pricey and hard to find.\n\nIgnores 10% of armor. Tracks locked targets.");
    this.Text("AO-Ammo-25mm-Dumbfires", "25mm Dumbfires");
    // draft, Task 8
    this.Text("AO-Ammo-Buckshot", "Buckshot");
    this.Text("AO-Ammo-Buckshot-Desc", "12-gauge buck. A handful of pellets per shell: wrecks anything up close, falls off fast past a few meters.\n\nArmor is 25% more effective against it. -25% range.");
    this.Text("AO-Ammo-Slugs", "Slugs");
    this.Text("AO-Ammo-Slugs-Desc", "One solid lead slug instead of pellets. Same punch in a single hit, and it flies straight.\n\nFires one projectile with the whole shot's damage. Much tighter spread. Double range.");
    // draft, Task 8
    this.Text("AO-Ammo-4ga-Buckshot", "4ga Buckshot");
    this.Text("AO-Ammo-4ga-Buckshot-Desc", "Shells as fat as a beer can, for the Carnage. Heavy, pricey, and they kick hard.\n\nArmor is 25% more effective against it. +30% recoil.");
    this.Text("AO-Ammo-4ga-Slugs", "4ga Slugs");
    this.Text("AO-Ammo-4ga-Slugs-Desc", "A slug the size of your thumb. Whoever it hits goes down.\n\nFires one projectile with the whole shot's damage, +30%. Ignores 50% of armor. Knocks the target down. Double range. +60% recoil.");
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
