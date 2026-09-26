#import "SBPHeader.h"
#import <UIKit/UIKit.h>

// 设置入口, 用户修改偏好后弹出此页面即可 Respring
// PSListController 子类: 当用户点击 PreferenceLoader entry 时作为 root controller

@interface SBPPreferencesListController : PSListController @end

@implementation SBPPreferencesListController

- (id)readPreferenceValue:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"key"];
    NSString *path = @"/var/mobile/Library/Preferences/com.muzikeji.statusbarpro.plist";
    NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:path];
    id v = d[key];
    if (!v) v = [specifier propertyForKey:@"default"];
    return v;
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"key"];
    NSString *path = @"/var/mobile/Library/Preferences/com.muzikeji.statusbarpro.plist";
    NSMutableDictionary *d = [NSMutableDictionary dictionaryWithContentsOfFile:path] ?: [NSMutableDictionary new];
    d[key] = value;
    [d writeToFile:path atomically:YES];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
        (CFStringRef)@"com.muzikeji.statusbarprefschanged", NULL, NULL, true);
}

- (void)openColorPicker {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"选择状态栏前景色"
                                                                message:nil
                                                         preferredStyle:UIAlertControllerStyleActionSheet];
    NSArray *colors = @[@"#FFFFFF", @"#000000", @"#FFCC00", @"#00CC66", @"#0099FF", @"#FF3366"];
    for (NSString *hex in colors) {
        [a addAction:[UIAlertAction actionWithTitle:hex style:UIAlertActionStyleDefault handler:^(UIAlertAction *_) {
            NSString *path = @"/var/mobile/Library/Preferences/com.muzikeji.statusbarpro.plist";
            NSMutableDictionary *d = [NSMutableDictionary dictionaryWithContentsOfFile:path] ?: [NSMutableDictionary new];
            d[@"foregroundColor"] = hex;
            [d writeToFile:path atomically:YES];
            CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                (CFStringRef)@"com.muzikeji.statusbarprefschanged", NULL, NULL, true);
        }]];
    }
    [a addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}

@end

// 简易 fallback Controller: iOS 15 不会执行 PSSwitchCell 等, 退回到手写 UI
@interface SBPPreferencesController : UIViewController
@end

@implementation SBPPreferencesController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"状态栏美化";
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    UILabel *tip = [UILabel new];
    tip.text = @"修改后请 Respring 以应用";
    tip.textColor = [UIColor secondaryLabelColor];
    tip.textAlignment = NSTextAlignmentCenter;
    tip.frame = CGRectMake(20, 100, self.view.bounds.size.width - 40, 30);
    [self.view addSubview:tip];

    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = CGRectMake(20, 160, self.view.bounds.size.width - 40, 44);
    [btn setTitle:@"应用并刷新" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(apply:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}

- (void)apply:(id)sender {
    NSString *path = @"/var/mobile/Library/Preferences/com.muzikeji.statusbarpro.plist";
    NSMutableDictionary *d = [NSMutableDictionary dictionaryWithContentsOfFile:path] ?: [NSMutableDictionary new];
    d[@"use24h"] = @(YES);
    d[@"showDate"] = @(YES);
    d[@"showWeekday"] = @(YES);
    d[@"showLunar"] = @(YES);
    d[@"signalStyle"] = @2;
    d[@"batteryStyle"] = @0;
    d[@"wifiCustom"] = @(YES);
    d[@"foregroundColor"] = @"#FFFFFF";
    [d writeToFile:path atomically:YES];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
        (CFStringRef)@"com.muzikeji.statusbarprefschanged", NULL, NULL, true);
}
@end