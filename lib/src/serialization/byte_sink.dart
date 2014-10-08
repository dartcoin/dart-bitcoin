part of dartcoin.core;


/**
 * A sink for bytes.
 *
 * Bytes can be added to the sink and eventually retrieved as a single byte array.
 */
class ByteSink implements Sink {

  Uint8List _buffer;
  int _count;

  ByteSink([int initialSize = 32]) {
    if(initialSize < 0)
      throw new ArgumentError("Negative initial size: $initialSize");
    _buffer = new Uint8List(initialSize);
    _count = 0;
  }

  /**
   * Add bytes to the sink.
   *
   * Data types allowed: [TypedData] (f.e. [Uint8List]), [List]<int>, [int]
   */
  @override
  void add(dynamic bytes, [int offset, int length]) {
    if(_buffer == null)
      throw new StateError("This sick has already been closed.");
    // test for typed_data
    if(bytes is TypedData) {
      offset = offset == null ? 0 : offset;
      length = length == null ? bytes.lengthInBytes - offset : length;
      if(offset < 0 || length < 0 || offset > bytes.lengthInBytes ||
          (offset + length) > bytes.lengthInBytes || (offset + length) < 0) {
        throw new ArgumentError("Invalid offset or lenght.");
      } else if(length == 0) {
        return;
      }
      int newCount = _count + length;
      if(newCount > _buffer.length)
        _increaseBufferSize(newCount);
      ByteBuffer bytesBuffer = bytes.buffer;
      _buffer.setRange(_count, _count + length, bytesBuffer.asUint8List(bytes.offsetInBytes + offset, length));
      _count = newCount;
    }
    // test for List<int>
    else if (bytes is List) {
      offset = offset == null ? 0 : offset;
      length = length == null ? bytes.length - offset : length;
      if(offset < 0 || length < 0 || offset > bytes.length ||
      (offset + length) > bytes.length || (offset + length) < 0) {
        throw new ArgumentError("Invalid offset or lenght.");
      } else if(length == 0) {
        return;
      }
      int newCount = _count + length;
      if(newCount > _buffer.length)
        _increaseBufferSize(newCount);
      _buffer.setRange(_count, _count + length, bytes.getRange(offset, offset + length));
      _count = newCount;
    }
    // test for 1 byte integer
    else if(bytes is int) {
      if((0xFF & bytes) != bytes)
        throw new ArgumentError("Not a valid byte value: should be between 0 and 255.");
      int newCount = _count + 1;
      if(newCount > _buffer.length)
        _increaseBufferSize(newCount);
      _buffer[_count] = bytes;
      _count = newCount;
    }
  }

  void _increaseBufferSize(int minimalLength) {
    Uint8List newBuffer = new Uint8List(max(_buffer.length << 1, minimalLength));
    newBuffer.setRange(0, _count, _buffer);
    _buffer = newBuffer;
  }

  /**
   * Reset the sink to an empty one.
   */
  void reset() {
    if(_buffer == null)
      throw new StateError("This sick has already been closed.");
    _count = 0;
  }

  /**
   * Closing this sink will remove all its contents and make it unusable.
   */
  @override
  void close() {
    if(_buffer == null)
      throw new StateError("This sick has already been closed.");
    _buffer = null;
    _count = null;
  }

  /**
   * Get the current size of the content of the sink.
   */
  int get size {
    if(_buffer == null)
      throw new StateError("This sick has already been closed.");
    return _count;
  }

  @override
  String toString() => toHexString();

  /**
   * Retrieve the content of the sink as a [Uint8List].
   */
  Uint8List toUint8List([int offset = 0, int length]) {
    if (_buffer == null)
      throw new StateError("This sick has already been closed.");
    if(length == null)
      length = _count;
    if(offset < 0 || length < 0 || (offset + length) > _count || (offset + length) < 0)
      throw new ArgumentError("Offset and length values of $offset and $length invalid for sink size $_count");
    return new Uint8List.view(_buffer.buffer, offset, length);
  }

  /**
   * Retrieve the content of the sink as a [ByteData] object.
   */
  ByteData toByteData() {
    if (_buffer == null)
      throw new StateError("This sick has already been closed.");
    return new ByteData.view(_buffer.buffer, 0, _count);
  }

  /**
   * Retrieve the content of the sink as a hexadecimal string.
   */
  String toHexString() => CryptoUtils.bytesToHex(toUint8List());


}