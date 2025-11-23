#ifndef ANTHROPIC_CLASSIC_H
#define ANTHROPIC_CLASSIC_H

#import "SAFEArc.h"
#import "TigerCompat.h"
#import "Hig.h"
#import "OS.h"

#define AT_LEAST_TIGER (MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_4)
#define AT_LEAST_LEOPARD (MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5)

#ifdef __clang__
  #define SUPPRESS_DEPRECATED_WARNINGS_BEGIN \
    _Pragma("clang diagnostic push") \
    _Pragma("clang diagnostic ignored \"-Wdeprecated-declarations\"")
  #define SUPPRESS_DEPRECATED_WARNINGS_END \
    _Pragma("clang diagnostic pop")
#else
  #define SUPPRESS_DEPRECATED_WARNINGS_BEGIN \
    _Pragma("GCC diagnostic push") \
    _Pragma("GCC diagnostic ignored \"-Wdeprecated-declarations\"")
  #define SUPPRESS_DEPRECATED_WARNINGS_END \
    _Pragma("GCC diagnostic pop")
#endif

#endif
