#import "SBPHeader.h"
#import "StatusBarProPrefs.h"

#pragma mark - 系统版本探测
static inline BOOL SBP_iOS17OrLater(void) {
    return [[[UIDevice currentDevice] systemVersion] floatValue] >= 17.0;
}
static inline BOOL SBP_iOS16OrLater(void) {
    return [[[UIDevice currentDevice] systemVersion] floatValue] >= 16.0;
}
static inline BOOL SBP_iOS15(void) {
    NSString *v = [[UIDevice currentDevice] systemVersion];
    return [v hasPrefix:@"15."];
}

#pragma mark - 农历查表 (2000-2099)
// 每个 uint32_t 编码该年信息:
//   - 高 4 位 = 闰月月份 (0 表示无闰月)
//   - 中 12 位 = 每月大小月标志 (1 = 大月 30 天, 0 = 小月 29 天)
//   - 低 16 位 = 月份顺序位 (bit 15..4 对应月 1..12)
// 完整表可从香港天文台公开数据生成
static const uint32_t kLunarInfo[] = {
    0x04bd8,0x04ae0,0x0a570,0x054d5,0x0d260,0x0d950,0x16554,0x056a0,0x09ad0,0x055d2, // 2000-2009
    0x04ae0,0x0a5b6,0x0a4d0,0x0d250,0x1d255,0x0b540,0x0d6a0,0x0ada2,0x095b0,0x14977, // 2010-2019
    0x04970,0x0a4b0,0x0b4b5,0x06a50,0x06d40,0x1ab54,0x02b60,0x09570,0x052f2,0x04970, // 2020-2029
    0x06566,0x0d4a0,0x0ea50,0x06e95,0x05ad0,0x02b60,0x186e3,0x092e0,0x1c8d7,0x0c950, // 2030-2039
    0x0d4a0,0x1d8a6,0x0b550,0x056a0,0x1a5b4,0x025d0,0x092d0,0x0d2b2,0x0a950,0x0b557, // 2040-2049
    0x06ca0,0x0b550,0x15355,0x04da0,0x0a5b0,0x14573,0x052b0,0x0a9a8,0x0e950,0x06aa0, // 2050-2059
    0x0aea6,0x0ab50,0x04b60,0x0aae4,0x0a570,0x05260,0x0f263,0x0d950,0x05b57,0x056a0, // 2060-2069
    0x096d0,0x04dd5,0x04ad0,0x0a4d0,0x0d4d4,0x0d250,0x0d558,0x0b540,0x0b6a0,0x195a6, // 2070-2079
    0x095b0,0x049b0,0x0a974,0x0a4b0,0x0b27a,0x06a50,0x06d40,0x0af46,0x0ab60,0x09570, // 2080-2089
    0x04af5,0x04970,0x064b0,0x074a3,0x0ea50,0x06b58,0x055c0,0x0ab60,0x096d5,0x092e0, // 2090-2099
    0x0c960,0x0d954,0x0d4a0,0x0da50,0x07552,0x056a0,0x0abb7,0x025d0,0x092d0,0x0cab5, // 2100-2109
    0x0a950,0x0b4a0,0x0baa4,0x0ad50,0x055d9,0x04ba0,0x0a5b0,0x15176,0x052b0,0x0a930, // 2110-2119
    0x07954,0x06aa0,0x0ad50,0x05b52,0x04b60,0x0a6e6,0x0a4e0,0x0d260,0x0ea65,0x0d530, // 2120-2129
    0x05aa0,0x076a3,0x096d0,0x04afb,0x04ad0,0x0a4d0,0x1d0b6,0x0d250,0x0d520,0x0dd45, // 2130-2139
    0x0b5a0,0x056d0,0x055b2,0x049b0,0x0a577,0x0a4b0,0x0aa50,0x1b255,0x06d20,0x0ada0, // 2140-2149
    0x14b63,0x09370,0x049f8,0x04970,0x064b0,0x168a6,0x0ea50,0x06b20,0x1a6c4,0x0aae0, // 2150-2159
    0x0a2e0,0x0d2e3,0x0c960,0x0d557,0x0d4a0,0x0da50,0x05d55,0x056a0,0x0a6d0,0x055d4, // 2160-2169
    0x052d0,0x0a9b8,0x0a950,0x0b4a0,0x0b6a6,0x0ad50,0x055a0,0x0aba0,0x025b0,0x052b0, // 2170-2179
    0x0b273,0x06930,0x07337,0x06aa0,0x0ad50,0x14b55,0x04b60,0x0a570,0x054e4,0x0d160, // 2180-2189
    0x0e968,0x0d520,0x0daa0,0x16aa6,0x056d0,0x04ae0,0x0a9d4,0x0a2d0,0x0d150,0x0f252, // 2190-2199
};
#define LUNAR_YEAR_MIN 2000
#define LUNAR_YEAR_MAX 2199

