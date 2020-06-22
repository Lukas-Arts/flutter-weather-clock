

import 'package:digital_clock/alert_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AlertWidget extends StatefulWidget {
  const AlertWidget(this.model);

  final AlertModel model;
  @override
  _AlertWidgetState createState() => _AlertWidgetState();
}

class _AlertWidgetState extends State<AlertWidget> {

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_updateModel);
    _updateModel();
  }
  @override
  void didUpdateWidget(AlertWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.model != oldWidget.model) {
      oldWidget.model.removeListener(_updateModel);
      widget.model.addListener(_updateModel);
    }
  }

  @override
  void dispose() {
    widget.model.removeListener(_updateModel);
    widget.model.dispose();
    super.dispose();
  }

  void _updateModel() {
    setState(() {
      // Cause the clock to rebuild when the model changes.
    });
  }

  String fillZeros(num x){
    return x>9?x.toString():"0"+x.toString();
  }
  Widget getDay(text,textStyle,val){
    return Padding(
      padding: EdgeInsets.all(4.0),
      child: FloatingActionButton(
        backgroundColor: (widget.model.repetition&val)>0 ? Colors.blue[800]:Colors.blueGrey[800],
        elevation: 1,
        child:Text(text,style: textStyle),
        onPressed: (){
          setState(() {
            if((widget.model.repetition&val)>0)
              widget.model.repetition&=(127-val);
            else widget.model.repetition|=val;
          });
        },
      ),
    );
  }
  String getRepString(){
    if(widget.model.repetition==127)
      return "Daily";
    else if(widget.model.repetition==0)
      return "Once";
    else return getRecRepString("", "", 1);
  }
  String getRecRepString(String last,String rep_string,int current){
    //print(current.toString()+" "+rep_string);
    if(widget.model.repetition&current>0){
      rep_string+=getDayName(current)+" ";
      last=getDayName(current);
    }
    if(current<64){
      current=current<<1;
      return getRecRepString(last, rep_string, current);
    }else return rep_string;

  }
  String getDayName(int i){
    if(i==1)
      return "Mo";
    if(i==2)
      return "Di";
    if(i==4)
      return "Mi";
    if(i==8)
      return "Do";
    if(i==16)
      return "Fr";
    if(i==32)
      return "Sa";
    if(i==64)
      return "So";
  }
  @override
  Widget build(BuildContext context) {
    final alarmTimeSize = MediaQuery.of(context).size.width / 16;
    final alarmRepSize = MediaQuery.of(context).size.width / 28;
    final timeStyle = TextStyle(
      color: Colors.white,
      fontFamily: 'larabiefont',
      fontSize: alarmTimeSize,
      shadows: [
        Shadow(
          blurRadius: 3,
          color: Colors.black,
          offset: Offset(0, 0),
        ),
      ],
    );
    final repStyle = TextStyle(
      color: Colors.white,
      fontFamily: 'larabiefont',
      fontSize: alarmRepSize,
      shadows: [
        Shadow(
          blurRadius: 3,
          color: Colors.black,
          offset: Offset(0, 0),
        ),
      ],
    );
    return FlatButton(
      padding: EdgeInsets.all(0.0),
      splashColor: Color.fromARGB(128, 128, 128, 128),
      onPressed: () {
        setState(() {
          widget.model.isExpanded=!widget.model.isExpanded;
        });
        print("hello world");
      },
      child: Column(
        children: <Widget>[
          Divider(color: Colors.white,height: 10.0,),
          IntrinsicHeight(
            child: Row(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(left:10.0,right:15.0,top:5.0,bottom:5.0),
                  child: FloatingActionButton(
                      backgroundColor: widget.model.isActive?Colors.blue[800]:Colors.blueGrey[800],
                      elevation: 0,
                      onPressed: () {
                        setState(() {
                          if(widget.model.isActive)
                            widget.model.isActive=false;
                          else widget.model.isActive=true;
                          print("is alert active: "+widget.model.isActive.toString());
                        });
                      },
                      child: Icon(
                        Icons.notifications_active,
                        color: Colors.white,
                        size: 28,
                        semanticLabel: 'Enable/Disable Alarm',
                      )
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      RawMaterialButton(
                        constraints: BoxConstraints(),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.all(0.0),
                        child: Text(widget.model.time_string,style: timeStyle,),
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(DateFormat("HH:mm").parse(widget.model.time_string) ?? DateTime.now()),
                          );
                          setState(() {
                            widget.model.time_string=fillZeros(time.hour)+":"+fillZeros(time.minute);
                          });
                          print(time.toString());
                        },
                      ),
                      if(!widget.model.isExpanded)
                        Padding(
                          padding: EdgeInsets.only(left: 2.0),
                          child: Text(getRepString().toString(),style: repStyle),
                        )
                    ],
                  ),
                ),
                Expanded(
                    child: Stack(
                      children: <Widget>[
                        Positioned(
                            top:0,
                            right: 10,
                            child: Icon(widget.model.isExpanded?Icons.keyboard_arrow_up:Icons.keyboard_arrow_down,color: Colors.white,size:32)
                        ),
                      ],
                    )
                ),
              ],
            ),
          ),
          if(widget.model.isExpanded)Padding(
            padding: EdgeInsets.only(left: 18.0, right: 18.0),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Checkbox(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: (val){
                        setState(() {
                          widget.model.isRepeatEnabled=!widget.model.isRepeatEnabled;
                        });
                      },
                      value: widget.model.isRepeatEnabled,
                    ),
                    Text("Repeat",style: repStyle,),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          RaisedButton(
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              elevation: 1,
                              color: Colors.red[800],
                              padding: EdgeInsets.all(0.0),
                              splashColor: Color.fromARGB(128, 128, 128, 128),
                              onPressed: () {
                                //widget.deleteAlarm();
                                print("deleteAlarm");
                              },
                              child:Row(
                                children: <Widget>[
                                  Icon(
                                    Icons.delete,
                                    color:Colors.white,
                                    size: 24,
                                  ),
                                  Text("Delete",style: repStyle,),
                                ],
                              )
                          )
                        ],
                      ),
                    )
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: getDay("Mo",repStyle,1),
                    ),
                    Expanded(
                      child: getDay("Di",repStyle,2),
                    ),
                    Expanded(
                      child: getDay("Mi",repStyle,4),
                    ),
                    Expanded(
                      child: getDay("Do",repStyle,8),
                    ),
                    Expanded(
                      child: getDay("Fr",repStyle,16),
                    ),
                    Expanded(
                      child: getDay("Sa",repStyle,32),
                    ),
                    Expanded(
                      child: getDay("So",repStyle,64),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      )
    );
  }
}