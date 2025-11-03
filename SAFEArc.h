//
//  SAFEArc.h
//  Compatibility helpers for ARC and MRC Objective-C code.
//
//  Drop this in your project and `#import "SAFEArc.h"` wherever you want to
//  write ARC-agnostic code. All macros are prefixed to avoid collisions.
//
//  Usage examples:
//    NSString *s = SAFE_ARC_AUTORELEASE([[NSString alloc] initWithUTF8String:"x"]);
//    self.name = SAFE_ARC_RETAIN(tmp);
//    SAFE_ARC_RELEASE(tmp);
//    SAFE_ARC_SUPER_DEALLOC;
//
//    SAFE_ARC_AUTORELEASE_POOL_PUSH();
//    /* work */
//    SAFE_ARC_AUTORELEASE_POOL_POP();
//
//    CFStringRef cfs = SAFE_ARC_BRIDGE_TO_CF(CFStringRef, s);
//    NSString *ns = SAFE_ARC_CF_TRANSFER(NSString *, CFStringCreate...(...));
//
//    dispatch_queue_t q = dispatch_queue_create("q", NULL);
//    SAFE_ARC_DISPATCH_RELEASE(q);
//
//  Written by ChatGPT 5 under the direction of Brielle Harrison
//  [ ] Compiled and tested on OS X Tiger
//  [ ] Compiled and tested on OS X Leopard
//  [ ] Compiled and tested on OS X Snow Leopard
//  [ ] Compiled and tested on OS X Lion
//  [ ] Compiled and tested on OS X Mountain Lion
//  [ ] Compiled and tested on macOS 26 Tahoe

#ifndef SAFE_ARC_H
#define SAFE_ARC_H

// ---- Feature probes ---------------------------------------------------------

#ifndef __has_feature
  #define __has_feature(x) 0
#endif

#ifndef __has_extension
  #define __has_extension(x) 0
#endif

// Clang defines OS_OBJECT_USE_OBJC=1 when GCD objects are Objective-C objects
// (no manual dispatch_release needed).
#ifndef OS_OBJECT_USE_OBJC
  #define OS_OBJECT_USE_OBJC 0
#endif

// ---- Ownership operations ---------------------------------------------------
// Balanced retain/release/autorelease that compile both with and without ARC.

#if __has_feature(objc_arc)

  #define SAFE_ARC_AUTORELEASE(x)   (x)
  #define SAFE_ARC_RELEASE(x)       ((void)(x))
  #define SAFE_ARC_RETAIN(x)        (x)
  #define SAFE_ARC_BRIDGED_RETAIN(x) (x)  /* legacy alias if you used it */
  #define SAFE_ARC_SUPER_DEALLOC    ((void)0)

  // Blocks
  #define SAFE_ARC_BLOCK_COPY(x)    (x)
  #define SAFE_ARC_BLOCK_RELEASE(x) ((void)(x))

  // Properties: choose the right attribute keywords at compile time
  #define SAFE_ARC_PROP_RETAIN      strong
  #define SAFE_ARC_PROP_COPY        copy
  #define SAFE_ARC_PROP_ASSIGN      assign

  // Weak references (fallbacks if weak isn’t available)
  #if __has_feature(objc_arc_weak)
    #define SAFE_ARC_WEAK           weak
    #define SAFE_ARC_WEAK_QUAL      __weak
  #else
    // On very old runtimes, emulate with assign (be careful!)
    #define SAFE_ARC_WEAK           assign
    #define SAFE_ARC_WEAK_QUAL
  #endif

  // Autorelease pool
  #define SAFE_ARC_AUTORELEASE_POOL_PUSH() @autoreleasepool {
  #define SAFE_ARC_AUTORELEASE_POOL_POP()  }

  // CoreFoundation bridging
  #define SAFE_ARC_BRIDGE_TO_CF(cf_type, obj)   (__bridge cf_type)(obj)
  #define SAFE_ARC_BRIDGE_TO_ID(id_type, cf)    (__bridge id_type)(cf)
  #define SAFE_ARC_CF_TRANSFER(id_type, cf)     (__bridge_transfer id_type)(cf)
  #define SAFE_ARC_ID_TRANSFER(cf_type, obj)    (__bridge_retained cf_type)(obj)

  // GCD/OS objects
  #if OS_OBJECT_USE_OBJC
    #define SAFE_ARC_DISPATCH_RELEASE(x) ((void)(x))
  #else
    #define SAFE_ARC_DISPATCH_RELEASE(x) dispatch_release(x)
  #endif

  // Nil-and-release convenience
  #define SAFE_ARC_RELEASE_AND_NIL(x) do { (x) = nil; } while (0)

  // Unavailable markers when ARC is on (for MRC-only APIs)
  #define SAFE_ARC_MRC_ONLY_UNAVAILABLE \
    __attribute__((unavailable("Not available with ARC")))

#else  // ------------------------------ MRC branch -----------------------------

  #define SAFE_ARC_AUTORELEASE(x)   ([(x) autorelease])
  #define SAFE_ARC_RELEASE(x)       ([(x) release])
  #define SAFE_ARC_RETAIN(x)        ([(x) retain])
  #define SAFE_ARC_BRIDGED_RETAIN(x) ([(x) retain])
  #define SAFE_ARC_SUPER_DEALLOC    ([super dealloc])

  // Blocks
  #define SAFE_ARC_BLOCK_COPY(x)    (Block_copy(x))
  #define SAFE_ARC_BLOCK_RELEASE(x) (Block_release(x))

  // Properties
  #define SAFE_ARC_PROP_RETAIN      retain
  #define SAFE_ARC_PROP_COPY        copy
  #define SAFE_ARC_PROP_ASSIGN      assign

  // No weak; use assign. (Consider zeroing-weak emulation if you need it.)
  #define SAFE_ARC_WEAK             assign
  #define SAFE_ARC_WEAK_QUAL

  // Autorelease pool
  #define SAFE_ARC_AUTORELEASE_POOL_PUSH() \
    NSAutoreleasePool *__safe_arc_pool = [[NSAutoreleasePool alloc] init];
  #define SAFE_ARC_AUTORELEASE_POOL_POP()  \
    [__safe_arc_pool drain];

  // CoreFoundation bridging: plain casts (you own what CF says you own)
  #define SAFE_ARC_BRIDGE_TO_CF(cf_type, obj)   ((cf_type)(obj))
  #define SAFE_ARC_BRIDGE_TO_ID(id_type, cf)    ((id_type)(cf))
  #define SAFE_ARC_CF_TRANSFER(id_type, cf)     ((id_type)(cf)) /* remember to release */
  #define SAFE_ARC_ID_TRANSFER(cf_type, obj)    ((cf_type)(obj)) /* remember to CFRelease */

  // GCD/OS objects
  #define SAFE_ARC_DISPATCH_RELEASE(x) dispatch_release(x)

  // Nil-and-release convenience
  #define SAFE_ARC_RELEASE_AND_NIL(x) \
    do { if ((x) != nil) { [(x) release]; (x) = nil; } } while (0)

  // Unavailable markers: no restriction under MRC
  #define SAFE_ARC_MRC_ONLY_UNAVAILABLE

#endif // __has_feature(objc_arc)

// ---- Helpful compile-time checks -------------------------------------------

#if !__has_feature(objc_arc) && !__has_extension(objc_arc)
  // You’re compiling without ARC support entirely (very old toolchain).
  // Macros still work, but consider gating code paths if needed.
#endif

#endif // SAFE_ARC_H
