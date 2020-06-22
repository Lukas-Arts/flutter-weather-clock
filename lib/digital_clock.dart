// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:digital_clock/alert_model.dart';
import 'package:digital_clock/alert_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'clock_widget.dart';
import 'model.dart';
import 'package:weather_icons/weather_icons.dart';
import 'package:wakelock/wakelock.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';


final geolocator = Geolocator();
final locationOptions = LocationOptions(accuracy: LocationAccuracy.low, distanceFilter: 1000);

/// A basic digital clock.
class DigitalClock extends StatefulWidget {
  const DigitalClock(this.model);

  final ClockModel model;
  @override
  _DigitalClockState createState() => _DigitalClockState();
}

class _DigitalClockState extends State<DigitalClock>  with WidgetsBindingObserver{
  final List<AlertModel> alerts=List();
  StreamSubscription<Position> positionStream;
  Position current_position=Position();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    load();
    widget.model.addListener(_updateModel);
    _updateModel();
    positionStream = geolocator.getPositionStream(locationOptions).listen(
            _updatePosition);
    Wakelock.enable();
  }
  @override
  void didUpdateWidget(DigitalClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.model != oldWidget.model) {
      oldWidget.model.removeListener(_updateModel);
      widget.model.addListener(_updateModel);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.model.removeListener(_updateModel);
    widget.model.dispose();
    Wakelock.disable();
    super.dispose();
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
  AlertModel getAlertFromString(String s){
    AlertModel am=AlertModel();
    List<String> s2=s.split("|");
    am.isActive=s2.elementAt(0).toLowerCase()=="true";
    am.time_string=s2.elementAt(1);
    am.isRepeatEnabled=s2.elementAt(2).toLowerCase()=="true";
    am.repetition=int.parse(s2.elementAt(3));
    am.isExpanded=s2.elementAt(4).toLowerCase()=="true";
    am.message=s2.elementAt(5);
    am.sound=s2.elementAt(6);
    print(am.toString());
    return am;
  }
  Future<void> load() async {
    print("loading alerts...");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      this.alerts.clear();
      List<String> alerts=prefs.getStringList("alerts")??List<String>();
      for(String s in alerts){
        this.alerts.add(getAlertFromString(s));
      }
    });
  }
  Future<void> save() async {
    print("saving alerts...");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> list=List<String>();

    //await AndroidAlarmManager.initialize();
    for(AlertModel am in alerts){
      //if(am.isActive)
      //  await AndroidAlarmManager.periodic(const Duration(minutes: 1), 0, printHello);

      list.add(am.toString());
      print(am.toString());
    }
    prefs.setStringList("alerts",list);
  }
  void printHello(){
    print("hello alarm!");
  }
  void _updateModel() {
    setState(() {
      // Cause the clock to rebuild when the model changes.
    });
  }
  void _updatePosition(Position position){
    print(position == null ? 'Unknown' : position.latitude.toString() + ', ' + position.longitude.toString());
    current_position=position;
    _updateWeather(position);
  }
  void _updateWeather(Position position)async{

    String url='http://api.openweathermap.org/data/2.5/weather?lat='+position.latitude.toString()+'&lon='+position.longitude.toString()+'&units=metric&appid=2cbf40a066645b812adb0ed2208c983c';

    print(url);
    final response = await http.get(url);

    if (response.statusCode == 200) {
      // If server returns an OK response, parse the JSON.
      Map<String, dynamic> json=jsonDecode(response.body);
      widget.model.temperature=json["main"]["temp"];
      print(widget.model.temperature.toString()+"°C");
      widget.model.weatherIcon=json["weather"][0]["icon"];
      print("icon:"+widget.model.weatherIcon);
      widget.model.windSpeed=(json["wind"]["speed"]);
      widget.model.windDir=(json["wind"]["deg"]);
      DateFormat df=DateFormat("HH:mm");
      //print((json["sys"]["surise"]).toString()+" "+(json["sys"]["surise"]).toString())
      widget.model.sunrise=df.format(DateTime.fromMillisecondsSinceEpoch((json["sys"]["sunrise"])*1000));
      widget.model.sunset=df.format(DateTime.fromMillisecondsSinceEpoch((json["sys"]["sunset"])*1000));

      print("wind:"+widget.model.windSpeed.toString()+"km/h "+widget.model.windDir.toString()+"°");
    } else {
      // If that response was not OK, throw an error.
      throw Exception('Failed to load Weather info');
    }

  }
  double parseDouble(num val){
    String s;
    if(val==null)
      s="0.0";
    else s=val.toString();
    if(!s.contains("."))
      s+".0";
    return double.parse(s);
  }
  Widget WeatherWidget(){
    final iconSize = MediaQuery.of(context).size.width / 8;
    final tempFontSize = MediaQuery.of(context).size.width / 18;
    final windFontSize = MediaQuery.of(context).size.width / 28;
    final sunSize = MediaQuery.of(context).size.width / 28;
    final sunStyle = TextStyle(
      color: Colors.white,
      //fontFamily: 'larabiefont',
      fontSize: sunSize,
      shadows: [
        Shadow(
          blurRadius: 3,
          color: Colors.black,
          offset: Offset(0, 0),
        ),
      ],
    );
    final tempStyle = TextStyle(
      color: Colors.white,
      //fontFamily: 'larabiefont',
      fontSize: tempFontSize,
      shadows: [
        Shadow(
          blurRadius: 3,
          color: Colors.black,
          offset: Offset(0, 0),
        ),
      ],
    );
    final windStyle = TextStyle(
      color: Colors.white,
      //fontFamily: 'larabiefont',
      fontSize: windFontSize,
      shadows: [
        Shadow(
          blurRadius: 3,
          color: Colors.black,
          offset: Offset(0, 0),
        ),
      ],
    );
    return Container(
      //color: Colors.black,
      child: DefaultTextStyle(
        style: tempStyle,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Column(
              children: <Widget>[
                Image(image: AssetImage("third_party/weather-underground-icons/sunrise.png"),width:sunSize*1.5,height:sunSize*1.5),
                Padding(
                  padding: EdgeInsets.only(bottom: sunSize*0.3),
                  child: Text(widget.model.sunrise,style: sunStyle,),
                )
              ],
            ),
            Padding(
              padding:EdgeInsets.only(right:10.0),
              child:Image(image: AssetImage('third_party/weather-underground-icons/'+widget.model.weatherIcon+".png"),width:iconSize*1.4,height:iconSize*1.4),
            ),
            Center(
                child: Text(widget.model.temperatureString)
            ),
            WindIcon(degree: parseDouble(widget.model.windDir),size: iconSize,color:Colors.white),
            Padding(
              padding: EdgeInsets.only(right: windFontSize*0.75),
              child: DefaultTextStyle(
                style: windStyle,
                child: Column(
                  children: <Widget>[
                    Text(widget.model.windDir.toString()+"°"),
                    Text(widget.model.windSpeed.toString()+" m/sec"),
                  ],
                ),
              ),
            ),
            Column(
              children: <Widget>[
                Image(image: AssetImage("third_party/weather-underground-icons/sunset.png"),width:sunSize*1.5,height:sunSize*1.5),
                Padding(
                  padding: EdgeInsets.only(bottom: sunSize*0.3),
                  child: Text(widget.model.sunset,style: sunStyle),
                )
              ],
            ),
          ],
        ),
      )
    );
  }
  Widget AlarmsWidget(){
    return Container(
      child: Column(
        children: <Widget>[
          for(AlertModel am in alerts)
            AlertWidget(am)
        ],
      ),
    );
  }
  String getNextAlert() {
    setState(() {
      alerts.sort((a,b){
        if(!a.isActive)return 1;
        if(!b.isActive)return -1;
        return a.time_string.toString().compareTo(b.time_string.toString());
      });
    });
    if(alerts.length!=0)
      return alerts.elementAt(0).time_string;
    else return "";

  }
  @override
  Widget build(BuildContext context) {
    Size size=MediaQuery.of(context).size;
    print(size.width.toString()+" "+size.height.toString()+" "+min(size.width,200.0).toString());
    final double h=(size.width>size.height?size.height:min(size.width,240.0));
    final sunSize = MediaQuery.of(context).size.width / 48;
    final sunStyle = TextStyle(
      color: Colors.white,
      fontFamily: 'larabiefont',
      fontSize: sunSize,
      shadows: [
        Shadow(
          blurRadius: 3,
          color: Colors.black,
          offset: Offset(0, 0),
        ),
      ],
    );
    return Stack(
      children: <Widget>[
        ListView(
          children:<Widget>[
            Container(
              height:h,
              child:Padding(
                padding: EdgeInsets.all(10.0),
                child: Column(
                  children: <Widget>[
                    Expanded(
                      child: ClockWidget(widget.model,getNextAlert()),
                    ),
                    WeatherWidget(),
                  ],
                ),
              ),
            ),
            AlarmsWidget(),
            Container(
              height: 100.0,
            )
          ],
        ),
        Positioned(
          bottom: 25.0,
          right: 25.0,
          child: FloatingActionButton(
            onPressed: (){
              setState(() {
                alerts.add(AlertModel());
              });
            },
            child: Text("+"),
          ),
        )
      ],
    );
  }
}
