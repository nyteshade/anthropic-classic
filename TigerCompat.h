#ifndef TIGER_COMPAT_H
#define TIGER_COMPAT_H

#include <AvailabilityMacros.h>

#ifndef MAC_OS_X_VERSION_10_5
#define MAC_OS_X_VERSION_10_5 1050
#endif

#if MAX_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_5

typedef int NSInteger;
typedef unsigned int NSUInteger;
typedef float CGFloat;

#define NEHProperty(type, getter, setter) \
  - (type)getter; \
  - (void)setter:(type)value;

#define NEMProperty(type, getter, setter) \
  - (type)getter \
  { \
    return _##getter; \
  } \
  - (void)setter:(type)value \
  { \
    _##getter = value; \
  }

#else /* MAX_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_5 */

#define NEHProperty(type, getter, setter) \
  @property (nonatomic, retain) type getter;

#define NEMProperty(type, getter, setter) \
  @synthesize getter = _##getter
  
#endif /* MAX_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_5 */

#endif /* TIGER_COMPAT_H */