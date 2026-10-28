module AmmoOverhaul

// An "Ammo" section on the weapon screen, between Attachments and Mods. The chooser builds two
// sections itself: Attachments (scope, magazine and silencer part types, RebuildParts) and Mods
// (every other slot, from GetSlots), so a feed slot would land under Mods. The feed slots are taken
// out of GetSlots and shown in a panel of our own (label and slot row), placed just before the Mods
// block as its sibling: the chooser hides the whole Mods block on guns with no mod slots, which
// would hide anything inside it. If that can't be done (the Mods block has no parent to add to),
// the feed slots stay under Mods.

@addField(InventoryWeaponItemChooser)
public let aoAmmoLabel: wref<inkText>;

@addField(InventoryWeaponItemChooser)
public let aoAmmoSlots: wref<inkHorizontalPanel>;

@addField(InventoryWeaponItemChooser)
public let aoAmmoSection: wref<inkVerticalPanel>;

@wrapMethod(InventoryWeaponItemChooser)
protected func GetSlots() -> array<ref<InventoryItemAttachments>> {
  let slots: array<ref<InventoryItemAttachments>> = wrappedMethod();
  if !this.AOEnsureAmmoSection() {
    return slots;
  }
  let kept: array<ref<InventoryItemAttachments>>;
  for slot in slots {
    if !AOData.IsFeedSlot(slot.SlotID) {
      ArrayPush(kept, slot);
    }
  }
  return kept;
}

// The Mods label shows when the gun has generic slots besides its parts; feed slots don't count.
@wrapMethod(InventoryWeaponItemChooser)
private final func UpdateModsLabel(const parts: script_ref<array<ref<InventoryItemAttachments>>>) -> Void {
  wrappedMethod(parts);
  if !IsDefined(this.aoAmmoSlots) {
    return;
  }
  let generic: Int32 = 0;
  let itemData: InventoryItemData = this.itemDisplay.GetItemData();
  let attachments: array<ref<InventoryItemAttachments>> = InventoryItemData.GetAttachments(itemData);
  for attachment in attachments {
    if Equals(attachment.SlotType, InventoryItemAttachmentType.Generic) && !AOData.IsFeedSlot(attachment.SlotID) {
      generic += 1;
    }
  }
  let hasMods: Bool = generic - ArraySize(Deref(parts)) > 0;
  inkWidgetRef.SetVisible(this.m_softwareModsLabel, hasMods);
  inkWidgetRef.SetVisible(this.m_softwareModsContainer, hasMods);
}

@wrapMethod(InventoryWeaponItemChooser)
protected func RebuildSlots() -> Void {
  wrappedMethod();
  this.AORebuildAmmoSection();
}

// Makes the section (label over slot row) once, just before the Mods block. False if there's
// nowhere to put it.
@addMethod(InventoryWeaponItemChooser)
private func AOEnsureAmmoSection() -> Bool {
  if IsDefined(this.aoAmmoSlots) {
    return true;
  }
  let modsLabel: ref<inkText> = inkTextRef.Get(this.m_softwareModsLabel) as inkText;
  let modsBlock: ref<inkWidget> = inkWidgetRef.Get(this.m_softwareModsContainer);
  let parent: ref<inkCompoundWidget> = IsDefined(modsBlock) ? modsBlock.GetParentWidget() as inkCompoundWidget : null;
  if !IsDefined(modsLabel) || !IsDefined(parent) {
    AmmoFeedSystem.Log("weapon screen: no parent for the Mods block, feed slots stay under Mods");
    return false;
  }

  let section: ref<inkVerticalPanel> = new inkVerticalPanel();
  section.SetName(n"aoAmmoSection");
  section.SetHAlign(modsBlock.GetHAlign());
  section.SetMargin(modsBlock.GetMargin());
  section.SetFitToContent(true);
  section.Reparent(parent, parent.GetChildIndex(modsBlock));

  let label: ref<inkText> = new inkText();
  label.SetName(n"aoAmmoLabel");
  label.fontFamily = modsLabel.fontFamily;
  label.SetFontStyle(modsLabel.GetFontStyle());
  label.SetFontSize(modsLabel.GetFontSize());
  label.SetLetterCase(modsLabel.GetLetterCase());
  label.style = modsLabel.style;
  label.SetState(modsLabel.GetState());
  label.SetTintColor(modsLabel.GetTintColor());
  label.SetOpacity(modsLabel.GetOpacity());
  label.SetMargin(modsLabel.GetMargin());
  label.SetHAlign(modsLabel.GetHAlign());
  label.SetVAlign(modsLabel.GetVAlign());
  label.SetAnchor(modsLabel.GetAnchor());
  label.SetSizeRule(modsLabel.GetSizeRule());
  label.SetFitToContent(true);
  label.SetText(GetLocalizedTextByKey(n"AO-Section-Ammo"));
  label.Reparent(section);

  let slots: ref<inkHorizontalPanel> = new inkHorizontalPanel();
  slots.SetName(n"aoAmmoSlots");
  slots.SetHAlign(modsLabel.GetHAlign());
  slots.SetFitToContent(true);
  slots.Reparent(section);

  this.aoAmmoSection = section;
  this.aoAmmoLabel = label;
  this.aoAmmoSlots = slots;
  return true;
}

