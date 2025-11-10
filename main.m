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
    // Don't autorelease - NSApplication doesn't retain its delegate on Leopard/Tiger
    // The delegate must live for the entire application lifetime
    AppDelegate *appDelegate = [[AppDelegate alloc] init];

    [application setDelegate:appDelegate];
    [application run];

    // Cleanup only happens after app quits
    SAFE_ARC_RELEASE(appDelegate);
    SAFE_ARC_AUTORELEASE_POOL_POP();

    return 0;
}