import 'package:flutter/material.dart';

// Equivalente a src/context/NotificacionContext.jsx en React
// Provee: unread, incrementUnread(), resetUnread()

class NotificacionContext extends ChangeNotifier {
  int _unread = 0;

  int get unread => _unread;

  void setUnread(int count) {
    _unread = count;
    notifyListeners();
  }

  void incrementUnread() {
    _unread++;
    notifyListeners();
  }

  void resetUnread() {
    _unread = 0;
    notifyListeners();
  }
}
