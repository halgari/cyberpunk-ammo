// Dev only: runs the vanilla magazine refund effectors on V for tools/snippets/calibers/refill.sh.
// CET can't call their protected ActionOn, a subclass can. Shinobi 50 (Proficiencies.Reflexes_50)
// refunds 20%.
public class AODevCeaselessLead extends CeaselessLeadAmmoEffector {
  public final func Run(owner: ref<GameObject>, percent: Float) -> Void {
    this.m_percentToRefund = percent;
    this.ActionOn(owner);
  }
}

public class AODevValentinosFrenzy extends ValentinosFrenzyEffector {
  public final func Run(owner: ref<GameObject>, count: Int32) -> Void {
    this.m_countToRefund = count;
    this.m_weaponToRefund = n"WeaponRight";
    this.ActionOn(owner);
  }
}