static BOOL lunarInRange(int y) { return y >= LUNAR_YEAR_MIN && y <= LUNAR_YEAR_MAX; }
static uint32_t lunarInfo(int y) { return kLunarInfo[y - LUNAR_YEAR_MIN]; }

static int lunarLeapMonth(int y) { return lunarInfo(y) >> 16; }
static BOOL lunarLeapBig(int y)  { return (lunarInfo(y) >> 4) & 1; }
static int lunarMonthDays(int y, int m) {
    if (m > 12) return lunarLeapBig(y) ? 30 : 29;
    return (lunarInfo(y) >> (16 - m)) & 1 ? 30 : 29;
}
static int lunarYearDays(int y) {
    int sum = 348; // 12 * 29
    for (uint32_t i = 0x8000; i > 0x8; i >>= 1) {
        if (lunarInfo(y) & i) sum++;
    }
    int leap = lunarLeapMonth(y);
    return sum + (leap ? (lunarLeapBig(y) ? 30 : 29) : 0);
}

static NSString *chineseDay(int d) {
    static NSString *tian[] = {"初","十","廿","三十"};
    static NSString *di[]   = {"","一","二","三","四","五","六","七","八","九"};
    if (d == 10) return @"初十";
    if (d == 20) return @"二十";
    if (d == 30) return @"三十";
    if (d < 11)  return [tian[0] stringByAppendingString:di[d]];
    if (d < 20)  return [tian[1] stringByAppendingString:di[d-10]];
    return [tian[2] stringByAppendingString:di[d-20]];
}

static void solarToLunar(int y, int m, int d, int *ly, int *lm, int *ld) {
    // 计算与 1900-01-31 (农历 1900-01-01) 的天数差
    int daysFromBase = 0;
    for (int yy = 1900; yy < y; yy++)
        daysFromBase += (yy%4==0 && yy%100!=0) || yy%400==0 ? 366 : 365;
    int mdays[]={31,28,31,30,31,30,31,31,30,31,30,31};
    if (((y%4==0) && (y%100!=0)) || (y%400==0)) mdays[1]=29;
    for (int mm = 1; mm < m; mm++) daysFromBase += mdays[mm-1];
    daysFromBase += d - 31;

    int lYear = 1900, lMonth = 1, lDay = 1;
    int yearDays = lunarYearDays(lYear);
    while (lYear < 2200 && daysFromBase >= yearDays) {
        daysFromBase -= yearDays;
        lYear++;
        yearDays = lunarYearDays(lYear);
    }
    int leap = lunarLeapMonth(lYear);
    while (1) {
        int monthDays = lunarMonthDays(lYear, lMonth);
        if (lMonth > 12 && daysFromBase < monthDays) break;
        if (daysFromBase < monthDays) break;
        daysFromBase -= monthDays;
        lMonth++;
        if (lMonth == leap + 1 && lMonth <= 12 && leap > 0) {
            // 跨过闰月 - 标记成闰月
        }
        if (lMonth > 13) { lYear++; lMonth = 1; leap = lunarLeapMonth(lYear); }
    }
    lDay += daysFromBase;
    if (lDay > lunarMonthDays(lYear, lMonth)) {
        lDay = lDay - lunarMonthDays(lYear, lMonth);
        lMonth++;
    }
    *ly = lYear; *lm = lMonth; *ld = lDay;
}

#pragma mark - 自定义时钟 Label
@interface SBPTimeLabel : UILabel
+ (instancetype)shared;
- (void)refresh;
- (void)refreshAnimated:(BOOL)animated;
@end

static NSTimer *gTimer = nil;

