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
@interface UIStatusBarStyleRequest : NSObject
@property(retain, nonatomic) UIColor *foregroundColor;
@property(retain, nonatomic) UIColor *backgroundColor;
@property(assign, nonatomic) long long style;       // iOS 17+
@property(retain, nonatomic) NSNumber *styleOverride; // iOS 16+ fallback
@end

#pragma mark - Time / Battery / WiFi items
// iOS 15: UIStatusBarTimeItemView
// iOS 16: UIStatusBarTimeItemView (still used) + UIStatusBarTimeContainerView
// iOS 17: split into UIStatusBarTimeItemView (item) + UIStatusBarDisplayableItem-derived UIStatusBarTimeContainerView
@interface UIStatusBarTimeItemView : UIView
- (void)refreshTimeEntry;
- (CGSize)sizeThatFits:(CGSize)size;
@end

// iOS 16+ new container for time
@interface UIStatusBarTimeContainerView : UIView
@property(retain, nonatomic) UIView *timeView;     // UIStatusBarTimeItemView
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
@property(retain, nonatomic) NSString *text;
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