//
//  main.m
//  ClaudeChat
//

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"

int main(int argc, char *argv[]) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSApplication *application = [NSApplication sharedApplication];
    AppDelegate *appDelegate = [[AppDelegate alloc] init];
    
    [application setDelegate:appDelegate];
    [application run];
    
    [appDelegate release];
    [pool release];
    
    return 0;
}