@implementation SBPTimeLabel {
    NSCalendar *_cal;
    NSDateComponents *_prev;
}
+ (instancetype)shared {
    static SBPTimeLabel *s;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ s = [SBPTimeLabel new]; });
    return s;
}
- (instancetype)init {
    if ((self = [super init])) {
        _cal = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
        _prev = nil;
        self.font = [UIFont monospacedDigitSystemFontOfSize:13 weight:UIFontWeightSemibold];
        self.textColor = [UIColor whiteColor];
        self.textAlignment = NSTextAlignmentCenter;
        self.adjustsFontSizeToFitWidth = YES;
        self.minimumScaleFactor = 0.7;
        self.numberOfLines = 2;
        [self refresh];
        if (!gTimer) {
            gTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer *_) {
                [[SBPTimeLabel shared] refreshAnimated:YES];
            }];
        }
    }
    return self;
}

- (void)refresh { [self refreshAnimated:NO]; }

- (void)refreshAnimated:(BOOL)animated {
    NSDate *now = [NSDate date];
    NSDateComponents *c = [_cal components:
        NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|
        NSCalendarUnitWeekday|NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond
        fromDate:now];

    // 时间
    BOOL use24 = [SBPGetPref(@"use24h") boolValue];
    int h = c.hour;
    if (!use24) h = h % 12 ?: 12;
    BOOL showSec = [SBPGetPref(@"showSeconds") boolValue];
    NSString *timeText = showSec
        ? [NSString stringWithFormat:@"%02d:%02d:%02d", h, c.minute, c.second]
        : [NSString stringWithFormat:@"%02d:%02d", h, c.minute];

    BOOL showDate = [SBPGetPref(@"showDate") boolValue];
    NSString *dateText = showDate
        ? [NSString stringWithFormat:@"%04d-%02d-%02d", c.year, c.month, c.day]
        : @"";

    BOOL showWeek = [SBPGetPref(@"showWeekday") boolValue];
    NSString *weekText = showWeek
        ? [NSString stringWithFormat:@"周%@", [@"日一二三四五六" substringWithRange:NSMakeRange(c.weekday-1, 1)]]
        : @"";

    BOOL showLunar = [SBPGetPref(@"showLunar") boolValue];
    NSString *lunarText = @"";
    if (showLunar) {
        int ly, lm, ld;
        solarToLunar(c.year, c.month, c.day, &ly, &lm, &ld);
        NSString *yearZ = (ly == 2024) ? @"龙" : (ly == 2025) ? @"蛇" : (ly == 2026) ? @"马" : @"";
        lunarText = [NSString stringWithFormat:@"农历%@%d月%@", yearZ, lm, chineseDay(ld)];
    }

    NSString *sep = @"  ";
    NSString *line1 = timeText;
    NSMutableArray *parts = [NSMutableArray array];
    if (dateText.length) [parts addObject:dateText];
    if (weekText.length) [parts addObject:weekText];
    if (lunarText.length) [parts addObject:lunarText];
    NSString *line2 = [parts componentsJoinedByString:sep];

    NSString *combined = line2.length
        ? [NSString stringWithFormat:@"%@\n%@", line1, line2]
        : line1;

    BOOL changed = !_prev
        || _prev.hour != c.hour || _prev.minute != c.minute || _prev.second != c.second
        || _prev.day != c.day || _prev.month != c.month || _prev.year != c.year;

    if (changed) self.text = combined;
    _prev = c;

    if (animated) {
        // 让系统自动处理 layout
    }
}

- (CGSize)intrinsicContentSize {
    NSString *t = self.text ?: @"00:00";
    CGRect r = [t boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)
                                options:NSStringDrawingUsesLineFragmentOrigin
                             attributes:@{NSFontAttributeName:self.font}
                                context:nil];
    return CGSizeMake(MAX(r.size.width, 80), MAX(r.size.height, 22));
}
@end

