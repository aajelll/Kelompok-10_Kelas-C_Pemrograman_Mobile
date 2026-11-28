import 'package:flutter/foundation.dart';
import 'package:voca/features/auth/providers/auth_provider.dart';

/// AuthProvider palsu (tanpa Firebase): hanya nama dan email.
class FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  FakeAuthProvider({this.name = 'Budi', this.mail = 'budi@contoh.com'});

  final String name;
  final String mail;

  @override
  String get displayName => name;

  @override
  String get email => mail;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}