// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/type_environment.dart';
import '../compiler/js_typerep.dart';

class JSTypeRep extends SharedJSTypeRep<DartType> {
  final TypeEnvironment types;
  final CoreTypes coreTypes;

  final Class _jsBool;
  final Class _jsNumber;
  final Class _jsString;

  JSTypeRep(this.types)
      : coreTypes = types.coreTypes,
        _jsBool =
            types.coreTypes.index.getClass('dart:_interceptors', 'JSBool'),
        _jsNumber =
            types.coreTypes.index.getClass('dart:_interceptors', 'JSNumber'),
        _jsString =
            types.coreTypes.index.getClass('dart:_interceptors', 'JSString');

  @override
  JSType typeFor(DartType type) {
    while (type is TypeParameterType) {
      type = (type as TypeParameterType).parameter.bound;
    }
    if (type == null) return JSType.jsUnknown;
    // Note that this should be changed if Dart gets non-nullable types
    if (type == const BottomType()) return JSType.jsNull;

    if (type is InterfaceType) {
      var c = type.classNode;
      if (c == coreTypes.nullClass) return JSType.jsNull;
      if (c == coreTypes.numClass ||
          c == coreTypes.intClass ||
          c == coreTypes.doubleClass ||
          c == _jsNumber) {
        return JSType.jsNumber;
      }
      if (c == coreTypes.boolClass || c == _jsBool) return JSType.jsBoolean;
      if (c == coreTypes.stringClass || c == _jsString) return JSType.jsString;
      if (c == coreTypes.objectClass) return JSType.jsUnknown;
      if (c == coreTypes.futureOrClass) {
        var argumentRep = typeFor(type.typeArguments[0]);
        if (argumentRep is JSObject || argumentRep is JSNull) {
          return JSType.jsObject;
        }
        return JSType.jsUnknown;
      }
    }
    if (type == const DynamicType() || type == const VoidType()) {
      return JSType.jsUnknown;
    }
    return JSType.jsObject;
  }

  /// Given a Dart type return the known implementation type, if any.
  /// Given `bool`, `String`, or `num`/`int`/`double`,
  /// returns the corresponding class in `dart:_interceptors`:
  /// `JSBool`, `JSString`, and `JSNumber` respectively, otherwise null.
  Class getImplementationClass(DartType t) {
    JSType rep = typeFor(t);
    // Number, String, and Bool are final
    if (rep == JSType.jsNumber) return _jsNumber;
    if (rep == JSType.jsBoolean) return _jsBool;
    if (rep == JSType.jsString) return _jsString;
    return null;
  }
}
