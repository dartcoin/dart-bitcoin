part of dartcoin.core;


/**
 * This class represents a general output script type that can be categorized as pay-to-address.
 * 
 * Examples of scripts in this category are pay-to-puubkey-hash and pay-to-script-hash.
 */
abstract class PayToAddressOutputScript extends Script {
  
  factory PayToAddressOutputScript(Address address, [bool encoded = true]) {
    if(address.isP2SHAddress)
      return new PayToScriptHashOutputScript(address.hash160, encoded);
    return new PayToPubKeyHashOutputScript(address.hash160, encoded);
  }
  
  PayToAddressOutputScript._super(Uint8List bytes) : super(bytes);
  
  Address getAddress([NetworkParameters params = NetworkParameters.MAIN_NET]);
  
}