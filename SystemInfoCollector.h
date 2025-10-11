#ifndef SYSTEMCOLLECTOR_H
#define SYSTEMCOLLECTOR_H

#import <Foundation/Foundation.h>
#import <sys/sysctl.h>
#import <sys/utsname.h>

@interface SystemInfoCollector : NSObject

+ (NSString *)collectSystemInfo;
+ (NSString *)getOSVersion;
+ (NSString *)getHardwareModel;
+ (NSString *)getCPUInfo;
+ (NSString *)getMemoryInfo;
+ (NSString *)getUserInfo;
+ (NSString *)getProcessorCount;

@end

@interface SystemInfoCollector (Extended)

+ (NSString *)getDiskInfo;
+ (NSString *)getArchitecture;
+ (NSString *)getSystemUptime;

@end

#endif