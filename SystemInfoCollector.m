#import "SystemInfoCollector.h"

@implementation SystemInfoCollector

+ (NSString *)collectSystemInfo {
    NSMutableString *info = [NSMutableString string];
    
    [info appendString:@"=== System Information ===\n"];
    [info appendFormat:@"OS: %@\n", [self getOSVersion]];
    [info appendFormat:@"Hardware: %@\n", [self getHardwareModel]];
    [info appendFormat:@"CPU: %@\n", [self getCPUInfo]];
    [info appendFormat:@"Processors: %@\n", [self getProcessorCount]];
    [info appendFormat:@"Memory: %@\n", [self getMemoryInfo]];
    [info appendFormat:@"User: %@\n", [self getUserInfo]];
    [info appendFormat:@"Hostname: %@\n", [[NSHost currentHost] name]];
    [info appendString:@"==========================\n"];
    
    return info;
}

+ (NSString *)getOSVersion {
    // For Tiger compatibility, use Gestalt
    SInt32 majorVersion, minorVersion, bugFixVersion;
    
    Gestalt(gestaltSystemVersionMajor, &majorVersion);
    Gestalt(gestaltSystemVersionMinor, &minorVersion);
    Gestalt(gestaltSystemVersionBugFix, &bugFixVersion);
    
    // Also get the uname info
    struct utsname systemInfo;
    uname(&systemInfo);
    
    return [NSString stringWithFormat:@"Mac OS X %d.%d.%d (%s %s)", 
            majorVersion, minorVersion, bugFixVersion,
            systemInfo.sysname, systemInfo.release];
}

+ (NSString *)getHardwareModel {
    char model[256];
    size_t len = sizeof(model);
    
    if (sysctlbyname("hw.model", model, &len, NULL, 0) == 0) {
        return [NSString stringWithUTF8String:model];
    }
    
    return @"Unknown";
}

+ (NSString *)getCPUInfo {
    char brand[256];
    size_t len = sizeof(brand);
    
    // Try to get CPU brand string
    if (sysctlbyname("machdep.cpu.brand_string", brand, &len, NULL, 0) == 0) {
        return [NSString stringWithUTF8String:brand];
    }
    
    // Fallback: Get CPU type info
    int cpuType;
    len = sizeof(cpuType);
    if (sysctlbyname("hw.cputype", &cpuType, &len, NULL, 0) == 0) {
        // CPU_TYPE_POWERPC = 18, CPU_TYPE_I386 = 7
        if (cpuType == 18) {
            return @"PowerPC";
        } else if (cpuType == 7) {
            return @"Intel x86";
        }
    }
    
    return @"Unknown CPU";
}

+ (NSString *)getProcessorCount {
    int processorCount;
    size_t len = sizeof(processorCount);
    
    if (sysctlbyname("hw.ncpu", &processorCount, &len, NULL, 0) == 0) {
        return [NSString stringWithFormat:@"%d", processorCount];
    }
    
    return @"Unknown";
}

+ (NSString *)getMemoryInfo {
    unsigned long long memSize;
    size_t len = sizeof(memSize);
    
    if (sysctlbyname("hw.memsize", &memSize, &len, NULL, 0) == 0) {
        double memGB = memSize / (1024.0 * 1024.0 * 1024.0);
        return [NSString stringWithFormat:@"%.2f GB", memGB];
    }
    
    return @"Unknown";
}

+ (NSString *)getUserInfo {
    return NSUserName();
}

@end

@implementation SystemInfoCollector (Extended)

+ (NSString *)getDiskInfo {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSDictionary *attrs = [fm fileSystemAttributesAtPath:@"/"];
    
    if (attrs) {
        NSNumber *size = [attrs objectForKey:NSFileSystemSize];
        NSNumber *freeSize = [attrs objectForKey:NSFileSystemFreeSize];
        
        double totalGB = [size doubleValue] / (1024.0 * 1024.0 * 1024.0);
        double freeGB = [freeSize doubleValue] / (1024.0 * 1024.0 * 1024.0);
        
        return [NSString stringWithFormat:@"%.2f GB total, %.2f GB free", 
                totalGB, freeGB];
    }
    
    return @"Unknown";
}

+ (NSString *)getArchitecture {
    struct utsname systemInfo;
    uname(&systemInfo);
    
    return [NSString stringWithUTF8String:systemInfo.machine];
}

+ (NSString *)getSystemUptime {
    struct timeval boottime;
    size_t len = sizeof(boottime);
    int mib[2] = { CTL_KERN, KERN_BOOTTIME };
    
    if (sysctl(mib, 2, &boottime, &len, NULL, 0) == 0) {
        time_t now = time(NULL);
        time_t uptime = now - boottime.tv_sec;
        
        int days = uptime / 86400;
        int hours = (uptime % 86400) / 3600;
        int minutes = (uptime % 3600) / 60;
        
        return [NSString stringWithFormat:@"%d days, %d hours, %d minutes", 
                days, hours, minutes];
    }
    
    return @"Unknown";
}

@end
