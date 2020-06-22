import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'model.dart';

class ClockWidget extends StatefulWidget {
  const ClockWidget(this.model,this.nextAlert);

  final ClockModel model;
  final String nextAlert;
  @override
  _ClockWidgetState createState() => _ClockWidgetState();
}

class _ClockWidgetState extends State<ClockWidget> {
  DateTime _dateTime = DateTime.now();
  Timer _timer;

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_updateModel);
    _updateModel();
    _updateTime();
  }
  @override
  void didUpdateWidget(ClockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.model != oldWidget.model) {
      oldWidget.model.removeListener(_updateModel);
      widget.model.addListener(_updateModel);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.model.removeListener(_updateModel);
    widget.model.dispose();
    super.dispose();
  }

  void _updateModel() {
    setState(() {
      // Cause the clock to rebuild when the model changes.
    });
  }

  void _updateTime() {
    setState(() {
      _dateTime = DateTime.now().add(Duration(hours: 1)*widget.model.timeModifier);
      // Update once per minute. If you want to update every second, use the
      // following code.
      //_timer = Timer(
      //Duration(minutes: 1) -
      //Duration(seconds: _dateTime.second) -
      // Duration(milliseconds: _dateTime.millisecond),
      //  _updateTime,
      //);
      // Update once per second, but make sure to do it at the beginning of each
      // new second, so that the clock is accurate.
      _timer = Timer(
        Duration(seconds: 1) - Duration(milliseconds: _dateTime.millisecond),
        _updateTime,
      );
    });
  }
  @override
  Widget build(BuildContext context) {
    final dateString=DateFormat("EEEE, dd. MMMM").format(_dateTime);
    final hour =DateFormat(widget.model.is24HourFormat ? 'HH' : 'hh').format(_dateTime);
    final minute = DateFormat('mm').format(_dateTime);
    final second = DateFormat('ss').format(_dateTime);
    final clockFontSize = MediaQuery.of(context).size.width / 5;
    final clockDotsFontSize = MediaQuery.of(context).size.width / 10;
    final infoFontSize = MediaQuery.of(context).size.width / 28;
    final offset = -clockFontSize / 7;
    final clockStyle = TextStyle(
      color: Colors.white,
      fontFamily: 'larabiefont',
      fontSize: clockFontSize,
      shadows: [
        Shadow(
          blurRadius: 5,
          color: Colors.black,
          offset: Offset(0, 0),
        ),
      ],
    );
    final clockDotsStyle = TextStyle(
      color: Colors.white,
      fontFamily: 'larabiefont',
      fontSize: clockDotsFontSize,
      shadows: [
        Shadow(
          blurRadius: 5,
          color: Colors.black,
          offset: Offset(0, 0),
        ),
      ],
    );

    final infoStyle = TextStyle(
      color: Colors.white,
      //fontFamily: 'UbuntuMono',
      fontSize: infoFontSize,
      shadows: [
        Shadow(
          blurRadius: 2,
          color: Colors.black,
          offset: Offset(0, 0),
        ),
      ],
    );
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(top: 15.0),
            child: DefaultTextStyle(
              style: clockStyle,
              child:Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(hour),
                  Padding(
                    padding: EdgeInsets.only(left:0.0,bottom:8.0),
                    child:DefaultTextStyle(
                      style: clockDotsStyle,
                      child:Text(':'),
                    ),
                  ),
                  Text(minute),
                  if(widget.model.showSeconds)
                    Padding(
                      padding: EdgeInsets.only(left:0.0,bottom:8.0),
                      child:DefaultTextStyle(
                        style: clockDotsStyle,
                        child:Text(':'),
                      ),
                    ),
                  if(widget.model.showSeconds)
                    Text(second),
                ],
              ),
            ),
          ),
          Center(
            child:DefaultTextStyle(
                style: infoStyle,
                child: Text(dateString)
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(right: 4.0,bottom: 1.5),
                child:Icon(
                  Icons.alarm,
                  color: Colors.white,
                  size: infoFontSize,
                  semanticLabel: 'Text to announce in accessibility modes',
                ),
              ),
              Center(
                child: DefaultTextStyle(
                    style: infoStyle,
                    child: Text(widget.nextAlert)
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}