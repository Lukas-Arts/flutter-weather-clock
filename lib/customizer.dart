// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';

import 'model.dart';

/// Returns a clock [Widget] with [ClockModel].
///
/// Example:
///   final myClockBuilder = (ClockModel model) => AnalogClock(model);
///   
typedef Widget ClockBuilder(ClockModel model);

/// Wrapper for clock widget to allow for customizations.
///
/// Puts the clock in landscape orientation with an aspect ratio of 5:3.
/// Provides a drawer where users can customize the data that is sent to the
/// clock. To show/hide the drawer, double-tap the clock.
///
/// To use the [ClockCustomizer], pass your clock into it, using a ClockBuilder.
///
/// ```
///   final myClockBuilder = (ClockModel model) => AnalogClock(model);
///   return ClockCustomizer(myClockBuilder);
/// ```
/// Contestants: Do not edit this.
class ClockCustomizer extends StatefulWidget {
  const ClockCustomizer(this._clock);

  /// The clock widget with [ClockModel], to update and display.
  final ClockBuilder _clock;

  @override
  _ClockCustomizerState createState() => _ClockCustomizerState();
}

class _ClockCustomizerState extends State<ClockCustomizer> with WidgetsBindingObserver{
  final _model = ClockModel();
  bool _configButtonShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    load();
    _model.addListener(_handleModelChange);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _model.removeListener(_handleModelChange);
    _model.dispose();
    super.dispose();
  }

  Future<void> load() async {
    print("loading prefs...");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _model.timeModifier=prefs.getDouble("timeModifier")??0.0;
      _model.showSeconds=prefs.getBool("showSeconds")??false;
      _model.is24HourFormat=prefs.getBool("is24HourFormat")??true;
      _model.unit=TemperatureUnit.values.elementAt(prefs.getInt("unit").toInt()??1);
    });
  }
  Future<void> save() async {
    print("saving prefs...");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setDouble("timeModifier",_model.timeModifier);
    prefs.setBool("showSeconds",_model.showSeconds);
    prefs.setBool("is24HourFormat",_model.is24HourFormat);
    prefs.setInt("unit",TemperatureUnit.values.indexOf(_model.unit));
  }
  void _handleModelChange() {
    setState(() {});
  }

  Widget _enumMenu<T>(
      String label, T value, List<T> items, ValueChanged<T> onChanged) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          onChanged: onChanged,
          items: items.map((T item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(enumToString(item)),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _switch(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: <Widget>[
        Expanded(child: Text(label)),
        Switch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _textField(
      String currentValue, String label, ValueChanged<Null> onChanged) {
    return TextField(
      decoration: InputDecoration(
        hintText: currentValue,
        helperText: label,
      ),
      onChanged: onChanged,
    );
  }
  AppLifecycleState _notification;
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print(state.toString());
    if(state == AppLifecycleState.paused) {
      print("saving...");
      save();
    }
    setState(() { _notification = state; });

  }
  Widget _configDrawer(BuildContext context) {
    return SafeArea(
      child: Drawer(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                _switch('24-Hour Format:', _model.is24HourFormat, (bool value) {
                  setState(() {
                    _model.is24HourFormat = value;
                  });
                }),
                _switch('Show Seconds:', _model.showSeconds, (bool value) {
                  setState(() {
                    _model.showSeconds = value;
                  });
                }),
                Row(
                  children: <Widget>[
                    Text("Timeshift: "+_model.timeModifier.toString()+"h",textAlign: TextAlign.start),
                    Expanded(
                      child: Slider(
                        activeColor: Colors.blueAccent,
                        value: _model.timeModifier,
                        onChanged: (double d)=>{
                          setState(() {
                            _model.timeModifier=d;
                          })
                        },
                        min:-12.0,
                        max:12.0,
                        divisions:24,
                      ),
                    )
                  ],
                ),
                _enumMenu(
                    'Weather', _model.weatherCondition, WeatherCondition.values,
                    (WeatherCondition condition) {
                  setState(() {
                    _model.weatherCondition = condition;
                  });
                }),
                _enumMenu('Units', _model.unit, TemperatureUnit.values,
                    (TemperatureUnit unit) {
                  setState(() {
                    _model.unit = unit;
                  });
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _configButton() {
    return Builder(
      builder: (BuildContext context) {
        return IconButton(
          icon: Icon(Icons.settings),
          tooltip: 'Configure clock',
          onPressed: () {
            final scaf=Scaffold.of(context);
            scaf.openEndDrawer();
            setState(() {
              _configButtonShown = false;
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final clock = widget._clock(_model);
    final now=DateTime.now().add(Duration(hours: 1)* _model.timeModifier);
    final hour24 =int.parse(DateFormat('HH').format(now));
    final hour12 =int.parse(DateFormat('hh').format(now));
    final int cval=(lerpDouble((hour24<12?0:255),(hour24<12?255:0),hour24%12/12)).toInt();
    final bg_color=Color.fromARGB(255,cval,cval,cval);
    print(bg_color.toString()+" "+cval.toString()+" "+(hour12/12).toString()+" "+hour24.toString()+"/"+hour12.toString());
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: bg_color,
        resizeToAvoidBottomPadding: false,
        endDrawer: _configDrawer(context),
        body: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              setState(() {
                _configButtonShown = !_configButtonShown;
              });
            },
            child: Stack(
              children: [
                clock,
                if (_configButtonShown)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Opacity(
                      opacity: 0.7,
                      child: _configButton(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
