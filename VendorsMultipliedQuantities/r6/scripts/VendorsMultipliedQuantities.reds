// BetterVendors, Cyberpunk 2077 mod that improves vendors
// Copyright (C) 2022 BurgersMcFly

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

@replaceMethod(Vendor)

  private final func FillVendorInventory(allowRegeneration: Bool) -> Void {
    let exclucedItemTags: array<CName>;
    let forceQuality: CName;
    let i: Int32;
    let itemData: wref<gameItemData>;
    let itemRecord: wref<Item_Record>;
    let ownerNPC: ref<NPCPuppet>;
    let powerLevelMod: ref<gameStatModifierData>;
    let prevInvItemList: array<wref<gameItemData>>;
    let qualityMod: ref<gameStatModifierData>;
    let statsSystem: ref<StatsSystem>;
    let transactionSystem: ref<TransactionSystem>;
    if allowRegeneration && this.ShouldRegenerateStock() {
      this.RegenerateStock();
    } else {
      if this.m_inventoryInit {
        return;
      };
    };
    ownerNPC = this.m_vendorObject as NPCPuppet;
    if IsDefined(ownerNPC) {
      if !ScriptedPuppet.IsActive(ownerNPC) {
        return;
      };
    };
    this.m_inventoryInit = true;
    this.m_inventoryReinitWithPlayerStats = false;
    ArrayPush(exclucedItemTags, n"Prop");
    GameInstance.GetTransactionSystem(this.m_gameInstance).GetItemListExcludingTags(this.m_vendorObject, exclucedItemTags, prevInvItemList);
    i = 0;
    while i < ArraySize(prevInvItemList) {
      GameInstance.GetTransactionSystem(this.m_gameInstance).RemoveItem(this.m_vendorObject, prevInvItemList[i].GetID(), prevInvItemList[i].GetQuantity());
      i += 1;
    };
    if IsDefined(this.m_vendorObject) && IsDefined(this.m_vendorRecord) && IsDefined(this.m_vendorRecord.VendorType()) && NotEquals(this.m_vendorRecord.VendorType().Type(), gamedataVendorType.VendingMachine) {
      transactionSystem = GameInstance.GetTransactionSystem(this.m_vendorObject.GetGame());
      statsSystem = GameInstance.GetStatsSystem(this.m_vendorObject.GetGame());
      i = 0;
      while i < ArraySize(this.m_stock) {
        itemRecord = TweakDBInterface.GetItemRecord(ItemID.GetTDBID(this.m_stock[i].itemID));
        transactionSystem.GiveItem(this.m_vendorObject, this.m_stock[i].itemID, (this.m_stock[i].quantity)*10, itemRecord.Tags());
        itemData = transactionSystem.GetItemData(this.m_vendorObject, this.m_stock[i].itemID);
        if this.m_stock[i].quantity < 100 {
        transactionSystem.GiveItem(this.m_vendorObject, this.m_stock[i].itemID, (this.m_stock[i].quantity)*10, itemRecord.Tags());
        }
        if !itemRecord.IsSingleInstance() && !itemData.HasTag(n"Cyberware") {
          statsSystem.RemoveAllModifiers(itemData.GetStatsObjectID(), gamedataStatType.PowerLevel, true);
          powerLevelMod = RPGManager.CreateStatModifier(gamedataStatType.PowerLevel, gameStatModifierType.Additive, Cast<Float>(this.m_stock[i].powerLevel) / 100.00);
          statsSystem.AddSavedModifier(itemData.GetStatsObjectID(), powerLevelMod);
          forceQuality = TweakDBInterface.GetCName(this.m_stock[i].vendorItemID + t".forceQuality", n"None");
          if IsNameValid(forceQuality) {
            RPGManager.ForceItemQuality(this.m_vendorObject, itemData, forceQuality);
          } else {
            if Equals(RPGManager.GetItemRecord(this.m_stock[i].itemID).Quality().Type(), gamedataQuality.Random) && itemData.GetStatValueByType(gamedataStatType.Quality) == 0.00 {
              statsSystem.RemoveAllModifiers(itemData.GetStatsObjectID(), gamedataStatType.Quality, true);
              qualityMod = RPGManager.CreateStatModifier(gamedataStatType.Quality, gameStatModifierType.Additive, 1.00);
              statsSystem.AddSavedModifier(itemData.GetStatsObjectID(), qualityMod);
            };
          };
        };
        i += 1;
      };
    };
  }