#pragma mark - 矢量绘图工具
static UIImage *SBPImageFromBlock(CGSize size, void(^draw)(CGContextRef)) {
    UIGraphicsBeginImageContextWithOptions(size, NO, [[UIScreen mainScreen] scale]);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    draw(ctx);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

#pragma mark - 信号图标
// 信号格式: 0..4 条 / 无服务 / 搜索中 / 飞行模式 / 0~4G 文字标记 / 双卡
static UIImage *signalImageWithBars(NSInteger bars, NSInteger style, BOOL isDual, BOOL isWifiOnly) {
    CGFloat bar_w = 3.5, gap = 1.5;
    CGFloat totalW = 4 * bar_w + 3 * gap + (isDual ? bar_w * 4 + gap * 4 + 4 : 0);
    CGFloat totalH = 10;
    CGSize size = CGSizeMake(totalW, totalH);

    UIColor *tint = [SBPGetPref(@"foregroundColor") isKindOfClass:[NSString class]]
        ? [UIColor whiteColor] : [UIColor whiteColor];

    return SBPImageFromBlock(size, ^(CGContextRef ctx) {
        CGFloat maxH = totalH;
        for (NSInteger i = 0; i < 4; i++) {
            CGFloat h = maxH * (0.3 + 0.18 * i);
            CGRect r = CGRectMake(i * (bar_w + gap), totalH - h, bar_w, h);
            CGPathRef path;
            switch (style) {
                case 1: { // 方形
                    path = [[UIBezierPath bezierPathWithRect:r] CGPath];
                    break;
                }
                case 2: { // 圆角
                    path = [[UIBezierPath bezierPathWithRoundedRect:r cornerRadius:1.2] CGPath];
                    break;
                }
                default: { // 经典 (高斯梯形)
                    CGPoint p[4] = {
                        CGPointMake(r.origin.x, totalH),
                        CGPointMake(r.origin.x, r.origin.y + 1),
                        CGPointMake(r.origin.x + bar_w, r.origin.y),
                        CGPointMake(r.origin.x + bar_w, totalH)
                    };
                    CGMutablePathRef mp = CGPathCreateMutable();
                    CGPathAddLines(mp, NULL, p, 4);
                    path = mp;
                    break;
                }
            }
            BOOL active = (i < bars) && bars > 0;
            CGContextSetFillColorWithColor(ctx, [tint colorWithAlphaComponent:active ? 1.0 : 0.18].CGColor);
            CGContextAddPath(ctx, path);
            CGContextFillPath(ctx);
        }
        if (isDual) {
            CGFloat x = 4 * (bar_w + gap) + gap + 2;
            for (NSInteger i = 0; i < 4; i++) {
                CGFloat h = maxH * (0.3 + 0.18 * i);
                CGRect r = CGRectMake(x + i * (bar_w + gap), totalH - h, bar_w, h);
                CGPathRef path = [[UIBezierPath bezierPathWithRoundedRect:r cornerRadius:1.2] CGPath];
                BOOL active = (i < bars) && bars > 0;
                CGContextSetFillColorWithColor(ctx, [tint colorWithAlphaComponent:active ? 1.0 : 0.18].CGColor);
                CGContextAddPath(ctx, path);
                CGContextFillPath(ctx);
            }
        }
    });
}

#pragma mark - WiFi 图标
static UIImage *wifiImageWithStrength(NSInteger bars, NSInteger style) {
    CGFloat w = 14, h = 11;
    CGSize size = CGSizeMake(w, h);

    return SBPImageFromBlock(size, ^(CGContextRef ctx) {
        UIColor *tint = [UIColor whiteColor];
        // 三道弧 + 中心点
        CGFloat cx = w / 2;
        CGFloat cy = h - 1.2;
        CGFloat radii[] = { 3.5, 6.5, 9.5 };
        for (NSInteger i = 0; i < 3; i++) {
            CGFloat r = radii[i];
            BOOL active = (i < bars);
            CGContextSetStrokeColorWithColor(ctx, [tint colorWithAlphaComponent:active ? 1.0 : 0.18].CGColor);
            CGContextSetLineWidth(ctx, 1.6);
            CGFloat start = -M_PI_2 - 0.55;
            CGFloat end   = -M_PI_2 + 0.55;
            CGContextAddArc(ctx, cx, cy, r, start, end, 0);
            CGContextStrokePath(ctx);
        }
        // 中心圆点
        BOOL dot = (bars >= 0);
        CGContextSetFillColorWithColor(ctx, [tint colorWithAlphaComponent:dot ? 1.0 : 0.18].CGColor);
        CGContextFillEllipseInRect(ctx, CGRectMake(cx - 1.1, cy - 1.1, 2.2, 2.2));
    });
}

#pragma mark - 电池图标
// level: 0..100, charging: BOOL, style: 0=经典 1=胶囊 2=百分号
static UIImage *batteryImageWithLevel(CGFloat level, BOOL charging, NSInteger style) {
    CGFloat w = 24, h = 11;
    CGSize size = CGSizeMake(w, h);
    UIColor *tint = [UIColor whiteColor];
    UIColor *bg   = [UIColor colorWithWhite:1 alpha:0.18];

    return SBPImageFromBlock(size, ^(CGContextRef ctx) {
        CGRect body = CGRectMake(0.5, 0.5, w - 2.5, h - 1);
        CGRect cap  = CGRectMake(w - 1.7, h * 0.3, 1.2, h * 0.4);

        // 外框
        if (style == 2) {
            // 胶囊形 (无外框,只填充)
        } else {
            CGPathRef p = [[UIBezierPath bezierPathWithRoundedRect:body cornerRadius:2.0] CGPath];
            CGContextSetStrokeColorWithColor(ctx, [tint colorWithAlphaComponent:0.4].CGColor);
            CGContextSetLineWidth(ctx, 0.8);
            CGContextAddPath(ctx, p);
            CGContextStrokePath(ctx);
            CGContextSetFillColorWithColor(ctx, bg.CGColor);
            CGContextAddPath(ctx, p);
            CGContextFillPath(ctx);
        }
        // 充电 cap
        CGContextSetFillColorWithColor(ctx, [tint colorWithAlphaComponent:0.4].CGColor);
        CGContextFillRect(ctx, cap);

        // 内填充
        CGRect inner = CGRectInset(body, 1.0, 1.0);
        inner.size.width *= MAX(0.0, MIN(1.0, level / 100.0));
        UIColor *fillColor = (level <= 20) ? [UIColor systemRedColor]
                            : (level <= 100) ? [UIColor whiteColor]
                            : [UIColor whiteColor];
        CGPathRef fill = [[UIBezierPath bezierPathWithRoundedRect:inner cornerRadius:1.0] CGPath];
        CGContextSetFillColorWithColor(ctx, fillColor.CGColor);
        CGContextAddPath(ctx, fill);
        CGContextFillPath(ctx);

        // 充电闪电
        if (charging) {
            CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);
            UIBezierPath *bolt = [UIBezierPath bezierPath];
            [bolt moveToPoint:CGPointMake(body.size.width * 0.5 - 1.2, body.size.height * 0.25)];
            [bolt addLineToPoint:CGPointMake(body.size.width * 0.5 + 0.4, body.size.height * 0.5 - 0.5)];
            [bolt addLineToPoint:CGPointMake(body.size.width * 0.5 - 0.4, body.size.height * 0.5 - 0.5)];
            [bolt addLineToPoint:CGPointMake(body.size.width * 0.5 + 1.2, body.size.height * 0.75)];
            [bolt addLineToPoint:CGPointMake(body.size.width * 0.5 - 1.0, body.size.height * 0.55)];
            [bolt addLineToPoint:CGPointMake(body.size.width * 0.5 - 0.1, body.size.height * 0.55)];
            [bolt closePath];
            CGContextAddPath(ctx, bolt.CGPath);
            CGContextFillPath(ctx);
        }
    });
}

