import 'package:fruteira/methods/read_data.dart';

bool isNumeric(String? s) {
  if(s == null) {
    return false;
  }
  return double.tryParse(s) != null;
}

String cleanLine(String s) {
  String result = s;
  if (s.lastIndexOf(',') == s.length - 1) {
    result = s.substring(0, s.length - 1);
  }
  return result.trim();
}

List<String> removeEmpty(List<String> source) {
  final List<String> list = [];
  var iterator = source.iterator;
  while (iterator.moveNext()) {
    if (iterator.current.isEmpty || iterator.current.contains(' ')) continue;
    list.add(iterator.current);
  }
  return list;
}

List<String> checkEmpty(List<String> source) {
  var iterator = source.iterator;
  while (iterator.moveNext()) {
    if (iterator.current.isEmpty || iterator.current.contains(' ')) return removeEmpty(source);
  }
  return source;
}

int? getNumeric(List<String> s) {
  int? last;
  int idx = 0;
  for (final String word in s) {
    if (word.isEmpty) {
      return getNumeric(removeEmpty(s));
    }
    String first = word.split('')[0];
    if (isNumeric(first)) {
      last = idx;
    }
    idx ++;
  }
  return last;
}


(String, double, int) retriveInfo(List<String> words) {
  final List<String> noSpace = checkEmpty(words);
  final int? idx = getNumeric(noSpace.sublist(0, noSpace.length - 1));
  if (idx == null) return (noSpace.join(" "), 0, 0);
  final String name = noSpace.sublist(0, idx).join(" ");
  final double price = double.parse(noSpace[idx].replaceAll(RegExp(r','), '.'));
  final int wtype = int.parse(noSpace.last);
  return (name, price, wtype);
}

String cutStr(String str, {int maxSize = 21}) {
  if (str.length <= maxSize) {
    return str;
  }
  else {
    return str.substring(0, 21);
  }
}



List<Item>? textToList(String text, int listid) {
  if (text == '') return null;
  List<Item>? result = [];
  List<String> lines = text.split('\n');
  for (String line in lines) {
    line = cleanLine(line);
    final (String name, double price, int wtype) = retriveInfo(line.split(' '));
    result.add(
      Item(
        name: cutStr(name).capitalize(), 
        price: price, 
        listid: listid,
        wtype: wtype
      )
    );
  }
  return result;
}

extension StringExtensions on String { 
  String capitalize() { 
    return "${this[0].toUpperCase()}${substring(1)}"; 
  } 
}