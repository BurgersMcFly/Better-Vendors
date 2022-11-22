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

  private final func PerformItemTransfer(buyer: wref<GameObject>, seller: wref<GameObject>, itemTransaction: SItemTransaction) -> Bool {

    let moneyStack: SItemStack;
    let blackBoard: ref<IBlackboard>;
    let buyerHasEnoughMoney: Bool;
    let buyerMoney: Int32;
    let sellerHasEnoughItems: Bool;
    let sellerItemQuantity: Int32;
    let totalPrice: Int32;
    let transactionSystem: ref<TransactionSystem>;
    let uiSystem: ref<UISystem>;
    let vendorNotification: ref<UIMenuNotificationEvent>;
    this.FillVendorInventory(false);
    this.m_lastInteractionTime = GameInstance.GetTimeSystem(this.m_gameInstance).GetGameTimeStamp();
    blackBoard = GameInstance.GetBlackboardSystem(buyer.GetGame()).Get(GetAllBlackboardDefs().UI_Vendor);
    transactionSystem = GameInstance.GetTransactionSystem(this.m_gameInstance);
    totalPrice = itemTransaction.pricePerItem * itemTransaction.itemStack.quantity;
    buyerMoney = transactionSystem.GetItemQuantity(buyer, MarketSystem.Money());
    sellerItemQuantity = transactionSystem.GetItemQuantity(seller, itemTransaction.itemStack.itemID);
    buyerHasEnoughMoney = buyerMoney >= totalPrice;
    sellerHasEnoughItems = sellerItemQuantity >= itemTransaction.itemStack.quantity;
    if sellerItemQuantity == 0 {
      LogError("[Vendor] Trying to sell item: " + TDBID.ToStringDEBUG(ItemID.GetTDBID(itemTransaction.itemStack.itemID)) + " with quantity 0");
      return false;
    };
    if !buyerHasEnoughMoney {
      vendorNotification = new UIMenuNotificationEvent();
      if buyer.IsPlayer() {
        vendorNotification.m_notificationType = UIMenuNotificationType.VNotEnoughMoney;
      } else {
        moneyStack.itemID = MarketSystem.Money();
        moneyStack.quantity = 500000;
        transactionSystem.GiveItem(buyer, moneyStack.itemID, moneyStack.quantity);
      };
      uiSystem = GameInstance.GetUISystem(this.m_gameInstance);
      uiSystem.QueueEvent(vendorNotification);
      return false;
    };
    GameInstance.GetTelemetrySystem(buyer.GetGame()).LogItemTransaction(buyer, seller, itemTransaction.itemStack.itemID, Cast<Uint32>(itemTransaction.pricePerItem), Cast<Uint32>(itemTransaction.itemStack.quantity), Cast<Uint32>(totalPrice));
    if !sellerHasEnoughItems {
      transactionSystem.GiveItem(seller, itemTransaction.itemStack.itemID, itemTransaction.itemStack.quantity - sellerItemQuantity);
    };
    transactionSystem.TransferItem(seller, buyer, itemTransaction.itemStack.itemID, itemTransaction.itemStack.quantity, itemTransaction.itemStack.dynamicTags);
    transactionSystem.TransferItem(buyer, seller, MarketSystem.Money(), totalPrice);
    blackBoard.SignalVariant(GetAllBlackboardDefs().UI_Vendor.VendorData);
    return true;
  }