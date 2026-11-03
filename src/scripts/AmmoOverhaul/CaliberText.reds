module AmmoOverhaul

// The gun's caliber on the type line of its tooltip, as "Pistol - .45". Tooltips come through
// both of the header's update paths, depending on the screen.

@wrapMethod(NewItemTooltipHeaderController)
public func Update(data: ref<MinimalItemTooltipData>) -> Void {
  wrappedMethod(data);
  this.AOAddCaliber(data.itemTweakID);
}

@wrapMethod(NewItemTooltipHeaderController)
public final func NEW_Update(data: wref<UIInventoryItem>, comparisonData: wref<UIInventoryItemComparisonManager>) -> Void {
  wrappedMethod(data, comparisonData);
  this.AOAddCaliber(data.GetTweakDBID());
}

@addMethod(NewItemTooltipHeaderController)
private func AOAddCaliber(item: TweakDBID) -> Void {
  let caliber: String = AOData.FindCaliber(item);
  if StrLen(caliber) == 0 {
    return;
  }
  let text: String = inkTextRef.GetText(this.m_itemTypeText);
  let localized: String = GetLocalizedText(text);
  inkTextRef.SetText(this.m_itemTypeText, (StrLen(localized) > 0 ? localized : text) + " - " + AOData.CaliberName(caliber));
}
