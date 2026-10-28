module AmmoOverhaul

// An "Ammo" section on the weapon screen, between Attachments and Mods. The chooser builds two
// sections itself: Attachments (scope, magazine and silencer part types, RebuildParts) and Mods
// (every other slot, from GetSlots), so a feed slot would land under Mods. The feed slots are taken
// out of GetSlots and shown in a label and slot row of our own, made next to the Mods label. If
// that can't be done (the Mods label has no parent to add to), the feed slots stay under Mods.

@addField(InventoryWeaponItemChooser)
public let aoAmmoLabel: wref<inkText>;

@addField(InventoryWeaponItemChooser)
public let aoAmmoSlots: wref<inkHorizontalPanel>;

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

// Makes the label and slot row once, just before the Mods label (and its spacer). False if there's
// nowhere to put them.
@addMethod(InventoryWeaponItemChooser)
private func AOEnsureAmmoSection() -> Bool {
  if IsDefined(this.aoAmmoSlots) {
    return true;
  }
  let modsLabel: ref<inkText> = inkTextRef.Get(this.m_softwareModsLabel) as inkText;
  let parent: ref<inkCompoundWidget> = IsDefined(modsLabel) ? modsLabel.GetParentWidget() as inkCompoundWidget : null;
  if !IsDefined(parent) {
    AmmoFeedSystem.Log("weapon screen: no parent for the Mods label, feed slots stay under Mods");
    return false;
  }
  let index: Int32 = parent.GetChildIndex(modsLabel);
  let push: ref<inkWidget> = inkWidgetRef.Get(this.m_softwareModsPush);
  if IsDefined(push) && push.GetParentWidget() == parent {
    index = Min(index, parent.GetChildIndex(push));
  }

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
  label.Reparent(parent, index);

  let slots: ref<inkHorizontalPanel> = new inkHorizontalPanel();
  slots.SetName(n"aoAmmoSlots");
  slots.SetHAlign(modsLabel.GetHAlign());
  slots.SetFitToContent(true);
  slots.Reparent(parent, index + 1);

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
  this.aoAmmoLabel.SetVisible(visible);
  this.aoAmmoSlots.SetVisible(visible);
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
  AmmoFeedSystem.Get(GetGameInstance()).NoteAmmoSection(this.AOSectionOrder() + " | slots" + ids + " | label " + this.aoAmmoLabel.GetText());
}

// Where the three section labels sit in the Ammo label's parent, e.g. "attachments 1 ammo 3 mods 5"
// (-1 for a label in another parent).
@addMethod(InventoryWeaponItemChooser)
private func AOSectionOrder() -> String {
  let parent: ref<inkCompoundWidget> = this.aoAmmoLabel.GetParentWidget() as inkCompoundWidget;
  let attachments: ref<inkWidget> = inkTextRef.Get(this.m_attachmentsLabel);
  let mods: ref<inkWidget> = inkTextRef.Get(this.m_softwareModsLabel);
  let a: Int32 = IsDefined(attachments) && attachments.GetParentWidget() == parent ? parent.GetChildIndex(attachments) : -1;
  let m: Int32 = IsDefined(mods) && mods.GetParentWidget() == parent ? parent.GetChildIndex(mods) : -1;
  return "attachments " + IntToString(a) + " ammo " + IntToString(parent.GetChildIndex(this.aoAmmoLabel)) + " mods " + IntToString(m);
}
