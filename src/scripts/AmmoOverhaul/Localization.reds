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
    this.Text("AO-Ammo-9mm-Incendiary", "9mm Incendiary Rounds");
    this.Text("AO-Ammo-9mm-Incendiary-Desc", "Phosphorus-cored pistol rounds. Sets targets on fire.");
    this.Text("AO-Feed-9mm-FMJ", "Ammo Feed: 9mm FMJ");
    this.Text("AO-Feed-9mm-FMJ-Desc", "Feeds standard full-metal-jacket handgun ammo.");
    this.Text("AO-Feed-9mm-Incendiary", "Ammo Feed: 9mm Incendiary");
    this.Text("AO-Feed-9mm-Incendiary-Desc", "Feeds 9mm incendiary rounds. Switching types unloads the gun; unfired rounds stay in their stack.");
  }
}
