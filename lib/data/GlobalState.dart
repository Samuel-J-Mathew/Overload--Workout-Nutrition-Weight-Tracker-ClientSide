class GlobalState {
  static final GlobalState _instance = GlobalState._internal();
  factory GlobalState() => _instance;

  String averageCals = "0";

  GlobalState._internal();
}
