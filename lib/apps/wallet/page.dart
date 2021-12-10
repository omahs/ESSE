import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:esse/utils/adaptive.dart';
import 'package:esse/utils/better_print.dart';
import 'package:esse/l10n/localizations.dart';
import 'package:esse/widgets/button_text.dart';
import 'package:esse/widgets/input_text.dart';
import 'package:esse/widgets/default_core_show.dart';
import 'package:esse/global.dart';
import 'package:esse/options.dart';
import 'package:esse/rpc.dart';

import 'package:esse/apps/wallet/models.dart';

class WalletDetail extends StatefulWidget {
  const WalletDetail({Key? key}) : super(key: key);

  @override
  _WalletDetailState createState() => _WalletDetailState();
}

class _WalletDetailState extends State<WalletDetail> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  bool _needGenerate = false;

  List<Address> _addresses = [];
  Address? _selectedAddress;

  List<Network> _networks = [];
  Network? _selectedNetwork;

  Token _mainToken = Token();
  List<Token> _tokens = [];

  List tokens = [
    ['ETH', '2000', '2000', 'assets/logo/logo_eth.png'],
    ['USDT', '2000', '2000', 'assets/logo/logo_tether.png'],
    ['XXX', '100', '1000', 'assets/logo/logo_erc20.png'],
    ['wBTC', '100', '1000', 'assets/logo/logo_btc.png'],
  ];

  @override
  void initState() {
    _tabController = new TabController(length: 2, vsync: this);
    rpc.addListener('wallet-generate', _walletGenerate, false);
    rpc.addListener('wallet-balance', _walletBalance, false);
    super.initState();
    Future.delayed(Duration.zero, _load);
  }

  _walletGenerate(List params) {
    final address = Address.fromList(params);
    bool isNew = true;
    this._addresses.forEach((addr) {
        if (addr.address == address.address) {
          isNew = false;
        }
    });
    if (isNew) {
      this._addresses.add(address);
      _changeAddress(address);
      setState(() {});
    }
  }

  _walletBalance(List params) {
    final address = params[0];
    final network = NetworkExtension.fromInt(params[1]);
    if (address == this._selectedAddress!.address && network == this._selectedNetwork!) {
      final contract = params[2];
      final balance = params[3];

      // TODO check token.

      this._mainToken = Token.eth(network);
      this._mainToken.balance(balance);
      setState(() {});
    }
  }

  _load() async {
    final res = await httpPost(Global.httpRpc, 'wallet-list', []);
    if (res.isOk) {
      this._addresses.clear();
      res.params.forEach((param) {
          print(param);
          this._addresses.add(Address.fromList(param));
      });
      if (this._addresses.length == 0) {
        this._needGenerate = true;
      }
      setState(() {});
    } else {
      // TODO tostor error
      print(res.error);
    }
  }

  _changeAddress(Address address) {
    this._selectedAddress = address;
    this._networks = address.networks();
    if (!this._networks.contains(this._selectedNetwork)) {
      _changeNetwork(this._networks[0]);
    } else {
      rpc.send('wallet-balance', [
          this._selectedNetwork!.toInt(), this._selectedAddress!.address
      ]);
    }
  }

  _changeNetwork(Network network) {
    this._selectedNetwork = network;
    rpc.send('wallet-balance', [
        this._selectedNetwork!.toInt(), this._selectedAddress!.address
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final lang = AppLocalizations.of(context);

    if (this._addresses.length == 0 && !this._needGenerate) {
      return Scaffold(
        appBar: AppBar(title: Text(lang.loadMore)),
        body: const DefaultCoreShow(),
      );
    }

    if (this._addresses.length == 0 && this._needGenerate) {
      return Scaffold(
        appBar: AppBar(title: Text(lang.wallet)),
        body: DefaultCoreShow(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(onPrimary: color.surface),
            onPressed: () {
              rpc.send('wallet-generate', [ChainToken.ETH.toInt(), ""]);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock),
                  const SizedBox(width: 8.0),
                  const Text('生成以太坊地址'),
                ]
              )
            )
        ))
      );
    }

    if (this._selectedAddress == null) {
      _changeAddress(this._addresses[0]);
    }

    List<PopupMenuEntry<int>> addressWidges = [];
    this._addresses.asMap().forEach((index, value) {
        addressWidges.add(_menuItem(index + 3, value, color, value == this._selectedAddress));
    });

    return Scaffold(
      appBar: AppBar(
        title: DropdownButton<Network>(
          icon: Container(),
          underline: Container(),
          value: this._selectedNetwork,
          onChanged: (Network? value) {
            if (value != null) {
              setState(() {
                  _changeNetwork(value);
              });
            }
          },
          items: this._networks.map((Network network) {
              final params = network.params();
              return  DropdownMenuItem<Network>(
                value: network,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                  decoration:  BoxDecoration(
                    border: Border.all(width: 1.0, color: params[1]),
                    borderRadius: BorderRadius.circular(25.0)
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.public, color: params[1], size: 18.0),
                      const SizedBox(width: 10),
                      Text(params[0], style: TextStyle(color: params[1], fontSize: 14.0)),
                    ],
                )),
              );
          }).toList(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: PopupMenuButton<int>(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                width: 40.0,
                decoration:  BoxDecoration(
                  color: color.surface,
                  borderRadius: BorderRadius.circular(25.0)
                ),
                child: Center(child: Text(this._selectedAddress!.icon()))
              ),
              onSelected: (int value) {
                if (value == 0) {
                  rpc.send('wallet-generate', [this._selectedAddress!.chain.toInt(), ""]);
                } else if (value == 1) {
                  //
                } else if (value == 2) {
                  //
                } else {
                  setState(() {
                      _changeAddress(this._addresses[value - 3]);
                  });
                }
              },
              itemBuilder: (context) {
                return addressWidges + <PopupMenuEntry<int>>[
                  PopupMenuItem<int>(
                    value: 0,
                    child: ListTile(
                      leading: Icon(Icons.add, color: const Color(0xFF6174FF)),
                      title: Text(lang.createAccount,
                        style: TextStyle(color: const Color(0xFF6174FF))),
                    ),
                  ),
                  PopupMenuItem<int>(
                    value: 1,
                    child: ListTile(
                      leading: Icon(Icons.vertical_align_bottom, color: const Color(0xFF6174FF)),
                      title: Text(lang.importAccount,
                        style: TextStyle(color: const Color(0xFF6174FF))),
                    ),
                  ),
                  PopupMenuItem<int>(
                    value: 2,
                    child: ListTile(
                      leading: Icon(Icons.settings, color: const Color(0xFF6174FF)),
                      title: Text(lang.setting,
                        style: TextStyle(color: const Color(0xFF6174FF))),
                    ),
                  )
                ];
              },
            ),
          )
        ]
      ),
      body: Container(
        alignment: Alignment.topCenter,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children:[
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: this._selectedAddress!.address));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                alignment: Alignment.center,
                decoration: new BoxDecoration(
                  border: new Border(bottom:
                    const BorderSide(width: 1.0, color: Color(0xA0ADB0BB)))),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(this._selectedAddress!.name, style: TextStyle(fontSize: 18.0)),
                    const SizedBox(height: 4.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(this._selectedAddress!.short(),
                          style: TextStyle(color: Color(0xFFADB0BB))),
                        const SizedBox(width: 8.0),
                        Icon(Icons.copy, size: 16.0, color: color.primary),
                      ]
                    )
                  ]
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 36.0,
                    height: 36.0,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(this._mainToken.logo),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Container(
                    height: 60.0,
                    alignment: Alignment.center,
                    child: Text(
                      "${this._mainToken.amount} ${this._mainToken.name}",
                      style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold)),
                  ),
                  Text('\$1000', style: TextStyle(color: Color(0xFFADB0BB))),
                  const SizedBox(height: 8.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                          decoration:  BoxDecoration(
                            color: Color(0xFF6174FF),
                            borderRadius: BorderRadius.circular(25.0)
                          ),
                          child: Center(child: Text('Send', style: TextStyle(color: Colors.white)))
                        )
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                          decoration:  BoxDecoration(
                            color: Color(0xFF6174FF),
                            borderRadius: BorderRadius.circular(25.0)
                          ),
                          child: Center(child: Text('Receive', style: TextStyle(color: Colors.white)))
                        )
                      ),
                    ]
                  ),
                ]
              )
            ),
            TabBar(
              unselectedLabelColor: color.onSurface,
              labelColor: Color(0xFF6174FF),
              tabs: [
                Tab(text: 'Assets'),
                Tab(text: 'Activity'),
              ],
              controller: _tabController!,
              indicatorSize: TabBarIndicatorSize.tab,
            ),
            Expanded(
              child: TabBarView(
                children: [
                  ListView.separated(
                    separatorBuilder: (BuildContext context, int index) => const Divider(),
                    itemCount: tokens.length + 1,
                    itemBuilder: (BuildContext context, int index) {
                      if (index == tokens.length) {
                        return TextButton(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            child: Text('Add new Token' + ' ( ERC20 / ERC721 )')
                          ),
                          onPressed: () {
                            //
                          },
                        );
                      } else {
                        return ListTile(
                          leading: Container(
                            width: 36.0,
                            height: 36.0,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage(tokens[index][3]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          title: Text(tokens[index][1] + ' ' + tokens[index][0]),
                          subtitle: Text('\$' + tokens[index][2]),
                          trailing: IconButton(icon: Icon(Icons.arrow_forward_ios),
                            onPressed: () {}),
                        );
                      }
                    }
                  ),
                  ListView.separated(
                    separatorBuilder: (BuildContext context, int index) => const Divider(),
                    itemCount: 10,
                    itemBuilder: (BuildContext context, int index) {
                      return Container(
                        child: Text('TODO ${index}'),
                      );
                    }
                  ),
                ],
                controller: _tabController!,
              ),
            ),
          ]
        )
      ),
    );
  }

  PopupMenuEntry<int> _menuItem(int value, Address address, ColorScheme color, bool selected) {
    return PopupMenuItem<int>(
      value: value,
      child: ListTile(
        leading: Icon(Icons.check, color: selected ? color.onSurface : Colors.transparent),
        title: Text(address.name),
        subtitle: Text(address.balance(this._selectedNetwork!) + ' ' + address.chain.symbol),
      ),
    );
  }
}
