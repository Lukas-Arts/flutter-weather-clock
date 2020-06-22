import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class AlertModel extends ChangeNotifier{
  get isActive => _isActive;
  bool _isActive = true;
  set isActive(bool isActive) {
    if (_isActive != isActive) {
      _isActive = isActive;
      notifyListeners();
    }
  }
  get time_string => _time_string;
  // Stored in degrees celsius, and converted based on the current unit setting
  String _time_string = "00:00";
  set time_string(String time_string) {
    if (time_string != _time_string) {
      _time_string = time_string;
      notifyListeners();
    }
  }

  get isExpanded => _isExpanded;
  bool _isExpanded=false;
  set isExpanded(bool isExpanded) {
    if (_isExpanded != isExpanded) {
      _isExpanded = isExpanded;
      notifyListeners();
    }
  }
  get isRepeatEnabled => _isRepeatEnabled;
  bool _isRepeatEnabled=false;
  set isRepeatEnabled(bool isRepeatEnabled) {
    if (_isRepeatEnabled != isRepeatEnabled) {
      _isRepeatEnabled = isRepeatEnabled;
      notifyListeners();
    }
  }

  get repetition => _repetition;
  int _repetition=0;
  set repetition(int repetition) {
    if (_repetition != repetition) {
      _repetition = repetition;
      notifyListeners();
    }
  }
  get message => _message;
  String _message="Hello World";
  set message(String message) {
    if (_message != message) {
      _message = message;
      notifyListeners();
    }
  }
  get sound => _sound;
  String _sound="";
  set sound(String sound) {
    if (_sound != sound) {
      _sound = sound;
      notifyListeners();
    }
  }
  String toString(){
    return isActive.toString()+"|"+time_string+"|"+isRepeatEnabled.toString()+"|"+repetition.toString()+"|"+isExpanded.toString()+"|"+message+"|"+sound;
  }
}