#pragma mark - 解析 namedImageName -> 业务参数
// 真实命名格式 (iOS 15/16/17):
//   SignalStrengthBars1..4             -> 单卡 bars 1..4
//   SignalStrengthDualBars1Left..4 + 1..4Right  -> 双卡
//   SignalStrengthIndicator            -> 通用
//   SignalStrengthNoSim / NoService / Searching
//   WiFi* / DataNetwork* (cell)
//   Battery* / BatteryCharging*
static NSDictionary *parseNamedImage(NSString *name) {
    if (!name) return nil;
    if ([name hasPrefix:@"SignalStrength"]) {
        NSMutableDictionary *d = [NSMutableDictionary new];
        d[@"kind"] = @"cellular";
        BOOL dual = [name hasPrefix:@"SignalStrengthDual"];

        if ([name isEqualToString:@"SignalStrengthNoSim"] || [name hasPrefix:@"SignalStrengthNoService"]) {
            d[@"state"] = @"nosim";
        } else if ([name hasPrefix:@"SignalStrengthSearching"]) {
            d[@"state"] = @"searching";
        } else if ([name containsString:@"AirplaneMode"]) {
            d[@"state"] = @"airplane";
        } else {
            d[@"state"] = @"active";
        }

        // 单卡: SignalStrengthBars4
        NSRegularExpression *r1 = [NSRegularExpression regularExpressionWithPattern:@"Bars(\\d)" options:0 error:nil];
        NSTextCheckingResult *m1 = [r1 firstMatchInString:name options:0 range:NSMakeRange(0, name.length)];
        if (m1) d[@"bars"] = @([name substringWithRange:[m1 rangeAtIndex:1]].intValue);

        if (dual) {
            NSRegularExpression *r2 = [NSRegularExpression regularExpressionWithPattern:@"Left(\\d)|Right(\\d)" options:0 error:nil];
            NSTextCheckingResult *m2 = [r2 firstMatchInString:name options:0 range:NSMakeRange(0, name.length)];
            if (m2) d[@"bars"] = @([[name substringWithRange:[m2 rangeAtIndex:1] ?: [m2 rangeAtIndex:2]].intValue);
        }
        return d;
    }
    if ([name hasPrefix:@"WiFi"] || [name containsString:@"WiFiCall"] || [name containsString:@"DataNetwork"]) {
        NSMutableDictionary *d = [NSMutableDictionary new];
        d[@"kind"] = @"wifi";
        d[@"state"] = @"active";
        if ([name hasPrefix:@"WiFiSearching"]) d[@"state"] = @"searching";
        if ([name hasPrefix:@"WiFiNotConnected"]) d[@"state"] = @"inactive";
        if ([name containsString:@"0bars"] || [name containsString:@"NotConnected"]) d[@"bars"] = @0;
        if ([name containsString:@"1bars"] || [name containsString:@"Low"]) d[@"bars"] = @1;
        if ([name containsString:@"2bars"] || [name containsString:@"Med"]) d[@"bars"] = @2;
        if ([name containsString:@"3bars"] || [name containsString:@"High"]) d[@"bars"] = @3;
        return d;
    }
    if ([name hasPrefix:@"Battery"] || [name containsString:@"Battery"]) {
        NSMutableDictionary *d = [NSMutableDictionary new];
        d[@"kind"] = @"battery";
        BOOL charging = [name containsString:@"Charging"];
        d[@"charging"] = @(charging);
        NSRegularExpression *r = [NSRegularExpression regularExpressionWithPattern:@"(\\d{1,3})" options:0 error:nil];
        NSTextCheckingResult *m = [r firstMatchInString:name options:0 range:NSMakeRange(0, name.length)];
        if (m) d[@"level"] = @([name substringWithRange:m.range].intValue);
        return d;
    }
    return nil;
}

#pragma mark - 状态栏样式 / 颜色
static void applyColorOverrides() {
    UIColor *fg = [UIColor whiteColor];
    NSString *hex = SBPGetPref(@"foregroundColor");
    if ([hex isKindOfClass:[NSString class]] && hex.length > 0) {
        unsigned int v = 0;
        [[NSScanner scannerWithString:hex] scanHexInt:&v];
        fg = [UIColor colorWithRed:((v>>16)&0xFF)/255.0 green:((v>>8)&0xFF)/255.0 blue:(v&0xFF)/255.0 alpha:1.0];
    }

    UIStatusBarStyleRequest *req = [NSClassFromString(@"UIStatusBarStyleRequest") new];
    req.foregroundColor = fg;
    req.backgroundColor = [UIColor clearColor];
    if ([req respondsToSelector:@selector(setStyle:)]) req.style = 0;

    NSDictionary *overrides = SBP_iOS17OrLater()
        ? @{@"StyleOverrideRequests":[NSMutableArray arrayWithObject:req],
            @"InterfaceStyleOverrideAvailable":@YES,
            @"StatusBarStyleOverridesLockupKey":[NSNumber numberWithInt:0]}
        : @{@"StyleOverrideRequests":[NSMutableArray arrayWithObject:req]};

    [[UIStatusBarServer sharedStatusBarServer] postStatusBarStyleOverrides:overrides];
}

#pragma mark - Hooks

// 1) 时间视图: iOS 15/16 直接 hook UIStatusBarTimeItemView
//    iOS 17 引入了 UIStatusBarTimeContainerView 包裹, 同时 hook
%group SBPLegacyTime
%hook UIStatusBarTimeItemView
%new(v@:@)
- (void)sbpinstallTimeLabel {
    SBPTimeLabel *lbl = [SBPTimeLabel shared];
    if (!lbl.superview) [self addSubview:lbl];
    lbl.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [lbl.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [lbl.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [lbl.topAnchor constraintEqualToAnchor:self.topAnchor],
        [lbl.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
    ]];
}
%new(v@:{CGSize=dd})
- (CGSize)sizeThatFits:(CGSize)size {
    return [[SBPTimeLabel shared] intrinsicContentSize];
}
%end
%end

// iOS 17 新增 UIStatusBarTimeContainerView, 包裹一个 UIStatusBarTimeItemView
%group SBPNewTime
%hook UIStatusBarTimeContainerView
%new(v@:@)
- (void)sbpinstallTimeLabel {
    UIView *child = [self performSelector:@selector(timeView)]; // UIStatusBarTimeItemView
    if ([child isKindOfClass:[UIView class]]) {
        SBPTimeLabel *lbl = [SBPTimeLabel shared];
        if (!lbl.superview) [child addSubview:lbl];
        lbl.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[
            [lbl.leadingAnchor constraintEqualToAnchor:child.leadingAnchor],
            [lbl.trailingAnchor constraintEqualToAnchor:child.trailingAnchor],
            [lbl.topAnchor constraintEqualToAnchor:child.topAnchor],
            [lbl.bottomAnchor constraintEqualToAnchor:child.bottomAnchor],
        ]];
    }
}
%end
%end

// 2) 图标重绘 (所有版本通用)
%group SBPIcons
%hook UIStatusBarImageView
- (UIImage *)image {
    NSString *name = self.namedImageName ?: @"";
    NSInteger sigStyle = [SBPGetPref(@"signalStyle") integerValue];
    NSInteger wifiStyle = 0;
    NSInteger battStyle = [SBPGetPref(@"batteryStyle") integerValue];

    NSDictionary *parsed = parseNamedImage(name);
    if (!parsed) return %orig;
    NSString *kind = parsed[@"kind"];
    if ([kind isEqualToString:@"cellular"]) {
        NSInteger bars = [parsed[@"bars"] integerValue];
        BOOL dual = [name hasPrefix:@"SignalStrengthDual"];
        return signalImageWithBars(bars, sigStyle, dual, NO);
    }
    if ([kind isEqualToString:@"wifi"]) {
        NSInteger bars = [parsed[@"bars"] integerValue];
        return wifiImageWithStrength(bars, wifiStyle);
    }
    if ([kind isEqualToString:@"battery"]) {
        CGFloat level = [parsed[@"level"] doubleValue];
        BOOL charging = [parsed[@"charging"] boolValue];
        return batteryImageWithLevel(level, charging, battStyle);
    }
    return %orig;
}
%end
%end // SBPIcons

// 3) 状态栏高度 (iOS 17 改 pixel layout)
// iOS 15/16: UIStatusBar setFrame
// iOS 17:    不再使用 frame layout, 改 sizeThatFits override
%group SBP15_16
%hook UIStatusBar
- (void)setFrame:(CGRect)frame {
    CGFloat extra = [SBPGetPref(@"barExtraHeight") doubleValue];
    if (extra > 0) frame.size.height += extra;
    %orig(frame);
}
%end
%end

// 4) prefs 变化回调
static void reloadPrefs() {
    applyColorOverrides();
    [[SBPTimeLabel shared] refresh];
}

%ctor {
    // 图标 hook 在所有版本启用
    %init(SBPIcons);

    // 按系统版本启用不同 group
    if (SBP_iOS17OrLater()) {
        %init(SBPNewTime);
    } else {
        %init(SBPLegacyTime);
        %init(SBP15_16);
    }

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserverForName:@"com.muzikeji.statusbarprefschanged" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *_) {
        reloadPrefs();
    }];
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
        NULL,
        (CFNotificationCallback)(void (*)(CFNotificationCenterRef, void *, CFStringRef, const void *, CFDictionaryRef))&reloadPrefs,
        (CFStringRef)@"com.muzikeji.statusbarprefschanged",
        NULL,
        CFNotificationSuspensionBehaviorDeliverImmediately);

    applyColorOverrides();
}