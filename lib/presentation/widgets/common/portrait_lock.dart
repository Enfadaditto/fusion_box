import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class PortraitLock extends StatefulWidget {
  final Widget child;

  const PortraitLock({super.key, required this.child});

  @override
  State<PortraitLock> createState() => _PortraitLockState();
}

class _PortraitLockState extends State<PortraitLock> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}


