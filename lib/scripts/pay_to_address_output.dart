library dartcoin.scripts.output.pay_to_address;

import "dart:typed_data";

import "package:dartcoin/core.dart";
import "package:dartcoin/script.dart";

import "package:dartcoin/scripts/pay_to_pubkey_hash_output.dart";
import "package:dartcoin/scripts/pay_to_script_hash_output.dart";

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
  
  PayToAddressOutputScript.fromBytesUnchecked(Uint8List bytes) : super(bytes);
  
  Address getAddress([NetworkParameters params = NetworkParameters.MAIN_NET]);
  
}