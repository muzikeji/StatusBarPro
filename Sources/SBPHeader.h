#import <UIKit/UIKit.h>
#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <substrate.h>

#pragma mark - Shared prefs key
#define SBPPrefPath @"/var/mobile/Library/Preferences/com.muzikeji.statusbarpro.plist"

static inline id SBPGetPref(NSString *key) {
    NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:SBPPrefPath];
    if (!d) return nil;
    return d[key];
}

static inline void SBPSetPref(NSString *key, id value) {
    NSMutableDictionary *d = [NSMutableDictionary dictionaryWithContentsOfFile:SBPPrefPath] ?: [NSMutableDictionary new];
    d[key] = value;
    [d writeToFile:SBPPrefPath atomically:YES];
}