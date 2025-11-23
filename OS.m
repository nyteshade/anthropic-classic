#import "AnthropicClassic.h"
#import "SystemInfoCollector.h"
#import "OS.h"

SUPPRESS_DEPRECATED_WARNINGS_BEGIN

@implementation OS

+ (BOOL)isTiger
{
  SInt32 minorVersion;
  
  Gestalt(gestaltSystemVersionMinor, &minorVersion);

  return minorVersion == 4;
}

+ (BOOL)isLeopard
{
  SInt32 minorVersion;
  
  Gestalt(gestaltSystemVersionMinor, &minorVersion);

  return minorVersion == 5;
}

+ (BOOL)isPowerPC
{
  NSString *cpuType = [SystemInfoCollector getCPUInfo];
  
  return [cpuType caseInsensitiveCompare:@"PowerPC"] == NSOrderedSame;
}

+ (BOOL)isIntel
{
  NSString *cpuType = [SystemInfoCollector getCPUInfo];
  
  return [cpuType caseInsensitiveCompare:@"Intel x86"] == NSOrderedSame;
}

@end

SUPPRESS_DEPRECATED_WARNINGS_END
