// StatusBarProPrefs.h - reverse engineered declarations across iOS 15/16/17
// (Enough symbols to build; extend via class-dump if you need more.)

#import <UIKit/UIKit.h>

#pragma mark - UIStatusBarServer (cross-process)
@interface UIStatusBarServer : NSObject
+ (instancetype)sharedStatusBarServer;
- (void)postStatusBarStyleOverrides:(NSDictionary *)overrides;
// iOS 16+: "postStatusBarStyleOverrides:outStyleOverrides:waitForUnlock:"
//          "postStatusBarIdentityProviderStateChange:"
@end

#pragma mark - Style Request
// 真实 UIKit 类: UIStatusBarStyleRequest 的 foregroundColor 是只读的,
// 可写属性在其可变子类 NSMutableUIStatusBarStyleRequest 上。
// 对只读类调用 setter 会抛 unrecognized selector, 曾导致 SpringBoard
// 崩溃进安全模式, 所以此处按真实接口声明, 代码里实例化可变子类。
@interface UIStatusBarStyleRequest : NSObject
@property(nonatomic, readonly) UIColor *foregroundColor;
@property(nonatomic, readonly) UIStatusBarStyle requestedStyle;
@end

@interface NSMutableUIStatusBarStyleRequest : UIStatusBarStyleRequest
@property(nonatomic, retain) UIColor *foregroundColor;
@property(nonatomic) UIStatusBarStyle requestedStyle;
@end

#pragma mark - Time / Battery / WiFi items
// iOS 15: UIStatusBarTimeItemView
// iOS 16: UIStatusBarTimeItemView (still used) + UIStatusBarTimeContainerView
// iOS 17: split into UIStatusBarTimeItemView (item) + UIStatusBarDisplayableItem-derived UIStatusBarTimeContainerView
@interface UIStatusBarTimeItemView : UIView
- (void)refreshTimeEntry;
- (CGSize)sizeThatFits:(CGSize)size;
- (void)sbpinstallTimeLabel;
@end

// iOS 16+ new container for time
@interface UIStatusBarTimeContainerView : UIView
@property(retain, nonatomic) UIView *timeView;     // UIStatusBarTimeItemView
- (void)sbpinstallTimeLabel;
@end

// iOS 17+ uses a wrapper UIStatusBarItemView
@interface UIStatusBarItemView : UIView
@property(retain, nonatomic) UIView *childItemView;
@end

#pragma mark - Image / String containers
@interface UIStatusBarImageView : UIView
@property(retain, nonatomic) NSString *namedImageName;
@property(retain, nonatomic) UIImage *image;
@property(assign, nonatomic) CGFloat highlightedAlpha;
@end

@interface UIStatusBarStringView : UILabel
@property(copy, nonatomic) NSString *text;
@end

#pragma mark - Generic Status Bar Infrastructure
@interface UIStatusBarItem : NSObject
@property(retain, nonatomic) NSString *entryName;
@end

@interface UIStatusBarForegroundView : UIView
- (UIView *)itemViewNamed:(NSString *)name;
// iOS 16+: -itemViewNamed:scanLocation:
// iOS 17+: -itemViewsForStyle: 
@end

@interface UIStatusBar : UIView
@property(retain, nonatomic) UIStatusBarForegroundView *foregroundView;
@property(assign, nonatomic) CGFloat barHeight;       // iOS 16+ override-able
- (void)setHidden:(BOOL)hidden;
@end

// iOS 17 introduced UIStatusBarInternalLayoutManager-driven layout
@interface UIStatusBarLayoutManager : NSObject
@property(retain, nonatomic) NSMutableArray *foregroundViews;
@end

// iOS 17+: per-pixel layout
@interface UIStatusBarInternalLayoutManager : NSObject @end

#pragma mark - iOS 16/17 SpringBoard: STUIStatusBar* (SystemStatusUI.framework)
// class-dump 自 iOS 17 真机 (MTACS/iOS-17-Runtime-Headers)。
// SpringBoard 顶部状态栏从 iOS 16 起改用 STUI 体系, iOS 15 及以下才是
// UIStatusBarTimeItemView/UIStatusBarImageView 那套老类。
@protocol STUIStatusBarDisplayable <NSObject> @end

@interface STUIStatusBarItem : NSObject
- (id)applyUpdate:(id)arg1 toDisplayItem:(id)arg2;
@end

@interface STUIStatusBarStringView : UILabel
@property(nonatomic, copy) NSString *alternateText;
@property(nonatomic, readonly) NSTimer *alternateTextTimer;
@property(nonatomic) long long fontStyle;
@property(nonatomic, copy) NSString *originalText;
@property(nonatomic) bool showsAlternateText;
- (void)applyStyleAttributes:(id)arg1;
- (void)didMoveToWindow;
@end

@interface STUIStatusBarTimeItem : STUIStatusBarItem
@property(nonatomic, retain) STUIStatusBarStringView *dateView;
@property(nonatomic, retain) STUIStatusBarStringView *pillTimeView;
@property(nonatomic, retain) STUIStatusBarStringView *shortTimeView;
@property(nonatomic, retain) STUIStatusBarStringView *timeView;
@end

@interface STUIStatusBarSignalView : UIView
@property(nonatomic, copy) UIColor *activeColor;
@property(nonatomic) long long iconSize;
@property(nonatomic, copy) UIColor *inactiveColor;
@property(nonatomic) long long numberOfActiveBars;
@property(nonatomic) long long numberOfBars;
@property(nonatomic) long long signalMode;
@property(nonatomic) bool smallSize;
- (void)_updateBars;
- (void)_colorsDidChange;
@end

@interface STUIStatusBarCellularSignalView : STUIStatusBarSignalView @end
@interface STUIStatusBarWifiSignalView : STUIStatusBarSignalView @end

@interface STUIStatusBarBatteryView : UIView
@property(nonatomic, copy) UIColor *bodyColor;
@property(nonatomic, copy) UIColor *fillColor;
@property(nonatomic, copy) UIColor *boltColor;
@property(nonatomic, copy) UIColor *pinColor;
@property(nonatomic, copy) UIColor *inactiveColor;
@end

@interface STUIStatusBar : UIView
@property(nonatomic, copy) UIColor *foregroundColor;
@property(nonatomic, retain) UIView *foregroundView;
- (void)setForegroundColor:(UIColor *)color;
- (void)layoutSubviews;
@end