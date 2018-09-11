library bitcoin.src.crypto;

import 'dart:io';

import 'package:bitcoin/core.dart';
import 'package:bitcoin/wire.dart';
import 'package:cryptoutils/hash.dart';
import 'package:observable/observable.dart';
import 'package:protobuf/protobuf.dart';
import 'dart:async';
import 'package:sqlite/sqlite.dart';
import "package:upnp/upnp.dart";
import "package:events/events.dart";


class FullNode extends Node {
  FullNode({params, store, chain, mempool, network})
      : super(params: params, store: store, chain: chain, mempool: mempool, network: network) {
    start();
  }

  void start() {
    print("Starting");
    // Join network
    // Attach event listeners
    super.start();
  }

  void stop() {
    // Disconnect from network
    // Detach event listeners
    super.stop();
  }
}

//abstract class SpvNode extends Node {
//  SpvNode(NetworkParameters params, Datastore store) : super(params, store);
//}


abstract class Node {
  NetworkParameters params;
  Datastore store;
  ObservableList<Block> blocks = new ObservableList<Block>();
  Network network;

  Node({this.params, this.store, chain, mempool, network}) {;
    // todo? fees
    // todo? miner
    // todo? rpc
    // todo? seeds
  }

  void start() {
    print("Starting node");
//    Block genesis = params.genesisBlock;

//    store.save(genesis.toBuffer());
//    store.getBlockByHash(genesis.hash);
  }

  void stop() {

  }

  void sync() {
    
  }
}


class Network {
  bool discovering = false;
  PeerList peers;
  HostList hosts;
  List<String> seeds = [
    "google.com",
    "main.network.paycoin.com" // TODO config
  ];

  Network() {
    peers = new PeerList();
    hosts = new HostList();
  }

  void discover() {
    if (discovering)
      return;

    // TODO bip150
    if (peers.length < 5) { // TODO max outbound

    }

    try {
      discovering = true;
//      discoverSeeds();
//      gateway();
    } finally {
      discovering = false;
    }
  }

  void gateway() async {
    for (NetworkInterface iface in await NetworkInterface.list()) {
      print("${iface.name}:");
      for (InternetAddress address in iface.addresses) {
        print("  - ${address.address}");
      }
    }

    var disc = new DeviceDiscoverer();
//    disc.quickDiscoverClients().listen((client) async {
//      try {
//        var dev = await client.getDevice();
//        print("${dev.friendlyName}: ${dev.url}");
//      } catch (e, stack) {
//        print("ERROR: ${e} - ${client.location}");
//        print(stack);
//      }
//    });


    disc.discoverDevices().then((devices) {
      devices.forEach((device) async {
        try {
          var dev = await device.getRealDevice();
          print("${dev.friendlyName}: ${dev.url};");
        } catch (e, stack) {
          print("ERROR: ${e} - ${device.uuid}");
          print(stack);
        }
      });
    });
  }

  void discoverSeeds() {
    for (String seed in this.seeds) {
      InternetAddress.lookup(seed).then((addresses) {
        addresses.forEach((address) {
          // TODO if isroutable
          // TODO if not onion
          // TODO ipv4/6
          print("Peer found ${address.address}");
          this.peers.add(new Peer.fromInternetAddress(address));
        });
      }).catchError((err) {
        print("Not connected to peer ${err}");
      });
    }
  }
}

class Peer extends Object with Events {
  PeerAddress address;
  ConnectionStatus _state = ConnectionStatus.queued;

  ConnectionStatus get state => _state;

  Peer();

  set state(ConnectionStatus state) {
    print("Changing state from ${this.state} to ${state}");
    // Emit events
    this.emit(ConnectionStateEvent(state));

    this._state = state;
  }

  Peer.fromInternetAddress(InternetAddress address) {
    this.address = new PeerAddress(address.address);
  }
}

class PeerList extends ObservableList<Peer> {

  @override
  void add(Peer value) {
    value.on(ConnectionStateEvent).listen((e) {
      print("Event received: ${e} on ${this}");
    });

    return super.add(value);
  }

  @override
  bool remove(Object element) {
    return super.remove(element);
  }

  Iterable<Peer> get connected => byConnectionState(ConnectionStatus.connected);
  Iterable<Peer> get queued => byConnectionState(ConnectionStatus.queued);
  Iterable<Peer> get disconnected => byConnectionState(ConnectionStatus.disconnected);

  Iterable<Peer> byConnectionState(ConnectionStatus state) => this.where((p) {
    return p.state == state;
  });
}

class Host {

}

class HostList extends ObservableList<Host> {

}

class ConnectionStateEvent{
  ConnectionStatus state;

  ConnectionStateEvent(ConnectionStatus state);

  ConnectionStateEvent.connected() : this(ConnectionStatus.connected);
  ConnectionStateEvent.queued() : this(ConnectionStatus.queued);
  ConnectionStateEvent.disconnected() : this(ConnectionStatus.disconnected);
}

enum ConnectionStatus {
  connected,
  disconnected,
  queued
}


class Sqllite implements Datastore {
  Database db;

  void init() {
    print("Initializing datastore");
    db = new Database.inMemory();
  }


  Future<bool> save(GeneratedMessage message) async {
    BuilderInfo entityInfo = message.info_;

    bool exists = await entityExists(entityInfo);
    if (!exists) {
      print("Entity `${entityInfo.messageName}` does not exists yet, creating");
      this.entityCreate(entityInfo); // TODO errors
    } else {
      print("Enitity `${entityInfo.messageName}` exists");
    }

    // wegschrijven
//    bool dataExists = this.dataExists(message);
//    if (dataExists) {
//
//    } else {
//
//    }
  }


  Future<bool> entityExists(BuilderInfo info) async {
    String name = info.messageName;

    // Check if exists
    Stream<Row> result = db.query('SELECT NULL FROM sqlite_master WHERE type="table" AND tbl_name=? LIMIT 1', params: [name]);

    return await result.length > 0;
  }


  void entityCreate(BuilderInfo info) {
    String name = info.messageName;

      Map<int, FieldInfo> fields = info.fieldInfo;

//      print('# ${name}');
      fields.forEach((key, info) async {
//        print('${info.index.toString()} ${info.name} (${info.type.toString()})');
//        print('Repeated: ${info.isRepeated}');
//        print('Required: ${info.isRequired}');
//        print('Enum: ${info.isEnum}');
//        print('Message: ${info.isGroupOrMessage}');
        if (info.isGroupOrMessage) {
          bool exists = await entityExists(info.subBuilder().info_);
          if (!exists) {
            entityCreate(info.subBuilder().info_);
          }
          
          if (info.isRepeated) {
//            for (var value in message.getField(info.tagNumber)) {
//              save(value);
//            }
          } else {
//            save(message.getField(info.tagNumber));
          }
        }
      });

//    throw new Exception('Could not create entity')
  }

  Block getBlockByHash(hash) {
    return new Block.empty();
  }

  Block getBlockByHeight(int height) {
    return new Block.empty();
  }

}

abstract class Datastore {
  void init();
  Future<bool> save(GeneratedMessage message);
  Future<bool> entityExists(BuilderInfo info);
  Block getBlockByHash(Hash256 hash);
  Block getBlockByHeight(int height);
}
