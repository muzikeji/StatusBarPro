#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <spawn.h>
#import <stdlib.h>
#import <string.h>

#define kPrefsChanged CFSTR("com.muzikeji.statusbarprefschanged")
#define kRespring     CFSTR("com.muzikeji.statusbarpro/respring")

// 说明：所有开关/分段的即时刷新依赖「立即重载状态栏」按钮。
// 按钮发出 Darwin 通知 com.muzikeji.statusbarprefschanged，
// SpringBoard 端的 reloadPrefs 回调收到后会重新应用样式。
@interface StatusBarProPrefsListController : PSListController
- (BOOL)spawnFirstAvailable:(NSArray<NSString *> *)paths
                  arguments:(NSArray<NSString *> *)args;
@end

@implementation StatusBarProPrefsListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }
    return _specifiers;
}

// 立即重载状态栏：通知 SpringBoard 重新应用全部设置。
- (void)reloadStatusBar:(id)sender {
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
        kPrefsChanged, NULL, NULL, YES);
}

// 注销：优先让 SpringBoard 端自杀（tweak 在 SpringBoard 进程里监听
// kRespring，对 rootless/roothide 都有效）；sbreload/killall 作为兜底。
- (void)respring:(id)sender {
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
        kRespring, NULL, NULL, YES);
    if ([self spawnFirstAvailable:@[ @"/var/jb/usr/bin/sbreload", @"/usr/bin/sbreload" ]
                        arguments:@[]]) {
        return;
    }
    [self spawnFirstAvailable:@[ @"/var/jb/usr/bin/killall", @"/usr/bin/killall" ]
                    arguments:@[ @"-9", @"SpringBoard" ]];
}

- (BOOL)spawnFirstAvailable:(NSArray<NSString *> *)paths
                  arguments:(NSArray<NSString *> *)args {
    NSFileManager *fm = [NSFileManager defaultManager];
    for (NSString *path in paths) {
        if (![fm isExecutableFileAtPath:path]) continue;
        NSMutableArray<NSString *> *argvStrings = [NSMutableArray arrayWithObject:path];
        [argvStrings addObjectsFromArray:args];
        char **argv = calloc(argvStrings.count + 1, sizeof(char *));
        if (!argv) continue;
        for (NSUInteger i = 0; i < argvStrings.count; i++) {
            argv[i] = strdup(argvStrings[i].UTF8String);
        }
        argv[argvStrings.count] = NULL;
        pid_t pid = 0;
        int rc = posix_spawn(&pid, path.UTF8String, NULL, NULL, argv, NULL);
        for (NSUInteger i = 0; i < argvStrings.count; i++) free(argv[i]);
        free(argv);
        if (rc == 0) return YES;
    }
    return NO;
}

@end