//
//  TigerCompat.h
//  anthropic-classic
//
//  Platform compatibility header for Tiger and later
//

#ifndef TigerCompat_h
#define TigerCompat_h

#include <AvailabilityMacros.h>
#include <TargetConditionals.h>

// Ensure we're on macOS
#if !TARGET_OS_MAC || TARGET_OS_IPHONE
#error "This code is designed for macOS only"
#endif

// Platform detection helpers
#define IS_TIGER_OR_LATER (MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_4)
#define IS_LEOPARD_OR_LATER (MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_5)
#define IS_SNOW_LEOPARD_OR_LATER (MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_6)

// Architecture-specific typedef handling
#ifdef __LP64__
    // 64-bit architectures
    #ifndef NE_INT_TYPE_DEFINED
        typedef int NEIntType;
        typedef float NEFloatType;
        typedef unsigned int NEUIntType;
        #define NE_INT_TYPE_DEFINED 1
    #endif
#else
    // 32-bit architectures (Tiger era)
    #ifndef NE_INT_TYPE_DEFINED
        typedef long NEIntType;
        typedef double NEFloatType;
        typedef unsigned long NEUIntType;
        #define NE_INT_TYPE_DEFINED 1
    #endif
#endif

// Runtime OS detection function
static inline BOOL NEIsRunningOnTigerOrLater(void) {
    return NSAppKitVersionNumber >= NSAppKitVersionNumber10_4;
}

static inline BOOL NEIsRunningOnLeopardOrLater(void) {
    return NSAppKitVersionNumber >= NSAppKitVersionNumber10_5;
}

// Safe feature availability checks
#define NE_HAS_CORE_ANIMATION IS_LEOPARD_OR_LATER
#define NE_HAS_GARBAGE_COLLECTION IS_LEOPARD_OR_LATER

#endif /* TigerCompat_h */