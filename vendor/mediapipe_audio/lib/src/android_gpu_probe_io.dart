import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

typedef _PlatformsNative =
    Int32 Function(Uint32, Pointer<Pointer<Void>>, Pointer<Uint32>);
typedef _Platforms = int Function(int, Pointer<Pointer<Void>>, Pointer<Uint32>);
typedef _DevicesNative =
    Int32 Function(
      Pointer<Void>,
      Uint64,
      Uint32,
      Pointer<Pointer<Void>>,
      Pointer<Uint32>,
    );
typedef _Devices =
    int Function(
      Pointer<Void>,
      int,
      int,
      Pointer<Pointer<Void>>,
      Pointer<Uint32>,
    );

bool? _available;

/// Checks the driver exposed to this Android process, without creating a model.
/// This is an availability check, not proof of successful model delegation.
bool hasAndroidOpenClGpu() {
  if (!Platform.isAndroid) return false;
  return _available ??= _probe();
}

bool _probe() {
  for (final name in ['libOpenCL.so', 'libOpenCL-pixel.so']) {
    try {
      final library = DynamicLibrary.open(name);
      final platforms = library.lookupFunction<_PlatformsNative, _Platforms>(
        'clGetPlatformIDs',
      );
      final devices = library.lookupFunction<_DevicesNative, _Devices>(
        'clGetDeviceIDs',
      );
      final found = using((arena) {
        final count = arena<Uint32>();
        if (platforms(0, nullptr, count) != 0 ||
            count.value == 0 ||
            count.value > 64) {
          return false;
        }
        final ids = arena<Pointer<Void>>(count.value);
        if (platforms(count.value, ids, nullptr) != 0) return false;
        final gpuCount = arena<Uint32>();
        for (var i = 0; i < count.value; i++) {
          gpuCount.value = 0;
          // CL_DEVICE_TYPE_GPU = 1 << 2. CPU OpenCL devices do not qualify.
          if (devices(ids[i], 1 << 2, 0, nullptr, gpuCount) == 0 &&
              gpuCount.value > 0) {
            return true;
          }
        }
        return false;
      });
      if (found) return true;
    } on Object {
      // The optional driver may be absent or not exposed by the OS namespace.
    }
  }
  return false;
}
