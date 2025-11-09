//
//  main.m
//  ClaudeChat
//

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"
#import "SAFEArc.h"

int main(int argc, char *argv[]) {
    SAFE_ARC_AUTORELEASE_POOL_PUSH();

    NSApplication *application = [NSApplication sharedApplication];
    AppDelegate *appDelegate = SAFE_ARC_AUTORELEASE([[AppDelegate alloc] init]);

    [application setDelegate:appDelegate];
    [application run];

    SAFE_ARC_AUTORELEASE_POOL_POP();

    return 0;
}