part of just_motion;

mixin MotionDelay {
  Timer? _delay;

  bool get isDelayed => _delay?.isActive ?? false;

  void cancelDelay() {
    _delay?.cancel();
    _delay = null;
  }

  void delay(double seconds) {
    cancelDelay();
    _delay = Timer(
      Duration(milliseconds: (seconds * 1000).round()),
      onDelayComplete,
    );
  }

  void onDelayComplete() {
    cancelDelay();
  }

  void dispose() {
    cancelDelay();
  }
}

enum MotionState { idle, target, start, deactivate, delayComplete, moving }

abstract class MotionValue<T> with ChangeNotifier, MotionDelay {
  /// used by `Motion` and `MotionBuilder` for the reactive state.
  static _MotionNotifier? proxyNotifier;

  ChangeNotifier? _statusListener;

  @override
  String toString() {
    return '$value / $target';
  }

  void removeStatusListener(VoidCallback listener) {
    _statusListener?.removeListener(listener);
  }

  void addStatusListener(VoidCallback listener) {
    _statusListener ??= ChangeNotifier();
    _statusListener!.addListener(listener);
  }

  late MotionState _state = MotionState.idle;
  MotionState get state => _state;
  void _setState(MotionState val) {
    if (_state == val) return;
    _state = val;
    _statusListener?.notifyListeners();
  }

  late T target, value;

  MotionValue(this.value) : target = value;

  bool get completed => target == value;

  /// time delation factor.
  double get _dt => 1 / timeDilation;

  void tick(Duration t);

  @override
  void delay(double seconds) {
    if (!completed) _deactivate();
    super.delay(seconds);
  }

  @override
  void onDelayComplete() {
    super.onDelayComplete();
    _setState(MotionState.delayComplete);
    if (!completed) {
      _activate();
    }
  }

  @override
  void dispose() {
    cancelDelay();
    _deactivate();
    _statusListener?.dispose();
    target = value;
    if (MotionValue.proxyNotifier != null) {
      MotionValue.proxyNotifier!.remove(this);
    }
    super.dispose();
  }

  void _activate() {
    if (!completed && !isDelayed) {
      _setState(MotionState.start);
      TickerMan.instance.activate(this);
    }
  }

  void _deactivate() {
    _setState(MotionState.deactivate);
    TickerMan.instance.remove(this);
  }

  void set(T val) {
    this.value = this.target = val;
  }

  T call([T? v]) {
    if (v != null) {
      this.target = v;
    }
    return value;
  }

  T to(T target, {double? delay}) {
    this.target = target;
    if (delay != null) {
      this.delay(delay);
    }
    return this.value;
  }

  void _widgetDeactivate() {
    if (!hasListeners) {
      dispose();
    }
  }
}