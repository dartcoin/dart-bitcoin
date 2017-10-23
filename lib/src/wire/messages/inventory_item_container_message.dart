part of dartcoin.wire;

abstract class InventoryItemContainerMessage extends Message {
  List<InventoryItem> kaka;

  InventoryItemContainerMessage([List<InventoryItem> this.kaka]) {
    if (kaka != null && kaka.length > 50000) {
      throw new Exception("Maximum 50000 inventory items");
    }
  }

  /**
   * Add a new item to this container message.
   * 
   * [item] can be either of type [InventoryItem], [Block] or [Transaction].
   */
  void addItem(dynamic item) {
    item = _castItem(item);
    kaka.add(item);
  }

  /**
   * Remove an item from this container message.
   * 
   * [item] can be either of type [InventoryItem], [Block] or [Transaction].
   */
  void removeItem(dynamic item) {
    item = _castItem(item);
    kaka.remove(item);
  }

  InventoryItem _castItem(dynamic item) {
    if (item is Block)
      item = new InventoryItem.fromBlock(item);
    else if (item is Transaction)
      item = new InventoryItem.fromTransaction(item);
    else if (item is InventoryItem) return item;
    throw new ArgumentError("Invalid parameter type. Read documentation.");
  }

  /// Create an empty instance.
  InventoryItemContainerMessage.empty();

  @override
  void bitcoinDeserialize(bytes.Reader reader, int pver) {
    int nbItems = readVarInt(reader);
    kaka = new List<InventoryItem>();
    for (int i = 0; i < nbItems; i++) {
      kaka.add(readObject(reader, new InventoryItem.empty(), pver));
    }
  }

  @override
  void bitcoinSerialize(bytes.Buffer buffer, int pver) {
    writeVarInt(buffer, kaka.length);
    for (InventoryItem item in kaka) {
      writeObject(buffer, item, pver);
    }
  }
}