// One slot display per feed slot of the gun, set up the way the chooser sets up its own slots.
@addMethod(InventoryWeaponItemChooser)
private func AORebuildAmmoSection() -> Void {
  if !IsDefined(this.aoAmmoSlots) {
    return;
  }
  let itemData: InventoryItemData = this.itemDisplay.GetItemData();
  let feeds: array<ref<InventoryItemAttachments>>;
  let attachments: array<ref<InventoryItemAttachments>> = InventoryItemData.GetAttachments(itemData);
  for attachment in attachments {
    if AOData.IsFeedSlot(attachment.SlotID) {
      ArrayPush(feeds, attachment);
    }
  }
  let visible: Bool = ArraySize(feeds) > 0;
  this.aoAmmoSection.SetVisible(visible);
  while this.aoAmmoSlots.GetNumChildren() > ArraySize(feeds) {
    this.aoAmmoSlots.RemoveChildByIndex(this.aoAmmoSlots.GetNumChildren() - 1);
  }
  while this.aoAmmoSlots.GetNumChildren() < ArraySize(feeds) {
    let spawned: ref<InventoryItemDisplayController> = ItemDisplayUtils.SpawnCommonSlotController(this, this.aoAmmoSlots, this.GetSlotDisplayToSpawn()) as InventoryItemDisplayController;
    if !IsDefined(spawned) {
      break;
    }
    spawned.GetRootWidget().RegisterToCallback(n"OnRelease", this, n"OnItemInventoryClick");
    spawned.GetRootWidget().RegisterToCallback(n"OnHoverOver", this, n"OnInventoryItemHoverOver");
    spawned.GetRootWidget().RegisterToCallback(n"OnHoverOut", this, n"OnInventoryItemHoverOut");
  }
  let ids: String = "";
  let i: Int32 = 0;
  while i < ArraySize(feeds) && i < this.aoAmmoSlots.GetNumChildren() {
    let slot: ref<InventoryItemDisplayController> = this.aoAmmoSlots.GetWidgetByIndex(i).GetController() as InventoryItemDisplayController;
    slot.SetParentItem(InventoryItemData.GetGameItemData(itemData));
    slot.Setup(this.inventoryDataManager, feeds[i].ItemData, feeds[i].SlotID, ItemDisplayContext.Attachment, true);
    ids += " " + TDBID.ToStringDEBUG(feeds[i].SlotID);
    i += 1;
  }
  // The dual-wield chooser rebuilds too, usually with no item; keep the one that has a gun.
  if !InventoryItemData.IsEmpty(itemData) {
    AmmoFeedSystem.Get(GetGameInstance()).NoteAmmoSection(this.AOSectionOrder() + " | slots" + ids + " | label " + this.aoAmmoLabel.GetText());
    AmmoFeedSystem.Log("weapon screen: " + TDBID.ToStringDEBUG(ItemID.GetTDBID(InventoryItemData.GetID(itemData))) + " feeds " + IntToString(ArraySize(feeds)) + " of " + IntToString(ArraySize(attachments)) + " | " + this.AOSectionOrder() + " | " + this.AOParentChain());
  }
}

// The Ammo label's parents, innermost first: "name(visible)/..." (debugging where the row sits).
@addMethod(InventoryWeaponItemChooser)
private func AOParentChain() -> String {
  let text: String = "";
  let widget: ref<inkWidget> = this.aoAmmoLabel;
  let depth: Int32 = 0;
  while IsDefined(widget) && depth < 6 {
    text += NameToString(widget.GetName()) + "(" + (widget.IsVisible() ? "v" : "h") + ")/";
    widget = widget.GetParentWidget();
    depth += 1;
  }
  return text;
}

// Where the three sections sit in the Ammo section's parent, e.g. "attachments 1 ammo 3 mods 4"
// (-1 for one in another parent), and whether the Ammo label and every parent above it are visible.
@addMethod(InventoryWeaponItemChooser)
private func AOSectionOrder() -> String {
  let parent: ref<inkCompoundWidget> = this.aoAmmoSection.GetParentWidget() as inkCompoundWidget;
  let attachments: ref<inkWidget> = inkWidgetRef.Get(this.m_attachmentsContainer);
  let mods: ref<inkWidget> = inkWidgetRef.Get(this.m_softwareModsContainer);
  let a: Int32 = IsDefined(attachments) && attachments.GetParentWidget() == parent ? parent.GetChildIndex(attachments) : -1;
  let m: Int32 = IsDefined(mods) && mods.GetParentWidget() == parent ? parent.GetChildIndex(mods) : -1;
  let shown: Bool = true;
  let widget: ref<inkWidget> = this.aoAmmoLabel;
  while IsDefined(widget) {
    shown = shown && widget.IsVisible();
    widget = widget.GetParentWidget();
  }
  return "attachments " + IntToString(a) + " ammo " + IntToString(parent.GetChildIndex(this.aoAmmoSection)) + " mods " + IntToString(m) + " shown " + (shown ? "true" : "false");
}
