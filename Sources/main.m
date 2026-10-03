#import <AppKit/AppKit.h>
#import <WebKit/WebKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <dlfcn.h>
#import <math.h>

static NSString * const TGHomeURL = @"https://t66y.com";
static NSString * const TGBridgeName = @"tonyBridge";
static NSString * const TGVidCatchEndpoint = @"http://127.0.0.1:17368";
static NSString * const TGVidCatchToken = @"vsl_4fd6bdb89fcd4d40a6e724f94908213e";

static void TGSendObject(id receiver, SEL selector, id value) {
    ((void (*)(id, SEL, id))objc_msgSend)(receiver, selector, value);
}

static id TGGetObject(id receiver, SEL selector) {
    return ((id (*)(id, SEL))objc_msgSend)(receiver, selector);
}

static void TGSendDouble(id receiver, SEL selector, double value) {
    ((void (*)(id, SEL, double))objc_msgSend)(receiver, selector, value);
}

static double TGGetDouble(id receiver, SEL selector) {
    return ((double (*)(id, SEL))objc_msgSend)(receiver, selector);
}

static void TGSendBool(id receiver, SEL selector, BOOL value) {
    ((void (*)(id, SEL, BOOL))objc_msgSend)(receiver, selector, value);
}

static id TGImageNamed(NSString *name) {
    return [NSImage imageNamed:name];
}

static id TGCreateTouchBarButton(
    Class buttonItemClass,
    NSString *identifier,
    id image,
    id target,
    SEL action
) {
    SEL selector = NSSelectorFromString(@"buttonTouchBarItemWithIdentifier:image:target:action:");
    return ((id (*)(id, SEL, id, id, id, SEL))objc_msgSend)(
        buttonItemClass,
        selector,
        identifier,
        image,
        target,
        action
    );
}

static BOOL TGLoadMacAVKit(void) {
    static void *avKitHandle;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        avKitHandle = dlopen(
            "/System/Library/Frameworks/AVKit.framework/AVKit",
            RTLD_LAZY | RTLD_LOCAL
        );
    });
    return avKitHandle != NULL &&
        NSClassFromString(@"AVTouchBarPlaybackControlsProvider") != Nil &&
        NSClassFromString(@"AVValueTiming") != Nil;
}

@interface TGFlippedView : NSView
@end

@implementation TGFlippedView
- (BOOL)isFlipped {
    return YES;
}
@end

@interface TGForumRowView : TGFlippedView
@property(nonatomic, strong) NSImageView *forumIcon;
@property(nonatomic, strong) NSTextField *forumTitle;
@property(nonatomic, strong) NSTextField *forumSubtitle;
@property(nonatomic, strong) NSBox *separator;
@end

@implementation TGForumRowView
@end

@interface TGAppDelegate : NSObject
    <NSApplicationDelegate, NSWindowDelegate, WKNavigationDelegate, WKUIDelegate,
     WKScriptMessageHandler, WKDownloadDelegate>

@property(nonatomic, strong) NSWindow *window;
@property(nonatomic, strong) WKWebView *webView;
@property(nonatomic, strong) NSTextField *addressField;
@property(nonatomic, strong) NSTextField *statusLabel;
@property(nonatomic, strong) NSProgressIndicator *progressIndicator;
@property(nonatomic, strong) NSButton *backButton;
@property(nonatomic, strong) NSButton *forwardButton;
@property(nonatomic, strong) NSButton *reloadButton;
@property(nonatomic, strong) NSButton *favoriteButton;
@property(nonatomic, strong) NSScrollView *sidebarScrollView;
@property(nonatomic, strong) NSLayoutConstraint *sidebarWidthConstraint;
@property(nonatomic, strong) NSMutableArray<NSString *> *sidebarRoutes;
@property(nonatomic) BOOL sidebarVisible;
@property(nonatomic, strong) NSScrollView *classicHomeView;
@property(nonatomic, strong) NSView *classicTopBar;
@property(nonatomic, strong) NSView *classicBottomBar;
@property(nonatomic, strong) NSLayoutConstraint *classicTopBarHeightConstraint;
@property(nonatomic, strong) NSLayoutConstraint *classicBottomBarHeightConstraint;
@property(nonatomic, strong) NSTextField *classicTitleLabel;
@property(nonatomic, strong) NSButton *nightModeButton;
@property(nonatomic, copy) NSArray<NSButton *> *rootTabButtons;
@property(nonatomic, copy) NSArray<NSArray<NSString *> *> *rootTabImageNames;
@property(nonatomic, strong) NSMutableArray<TGForumRowView *> *forumRows;
@property(nonatomic, strong) NSMutableArray<NSTextField *> *forumSectionLabels;
@property(nonatomic, strong) NSTextField *statusBarClock;
@property(nonatomic) NSInteger selectedRootTab;
@property(nonatomic) NSInteger nightModeSelection;
@property(nonatomic) BOOL showingClassicHome;

@property(nonatomic) BOOL paused;
@property(nonatomic) BOOL pictureInPicture;
@property(nonatomic) BOOL pictureInPictureAvailable;
@property(nonatomic) BOOL fullscreen;
@property(nonatomic) NSTimeInterval elapsed;
@property(nonatomic) NSTimeInterval duration;
@property(nonatomic, copy) NSString *title;
@property(nonatomic, strong) WKFrameInfo *mediaFrame;
@property(nonatomic) BOOL mediaCinemaFullscreen;
@property(nonatomic) NSUInteger mediaFullscreenRequestGeneration;

@property(nonatomic, strong) id touchBar;
@property(nonatomic, strong) id touchBarProvider;
@property(nonatomic, strong) id timing;
@property(nonatomic, copy) NSArray *seekableTimeRanges;
@property(nonatomic) double defaultPlaybackRate;
@property(nonatomic) float rate;
@property(nonatomic, strong) id touchBarSliderItem;
@property(nonatomic, strong) id touchBarSlider;
@property(nonatomic, strong) id touchBarPlayPauseItem;
@property(nonatomic, strong) id touchBarPictureInPictureItem;
@property(nonatomic, strong) id touchBarFullscreenItem;
@property(nonatomic, strong) id touchBarExitFullscreenItem;
@property(nonatomic, strong) id previousTouchBar;
@property(nonatomic, weak) NSWindow *touchBarHostWindow;
@property(nonatomic, strong) id touchBarHostPreviousTouchBar;
@property(nonatomic, weak) NSResponder *touchBarHostResponder;
@property(nonatomic, strong) id touchBarHostResponderPreviousTouchBar;

@property(nonatomic, strong) NSURLSession *vidCatchSession;
@property(nonatomic, copy) NSString *vidCatchJobID;

- (void)refreshAVKitTimingWithRate:(double)rate;
- (void)installRemoteCommands;
- (void)installTouchBarIfNeeded;
- (NSWindow *)activeTouchBarHostWindow;
- (void)ensureTouchBarAttached;
- (void)refreshTouchBarPresentation;
- (void)updateSafariEscapeKey;
- (void)clearMediaControls;

@end

@implementation TGAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    (void)notification;
    self.paused = YES;
    self.title = @"小草视频";
    self.defaultPlaybackRate = 1.0;
    self.rate = 1.0f;
    self.seekableTimeRanges = @[];
    [self installRemoteCommands];

    NSURLSessionConfiguration *sessionConfiguration = NSURLSessionConfiguration.ephemeralSessionConfiguration;
    sessionConfiguration.timeoutIntervalForRequest = 15.0;
    sessionConfiguration.timeoutIntervalForResource = 45.0;
    self.vidCatchSession = [NSURLSession sessionWithConfiguration:sessionConfiguration];

    [self installMainMenu];
    [self installApplicationIcon];
    [self buildWindow];

    [NSApp activateIgnoringOtherApps:YES];
    [self.window makeKeyAndOrderFront:nil];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    (void)sender;
    return YES;
}

- (void)installMainMenu {
    NSMenu *mainMenu = [[NSMenu alloc] initWithTitle:@"Main"];

    NSMenuItem *applicationItem = [[NSMenuItem alloc] initWithTitle:@"App"
                                                            action:nil
                                                     keyEquivalent:@""];
    NSMenu *applicationMenu = [[NSMenu alloc] initWithTitle:@"小草 Mac 浏览器"];
    [applicationMenu addItemWithTitle:@"关于小草 Mac 浏览器"
                               action:@selector(orderFrontStandardAboutPanel:)
                        keyEquivalent:@""];
    [applicationMenu addItem:[NSMenuItem separatorItem]];
    [applicationMenu addItemWithTitle:@"退出小草 Mac 浏览器"
                               action:@selector(terminate:)
                        keyEquivalent:@"q"];
    applicationItem.submenu = applicationMenu;
    [mainMenu addItem:applicationItem];

    NSMenuItem *editItem = [[NSMenuItem alloc] initWithTitle:@"Edit" action:nil keyEquivalent:@""];
    NSMenu *editMenu = [[NSMenu alloc] initWithTitle:@"编辑"];
    [editMenu addItemWithTitle:@"撤销" action:@selector(undo:) keyEquivalent:@"z"];
    [editMenu addItemWithTitle:@"重做" action:@selector(redo:) keyEquivalent:@"Z"];
    [editMenu addItem:[NSMenuItem separatorItem]];
    [editMenu addItemWithTitle:@"剪切" action:@selector(cut:) keyEquivalent:@"x"];
    [editMenu addItemWithTitle:@"复制" action:@selector(copy:) keyEquivalent:@"c"];
    [editMenu addItemWithTitle:@"粘贴" action:@selector(paste:) keyEquivalent:@"v"];
    [editMenu addItemWithTitle:@"全选" action:@selector(selectAll:) keyEquivalent:@"a"];
    editItem.submenu = editMenu;
    [mainMenu addItem:editItem];

    NSMenuItem *navigationItem = [[NSMenuItem alloc] initWithTitle:@"Navigate"
                                                            action:nil
                                                     keyEquivalent:@""];
    NSMenu *navigationMenu = [[NSMenu alloc] initWithTitle:@"浏览"];
    NSMenuItem *location = [navigationMenu addItemWithTitle:@"打开位置…"
                                                     action:@selector(focusLocation:)
                                              keyEquivalent:@"l"];
    location.target = self;
    NSMenuItem *reload = [navigationMenu addItemWithTitle:@"重新载入"
                                                   action:@selector(reloadPage:)
                                            keyEquivalent:@"r"];
    reload.target = self;
    NSMenuItem *back = [navigationMenu addItemWithTitle:@"后退"
                                                 action:@selector(goBack:)
                                          keyEquivalent:@"["];
    back.target = self;
    NSMenuItem *forward = [navigationMenu addItemWithTitle:@"前进"
                                                    action:@selector(goForward:)
                                             keyEquivalent:@"]"];
    forward.target = self;
    [navigationMenu addItem:[NSMenuItem separatorItem]];
    NSMenuItem *videoFullScreen = [navigationMenu addItemWithTitle:@"视频全屏 / 退出视频全屏"
                                                            action:@selector(toggleMediaFullscreen:)
                                                     keyEquivalent:@""];
    videoFullScreen.target = self;
    NSMenuItem *fullScreen = [navigationMenu addItemWithTitle:@"进入全屏幕"
                                                       action:@selector(toggleWindowFullscreen:)
                                                keyEquivalent:@"f"];
    fullScreen.keyEquivalentModifierMask = NSEventModifierFlagControl | NSEventModifierFlagCommand;
    fullScreen.target = self;
    navigationItem.submenu = navigationMenu;
    [mainMenu addItem:navigationItem];

    NSApp.mainMenu = mainMenu;
}

- (void)installApplicationIcon {
    NSString *path = [NSBundle.mainBundle pathForResource:@"AppIcon" ofType:@"icns"];
    NSImage *icon = path.length > 0 ? [[NSImage alloc] initWithContentsOfFile:path] : nil;
    if (icon != nil) NSApp.applicationIconImage = icon;
}

- (NSButton *)toolbarButtonWithSymbol:(NSString *)symbol
                               label:(NSString *)label
                              action:(SEL)action {
    NSButton *button = [NSButton buttonWithTitle:label target:self action:action];
    if (@available(macOS 11.0, *)) {
        NSImage *image = [NSImage imageWithSystemSymbolName:symbol accessibilityDescription:label];
        if (image != nil) {
            button.image = image;
            button.title = @"";
            button.imagePosition = NSImageOnly;
        }
    }
    button.bezelStyle = NSBezelStyleTexturedRounded;
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button.widthAnchor constraintEqualToConstant:34].active = YES;
    [button.heightAnchor constraintEqualToConstant:30].active = YES;
    button.toolTip = label;
    return button;
}

- (NSButton *)sidebarButtonWithTitle:(NSString *)title
                              symbol:(NSString *)symbol
                               route:(NSString *)route {
    NSButton *button = [NSButton buttonWithTitle:title target:self action:@selector(openSidebarRoute:)];
    button.bezelStyle = NSBezelStyleAccessoryBarAction;
    button.alignment = NSTextAlignmentLeft;
    button.font = [NSFont systemFontOfSize:13.0 weight:NSFontWeightMedium];
    button.contentTintColor = NSColor.labelColor;
    button.translatesAutoresizingMaskIntoConstraints = NO;
    if (@available(macOS 11.0, *)) {
        NSImage *image = [NSImage imageWithSystemSymbolName:symbol accessibilityDescription:title];
        if (image != nil) {
            button.image = image;
            button.imagePosition = NSImageLeading;
        }
    }
    button.tag = (NSInteger)self.sidebarRoutes.count;
    [self.sidebarRoutes addObject:route];
    [button.heightAnchor constraintEqualToConstant:34].active = YES;
    return button;
}

- (NSTextField *)sidebarHeading:(NSString *)title {
    NSTextField *label = [NSTextField labelWithString:title];
    label.font = [NSFont systemFontOfSize:11.0 weight:NSFontWeightSemibold];
    label.textColor = NSColor.secondaryLabelColor;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    return label;
}

- (NSScrollView *)buildSidebar {
    self.sidebarRoutes = [NSMutableArray array];
    self.sidebarVisible = YES;

    NSStackView *stack = [[NSStackView alloc] initWithFrame:NSZeroRect];
    stack.orientation = NSUserInterfaceLayoutOrientationVertical;
    stack.alignment = NSLayoutAttributeLeading;
    stack.spacing = 5.0;
    stack.edgeInsets = NSEdgeInsetsMake(14, 10, 18, 10);
    stack.translatesAutoresizingMaskIntoConstraints = NO;

    NSTextField *brand = [NSTextField labelWithString:@"小草 Mac"];
    brand.font = [NSFont systemFontOfSize:18.0 weight:NSFontWeightBold];
    brand.textColor = [NSColor colorWithCalibratedRed:0.08 green:0.48 blue:0.29 alpha:1.0];
    [stack addArrangedSubview:brand];
    [stack setCustomSpacing:12 afterView:brand];

    NSArray<NSArray<NSString *> *> *primary = @[
        @[@"首页", @"house.fill", @"https://t66y.com/index.php"],
        @[@"发现", @"safari.fill", @"https://t66y.com/thread0806.php?fid=7"],
        @[@"收藏", @"star.fill", @"internal:favorites"],
        @[@"历史", @"clock.fill", @"internal:history"],
        @[@"登录 / 我的", @"person.crop.circle", @"https://t66y.com/login.php"],
        @[@"设置说明", @"gearshape.fill", @"internal:settings"]
    ];
    for (NSArray<NSString *> *item in primary) {
        NSButton *button = [self sidebarButtonWithTitle:item[0] symbol:item[1] route:item[2]];
        [stack addArrangedSubview:button];
        [button.widthAnchor constraintEqualToConstant:208].active = YES;
    }

    [stack setCustomSpacing:14 afterView:stack.arrangedSubviews.lastObject];
    [stack addArrangedSubview:[self sidebarHeading:@"社区版块"]];

    NSArray<NSArray<NSString *> *> *forums = @[
        @[@"技术讨论区", @"7"], @[@"新时代的我们", @"8"],
        @[@"达盖尔的旗帜", @"16"], @[@"成人文学交流区", @"20"],
        @[@"博彩区", @"23"], @[@"亚洲无码原创区", @"2"],
        @[@"亚洲有码原创区", @"15"], @[@"欧美原创区", @"4"],
        @[@"动漫原创区", @"5"], @[@"国产原创区", @"25"],
        @[@"中字原创区", @"26"], @[@"AI 破解原创区", @"28"],
        @[@"综合分享区", @"27"], @[@"HTTP 下载区", @"21"],
        @[@"在线成人影院", @"22"], @[@"草榴资讯", @"9"]
    ];
    for (NSArray<NSString *> *item in forums) {
        NSString *route = [NSString stringWithFormat:@"https://t66y.com/thread0806.php?fid=%@", item[1]];
        NSButton *button = [self sidebarButtonWithTitle:item[0] symbol:@"rectangle.stack" route:route];
        button.font = [NSFont systemFontOfSize:12.5];
        [stack addArrangedSubview:button];
        [button.widthAnchor constraintEqualToConstant:208].active = YES;
    }

    TGFlippedView *document = [[TGFlippedView alloc] initWithFrame:NSZeroRect];
    document.translatesAutoresizingMaskIntoConstraints = NO;
    [document addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:document.leadingAnchor],
        [stack.trailingAnchor constraintEqualToAnchor:document.trailingAnchor],
        [stack.topAnchor constraintEqualToAnchor:document.topAnchor],
        [stack.bottomAnchor constraintEqualToAnchor:document.bottomAnchor],
        [document.widthAnchor constraintEqualToConstant:228]
    ]];

    NSScrollView *scroll = [[NSScrollView alloc] initWithFrame:NSZeroRect];
    scroll.documentView = document;
    scroll.hasVerticalScroller = YES;
    scroll.drawsBackground = YES;
    scroll.backgroundColor = NSColor.controlBackgroundColor;
    scroll.autohidesScrollers = YES;
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    return scroll;
}

- (NSImage *)iOSImageNamed:(NSString *)name size:(NSSize)size template:(BOOL)isTemplate {
    NSString *path = [NSBundle.mainBundle pathForResource:name ofType:@"png" inDirectory:@"IOSUI"];
    NSImage *image = path.length > 0 ? [[NSImage alloc] initWithContentsOfFile:path] : nil;
    if (image != nil) {
        image.size = size;
        image.template = isTemplate;
    }
    return image;
}

- (BOOL)iOSDarkMode {
    NSString *name = [self.window.effectiveAppearance bestMatchFromAppearancesWithNames:@[
        NSAppearanceNameAqua, NSAppearanceNameDarkAqua
    ]];
    return [name isEqualToString:NSAppearanceNameDarkAqua];
}

- (NSTextField *)classicSectionLabel:(NSString *)title {
    NSTextField *label = [NSTextField labelWithString:[NSString stringWithFormat:@"  %@", title]];
    label.font = [NSFont systemFontOfSize:12.0 weight:NSFontWeightRegular];
    label.alignment = NSTextAlignmentLeft;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [label.heightAnchor constraintEqualToConstant:19.0].active = YES;
    [self.forumSectionLabels addObject:label];
    return label;
}

- (NSView *)classicRowWithTitle:(NSString *)title
                       subtitle:(NSString *)subtitle
                          asset:(NSString *)assetName
                          route:(NSString *)route {
    TGForumRowView *row = [[TGForumRowView alloc] initWithFrame:NSZeroRect];
    row.translatesAutoresizingMaskIntoConstraints = NO;
    row.wantsLayer = YES;

    NSImageView *icon = [[NSImageView alloc] initWithFrame:NSZeroRect];
    icon.image = [self iOSImageNamed:assetName size:NSMakeSize(60, 60) template:YES];
    icon.imageScaling = NSImageScaleProportionallyUpOrDown;
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    row.forumIcon = icon;
    [row addSubview:icon];

    NSTextField *titleLabel = [NSTextField labelWithString:title];
    titleLabel.font = [NSFont systemFontOfSize:17.0 weight:NSFontWeightRegular];
    titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    row.forumTitle = titleLabel;
    [row addSubview:titleLabel];

    NSTextField *subtitleLabel = [NSTextField wrappingLabelWithString:subtitle ?: @""];
    subtitleLabel.font = [NSFont systemFontOfSize:14.0 weight:NSFontWeightRegular];
    subtitleLabel.maximumNumberOfLines = 2;
    subtitleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    row.forumSubtitle = subtitleLabel;
    [row addSubview:subtitleLabel];

    NSBox *separator = [[NSBox alloc] initWithFrame:NSZeroRect];
    separator.boxType = NSBoxSeparator;
    separator.translatesAutoresizingMaskIntoConstraints = NO;
    row.separator = separator;
    [row addSubview:separator];

    NSButton *hitTarget = [NSButton buttonWithTitle:@"" target:self action:@selector(openSidebarRoute:)];
    hitTarget.bordered = NO;
    hitTarget.tag = (NSInteger)self.sidebarRoutes.count;
    hitTarget.toolTip = title;
    hitTarget.translatesAutoresizingMaskIntoConstraints = NO;
    [self.sidebarRoutes addObject:route];
    [row addSubview:hitTarget];

    [NSLayoutConstraint activateConstraints:@[
        [row.heightAnchor constraintEqualToConstant:82.0],
        [icon.leadingAnchor constraintEqualToAnchor:row.leadingAnchor constant:10.0],
        [icon.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],
        [icon.widthAnchor constraintEqualToConstant:60.0],
        [icon.heightAnchor constraintEqualToConstant:60.0],
        [titleLabel.leadingAnchor constraintEqualToAnchor:row.leadingAnchor constant:80.0],
        [titleLabel.trailingAnchor constraintEqualToAnchor:row.trailingAnchor constant:-8.0],
        [titleLabel.topAnchor constraintEqualToAnchor:row.topAnchor constant:15.0],
        [titleLabel.heightAnchor constraintEqualToConstant:22.0],
        [subtitleLabel.leadingAnchor constraintEqualToAnchor:row.leadingAnchor constant:80.0],
        [subtitleLabel.trailingAnchor constraintEqualToAnchor:row.trailingAnchor constant:-8.0],
        [subtitleLabel.topAnchor constraintEqualToAnchor:row.topAnchor constant:39.0],
        [subtitleLabel.bottomAnchor constraintLessThanOrEqualToAnchor:row.bottomAnchor constant:-6.0],
        [separator.leadingAnchor constraintEqualToAnchor:row.leadingAnchor constant:8.0],
        [separator.trailingAnchor constraintEqualToAnchor:row.trailingAnchor],
        [separator.bottomAnchor constraintEqualToAnchor:row.bottomAnchor],
        [hitTarget.leadingAnchor constraintEqualToAnchor:row.leadingAnchor],
        [hitTarget.trailingAnchor constraintEqualToAnchor:row.trailingAnchor],
        [hitTarget.topAnchor constraintEqualToAnchor:row.topAnchor],
        [hitTarget.bottomAnchor constraintEqualToAnchor:row.bottomAnchor]
    ]];

    [self.forumRows addObject:row];
    return row;
}

- (NSScrollView *)buildClassicHome {
    self.sidebarRoutes = [NSMutableArray array];
    self.forumRows = [NSMutableArray array];
    self.forumSectionLabels = [NSMutableArray array];
    NSStackView *stack = [[NSStackView alloc] initWithFrame:NSZeroRect];
    stack.orientation = NSUserInterfaceLayoutOrientationVertical;
    stack.alignment = NSLayoutAttributeLeading;
    stack.spacing = 0;
    stack.edgeInsets = NSEdgeInsetsZero;
    stack.translatesAutoresizingMaskIntoConstraints = NO;

    NSArray<NSDictionary *> *groups = @[
        @{
            @"title": @"休閑區",
            @"rows": @[
                @[@"技術討論區", @"日常生活 興趣交流 時事經濟 求助求檔 會員閑談吹水區", @"f7", @"7"],
                @[@"新時代的我們", @"草榴貼圖區 加大你的帶寬! 加大你的內存! 加大你的顯示器! ", @"f8", @"8"],
                @[@"達蓋爾的旗幟", @"草榴自拍區 分享你我光圈下的最美", @"f16", @"16"],
                @[@"成人文學交流區", @"草榴文學區 歡迎各位發表", @"f20", @"20"],
                @[@"博彩區", @"草榴博彩區 積分認證板塊", @"f23", @"23"]
            ]
        },
        @{
            @"title": @"BT電影下載",
            @"rows": @[
                @[@"亞洲無碼原創區", @"自由發布亞洲最新無修正資訊片 亞洲無碼AV大聯盟", @"f2", @"2"],
                @[@"亞洲有碼原創區", @"自由發布亞洲最新有修正資訊片", @"f15", @"15"],
                @[@"歐美原創區", @"自由發布純正的歐美成人資訊片", @"f4", @"4"],
                @[@"動漫原創區", @"自由發布任何H動畫漫畫", @"f5", @"5"],
                @[@"國產原創區", @"自由發布純正的國產成人，三級資訊片", @"f25", @"25"],
                @[@"中字原創區", @"自由發布各類中文字幕成人資訊片", @"f26", @"26"],
                @[@"AI破解原創區", @"自由發布任何AI破解資訊片", @"f28", @"28"],
                @[@"綜合分享區", @"最新資訊，網友分享，搶先登場", @"f27", @"27"],
                @[@"HTTP下載區", @"自由發布各類HTTP/Ray/eMule等方式下載", @"f21", @"21"],
                @[@"在綫成人影院", @"在綫欣賞，即點即看", @"f22", @"22"],
                @[@"草榴資訊", @"公告有關本站最新動向 會員須知 請經常來看看", @"f9", @"9"]
            ]
        }
    ];

    for (NSDictionary *group in groups) {
        NSTextField *heading = [self classicSectionLabel:group[@"title"]];
        [stack addArrangedSubview:heading];
        NSArray<NSArray<NSString *> *> *rows = group[@"rows"];
        for (NSArray<NSString *> *row in rows) {
            NSString *route = [NSString stringWithFormat:@"https://t66y.com/thread0806.php?fid=%@", row[3]];
            NSView *forumRow = [self classicRowWithTitle:row[0] subtitle:row[1] asset:row[2] route:route];
            [stack addArrangedSubview:forumRow];
            [forumRow.widthAnchor constraintEqualToAnchor:stack.widthAnchor].active = YES;
        }
    }

    TGFlippedView *document = [[TGFlippedView alloc] initWithFrame:NSZeroRect];
    document.translatesAutoresizingMaskIntoConstraints = NO;
    [document addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:document.leadingAnchor],
        [stack.trailingAnchor constraintEqualToAnchor:document.trailingAnchor],
        [stack.topAnchor constraintEqualToAnchor:document.topAnchor],
        [stack.bottomAnchor constraintEqualToAnchor:document.bottomAnchor]
    ]];

    NSScrollView *scroll = [[NSScrollView alloc] initWithFrame:NSZeroRect];
    scroll.documentView = document;
    scroll.hasVerticalScroller = YES;
    scroll.autohidesScrollers = YES;
    scroll.drawsBackground = YES;
    scroll.backgroundColor = NSColor.controlBackgroundColor;
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    [document.widthAnchor constraintEqualToAnchor:scroll.contentView.widthAnchor].active = YES;
    return scroll;
}

- (NSButton *)rootTabButtonWithTitle:(NSString *)title image:(NSString *)imageName tag:(NSInteger)tag {
    NSButton *button = [NSButton buttonWithTitle:title target:self action:@selector(selectRootTab:)];
    button.tag = tag;
    button.bordered = NO;
    button.font = [NSFont systemFontOfSize:10.0 weight:NSFontWeightRegular];
    button.imagePosition = NSImageAbove;
    button.imageScaling = NSImageScaleProportionallyDown;
    button.image = [self iOSImageNamed:imageName size:NSMakeSize(25, 25) template:YES];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    return button;
}

- (NSButton *)iOSToolbarButtonWithAsset:(NSString *)assetName
                                   label:(NSString *)label
                                  action:(SEL)action {
    NSButton *button = [NSButton buttonWithTitle:@"" target:self action:action];
    button.bordered = NO;
    button.image = [self iOSImageNamed:assetName size:NSMakeSize(24, 24) template:YES];
    button.imagePosition = NSImageOnly;
    button.imageScaling = NSImageScaleProportionallyDown;
    button.toolTip = label;
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button.widthAnchor constraintEqualToConstant:36.0].active = YES;
    [button.heightAnchor constraintEqualToConstant:36.0].active = YES;
    return button;
}

- (void)buildWindow {
    NSRect frame = NSMakeRect(0, 0, 554, 720);
    NSWindowStyleMask style = NSWindowStyleMaskTitled |
        NSWindowStyleMaskClosable |
        NSWindowStyleMaskMiniaturizable |
        NSWindowStyleMaskResizable;
    self.window = [[NSWindow alloc] initWithContentRect:frame
                                             styleMask:style
                                               backing:NSBackingStoreBuffered
                                                 defer:NO];
    self.window.title = @"小草";
    self.window.delegate = self;
    self.window.minSize = NSMakeSize(430, 560);
    [self.window center];

    NSView *content = [[NSView alloc] initWithFrame:frame];
    content.translatesAutoresizingMaskIntoConstraints = NO;
    self.window.contentView = content;

    NSView *topBar = [[NSView alloc] initWithFrame:NSZeroRect];
    topBar.wantsLayer = YES;
    topBar.translatesAutoresizingMaskIntoConstraints = NO;
    self.classicTopBar = topBar;
    [content addSubview:topBar];

    self.backButton = [self iOSToolbarButtonWithAsset:@"button-back" label:@"返回" action:@selector(goBack:)];
    self.favoriteButton = [self iOSToolbarButtonWithAsset:@"button-menu" label:@"菜单" action:@selector(toggleFavorite:)];
    self.reloadButton = [self toolbarButtonWithSymbol:@"arrow.clockwise" label:@"刷新" action:@selector(reloadPage:)];
    self.forwardButton = [self toolbarButtonWithSymbol:@"chevron.right" label:@"前进" action:@selector(goForward:)];
    self.nightModeButton = [self iOSToolbarButtonWithAsset:@"night-auto"
                                                     label:@"夜间模式"
                                                    action:@selector(toggleNightMode:)];

    NSDateFormatter *clockFormatter = [[NSDateFormatter alloc] init];
    clockFormatter.dateFormat = @"H:mm";
    self.statusBarClock = [NSTextField labelWithString:[clockFormatter stringFromDate:NSDate.date]];
    self.statusBarClock.font = [NSFont systemFontOfSize:11.0 weight:NSFontWeightMedium];
    self.statusBarClock.alignment = NSTextAlignmentCenter;
    self.statusBarClock.translatesAutoresizingMaskIntoConstraints = NO;
    [topBar addSubview:self.statusBarClock];

    self.classicTitleLabel = [NSTextField labelWithString:@"草榴社區"];
    self.classicTitleLabel.font = [NSFont systemFontOfSize:17.0 weight:NSFontWeightSemibold];
    self.classicTitleLabel.alignment = NSTextAlignmentCenter;
    self.classicTitleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.classicTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [topBar addSubview:self.classicTitleLabel];
    [topBar addSubview:self.backButton];
    [topBar addSubview:self.favoriteButton];
    [topBar addSubview:self.nightModeButton];

    self.addressField = [[NSTextField alloc] initWithFrame:NSZeroRect];
    self.addressField.placeholderString = @"输入网址";
    self.addressField.bezelStyle = NSTextFieldRoundedBezel;
    self.addressField.font = [NSFont systemFontOfSize:13.0];
    self.addressField.target = self;
    self.addressField.action = @selector(openAddress:);
    self.addressField.translatesAutoresizingMaskIntoConstraints = NO;

    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    configuration.preferences.javaScriptCanOpenWindowsAutomatically = YES;
    configuration.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;
    configuration.allowsAirPlayForMediaPlayback = YES;
    configuration.websiteDataStore = WKWebsiteDataStore.defaultDataStore;
    configuration.defaultWebpagePreferences.preferredContentMode = WKContentModeMobile;

    WKUserContentController *contentController = [[WKUserContentController alloc] init];
    [contentController addScriptMessageHandler:self name:TGBridgeName];
    NSString *scriptPath = [NSBundle.mainBundle pathForResource:@"BrowserBridge" ofType:@"js"];
    NSError *scriptError = nil;
    NSString *scriptSource = [NSString stringWithContentsOfFile:scriptPath
                                                      encoding:NSUTF8StringEncoding
                                                         error:&scriptError];
    if (scriptSource.length > 0 && scriptError == nil) {
        WKUserScript *script = [[WKUserScript alloc] initWithSource:scriptSource
                                                     injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                                                  forMainFrameOnly:NO];
        [contentController addUserScript:script];
    }
    configuration.userContentController = contentController;

    self.webView = [[WKWebView alloc] initWithFrame:NSZeroRect configuration:configuration];
    self.webView.navigationDelegate = self;
    self.webView.UIDelegate = self;
    self.webView.allowsBackForwardNavigationGestures = YES;
    self.webView.allowsMagnification = YES;
    // Match the original iPad WKWebView. Several embedded players choose a
    // different control layer for desktop Safari, leaving advertising play
    // overlays visible after playback starts.
    self.webView.customUserAgent = @"Mozilla/5.0 (iPad; CPU OS 15_4 like Mac OS X) "
        "AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148";
    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    [content addSubview:self.webView];

    self.classicHomeView = [self buildClassicHome];
    [content addSubview:self.classicHomeView];

    NSView *bottomBar = [[NSView alloc] initWithFrame:NSZeroRect];
    bottomBar.wantsLayer = YES;
    bottomBar.translatesAutoresizingMaskIntoConstraints = NO;
    self.classicBottomBar = bottomBar;
    [content addSubview:bottomBar];

    NSButton *tabHome = [self rootTabButtonWithTitle:@"首页" image:@"tab-home" tag:0];
    NSButton *tabDiscover = [self rootTabButtonWithTitle:@"发现" image:@"tab-news" tag:1];
    NSButton *tabReturn = [self rootTabButtonWithTitle:@"回家" image:@"tab-address" tag:2];
    NSButton *tabMe = [self rootTabButtonWithTitle:@"我" image:@"tab-my" tag:3];
    self.rootTabButtons = @[tabHome, tabDiscover, tabReturn, tabMe];
    self.rootTabImageNames = @[
        @[@"tab-home", @"tab-home"],
        @[@"tab-news", @"tab-news-on"],
        @[@"tab-address", @"tab-address-on"],
        @[@"tab-my", @"tab-my-on"]
    ];
    NSStackView *tabs = [NSStackView stackViewWithViews:self.rootTabButtons];
    tabs.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    tabs.distribution = NSStackViewDistributionFillEqually;
    tabs.alignment = NSLayoutAttributeCenterY;
    tabs.translatesAutoresizingMaskIntoConstraints = NO;
    [bottomBar addSubview:tabs];

    self.statusLabel = [NSTextField labelWithString:@"就绪"];
    self.statusLabel.font = [NSFont systemFontOfSize:11.0];
    self.statusLabel.textColor = NSColor.secondaryLabelColor;
    self.statusLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    self.statusLabel.hidden = YES;

    self.progressIndicator = [[NSProgressIndicator alloc] initWithFrame:NSZeroRect];
    self.progressIndicator.style = NSProgressIndicatorStyleBar;
    self.progressIndicator.minValue = 0;
    self.progressIndicator.maxValue = 1;
    self.progressIndicator.doubleValue = 0;
    self.progressIndicator.hidden = YES;
    self.progressIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    [content addSubview:self.progressIndicator];

    self.classicTopBarHeightConstraint = [topBar.heightAnchor constraintEqualToConstant:64];
    self.classicBottomBarHeightConstraint = [bottomBar.heightAnchor constraintEqualToConstant:49];

    [NSLayoutConstraint activateConstraints:@[
        [topBar.leadingAnchor constraintEqualToAnchor:content.leadingAnchor],
        [topBar.trailingAnchor constraintEqualToAnchor:content.trailingAnchor],
        [topBar.topAnchor constraintEqualToAnchor:content.topAnchor],
        self.classicTopBarHeightConstraint,

        [self.statusBarClock.topAnchor constraintEqualToAnchor:topBar.topAnchor constant:2],
        [self.statusBarClock.centerXAnchor constraintEqualToAnchor:topBar.centerXAnchor],
        [self.statusBarClock.heightAnchor constraintEqualToConstant:17],

        [self.backButton.leadingAnchor constraintEqualToAnchor:topBar.leadingAnchor constant:10],
        [self.backButton.centerYAnchor constraintEqualToAnchor:self.classicTitleLabel.centerYAnchor],
        [self.classicTitleLabel.centerXAnchor constraintEqualToAnchor:topBar.centerXAnchor],
        [self.classicTitleLabel.topAnchor constraintEqualToAnchor:topBar.topAnchor constant:25],
        [self.classicTitleLabel.heightAnchor constraintEqualToConstant:22],
        [self.classicTitleLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.backButton.trailingAnchor constant:8],
        [self.nightModeButton.trailingAnchor constraintEqualToAnchor:topBar.trailingAnchor constant:-10],
        [self.nightModeButton.centerYAnchor constraintEqualToAnchor:self.classicTitleLabel.centerYAnchor],
        [self.favoriteButton.trailingAnchor constraintEqualToAnchor:self.nightModeButton.leadingAnchor constant:-6],
        [self.favoriteButton.centerYAnchor constraintEqualToAnchor:self.classicTitleLabel.centerYAnchor],
        [self.classicTitleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.favoriteButton.leadingAnchor constant:-8],

        [self.classicHomeView.leadingAnchor constraintEqualToAnchor:content.leadingAnchor],
        [self.classicHomeView.trailingAnchor constraintEqualToAnchor:content.trailingAnchor],
        [self.classicHomeView.topAnchor constraintEqualToAnchor:topBar.bottomAnchor],
        [self.classicHomeView.bottomAnchor constraintEqualToAnchor:bottomBar.topAnchor],

        [self.webView.leadingAnchor constraintEqualToAnchor:content.leadingAnchor],
        [self.webView.trailingAnchor constraintEqualToAnchor:content.trailingAnchor],
        [self.webView.topAnchor constraintEqualToAnchor:topBar.bottomAnchor],
        [self.webView.bottomAnchor constraintEqualToAnchor:bottomBar.topAnchor],

        [bottomBar.leadingAnchor constraintEqualToAnchor:content.leadingAnchor],
        [bottomBar.trailingAnchor constraintEqualToAnchor:content.trailingAnchor],
        [bottomBar.bottomAnchor constraintEqualToAnchor:content.bottomAnchor],
        self.classicBottomBarHeightConstraint,
        [tabs.leadingAnchor constraintEqualToAnchor:bottomBar.leadingAnchor],
        [tabs.trailingAnchor constraintEqualToAnchor:bottomBar.trailingAnchor],
        [tabs.topAnchor constraintEqualToAnchor:bottomBar.topAnchor],
        [tabs.bottomAnchor constraintEqualToAnchor:bottomBar.bottomAnchor],

        [self.progressIndicator.leadingAnchor constraintEqualToAnchor:content.leadingAnchor],
        [self.progressIndicator.trailingAnchor constraintEqualToAnchor:content.trailingAnchor],
        [self.progressIndicator.topAnchor constraintEqualToAnchor:topBar.bottomAnchor constant:-2],
        [self.progressIndicator.heightAnchor constraintEqualToConstant:2]
    ]];

    for (NSString *keyPath in @[@"URL", @"title", @"loading", @"estimatedProgress", @"canGoBack", @"canGoForward"]) {
        [self.webView addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionNew context:NULL];
    }

    self.selectedRootTab = 0;
    self.nightModeSelection = 0;
    [self updateRootTabUI];
    [self applyIOSTheme];
    [self showClassicHome];
    [self updateNavigationUI];
    [self updateTouchBar];
}

- (void)dealloc {
    for (NSString *keyPath in @[@"URL", @"title", @"loading", @"estimatedProgress", @"canGoBack", @"canGoForward"]) {
        @try {
            [self.webView removeObserver:self forKeyPath:keyPath];
        } @catch (__unused NSException *exception) {}
    }
    [self.webView.configuration.userContentController removeScriptMessageHandlerForName:TGBridgeName];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
    (void)change;
    (void)context;
    if (object == self.webView) {
        [self updateNavigationUI];
        return;
    }
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)updateNavigationUI {
    self.backButton.enabled = !self.showingClassicHome;
    self.forwardButton.enabled = self.webView.canGoForward;
    NSURL *URL = self.webView.URL;
    if (URL.absoluteString.length > 0 && self.window.firstResponder != self.addressField.currentEditor) {
        self.addressField.stringValue = URL.absoluteString;
    }
    NSString *title = self.webView.title;
    if (!self.showingClassicHome && title.length > 0) self.classicTitleLabel.stringValue = title;
    self.window.title = self.showingClassicHome ? @"小草" : (title.length > 0 ? title : @"小草");
    self.progressIndicator.hidden = !self.webView.loading;
    self.progressIndicator.doubleValue = self.webView.estimatedProgress;
    if (self.webView.loading) {
        self.statusLabel.stringValue = URL.host.length > 0
            ? [NSString stringWithFormat:@"正在载入 %@…", URL.host]
            : @"正在载入…";
    } else if (URL.absoluteString.length > 0) {
        self.statusLabel.stringValue = URL.absoluteString;
    }
    [self updateFavoriteUI];
}

- (void)focusLocation:(id)sender {
    (void)sender;
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"打开位置";
    alert.informativeText = @"输入网页地址";
    [alert addButtonWithTitle:@"打开"];
    [alert addButtonWithTitle:@"取消"];
    NSTextField *field = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 420, 24)];
    field.stringValue = self.webView.URL.absoluteString ?: @"https://t66y.com";
    field.placeholderString = @"https://";
    alert.accessoryView = field;
    [field selectText:nil];
    if ([alert runModal] == NSAlertFirstButtonReturn) [self loadURLString:field.stringValue];
}

- (void)openAddress:(id)sender {
    (void)sender;
    [self loadURLString:self.addressField.stringValue];
}

- (void)loadURLString:(NSString *)rawValue {
    NSString *value = [rawValue stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (value.length == 0) return;
    if ([value rangeOfString:@"://"].location == NSNotFound) {
        value = [@"https://" stringByAppendingString:value];
    }
    NSURL *URL = [NSURL URLWithString:value];
    if (URL == nil || URL.scheme.length == 0) {
        self.statusLabel.stringValue = @"网址无效";
        return;
    }
    [self showWebContent];
    [self.webView loadRequest:[NSURLRequest requestWithURL:URL
                                               cachePolicy:NSURLRequestUseProtocolCachePolicy
                                           timeoutInterval:30.0]];
}

- (void)goHome:(id)sender {
    (void)sender;
    self.selectedRootTab = 0;
    [self updateRootTabUI];
    [self showClassicHome];
}

- (void)showClassicHome {
    self.showingClassicHome = YES;
    self.classicHomeView.hidden = NO;
    self.webView.hidden = YES;
    self.backButton.hidden = YES;
    self.favoriteButton.hidden = YES;
    self.classicTitleLabel.stringValue = @"草榴社區";
    self.window.title = @"小草";
    self.progressIndicator.hidden = YES;
}

- (void)showWebContent {
    self.showingClassicHome = NO;
    self.classicHomeView.hidden = YES;
    self.webView.hidden = NO;
    self.backButton.hidden = NO;
    self.favoriteButton.hidden = NO;
    [self updateFavoriteUI];
}

- (void)updateRootTabUI {
    [self.rootTabButtons enumerateObjectsUsingBlock:^(NSButton *button, NSUInteger index, BOOL *stop) {
        (void)stop;
        BOOL selected = (NSInteger)index == self.selectedRootTab;
        BOOL dark = [self iOSDarkMode];
        NSArray<NSString *> *names = self.rootTabImageNames[index];
        button.image = [self iOSImageNamed:(selected ? names[1] : names[0])
                                      size:NSMakeSize(25, 25)
                                  template:YES];
        button.contentTintColor = selected
            ? (dark
                ? [NSColor colorWithCalibratedWhite:0.929 alpha:1.0]
                : [NSColor colorWithCalibratedRed:0.059 green:0.471 blue:0.518 alpha:1.0])
            : [NSColor colorWithCalibratedWhite:(dark ? 0.400 : 0.600) alpha:1.0];
        button.font = [NSFont systemFontOfSize:10.0 weight:NSFontWeightRegular];
    }];
}

- (void)applyIOSTheme {
    BOOL dark = [self iOSDarkMode];
    NSColor *navigationColor = dark
        ? [NSColor colorWithCalibratedWhite:0.133 alpha:1.0]
        : [NSColor colorWithCalibratedRed:0.059 green:0.471 blue:0.518 alpha:1.0];
    NSColor *listBackground = [NSColor colorWithCalibratedWhite:(dark ? 0.000 : 0.922) alpha:1.0];
    NSColor *rowBackground = [NSColor colorWithCalibratedWhite:(dark ? 0.133 : 1.000) alpha:1.0];
    NSColor *itemText = [NSColor colorWithCalibratedWhite:(dark ? 0.929 : 0.000) alpha:1.0];
    NSColor *sectionText = [NSColor colorWithCalibratedWhite:(dark ? 0.400 : 0.667) alpha:1.0];
    NSColor *iconColor = dark
        ? [NSColor colorWithCalibratedWhite:0.929 alpha:1.0]
        : [NSColor colorWithCalibratedRed:0.184 green:0.373 blue:0.631 alpha:1.0];
    NSColor *tabBarColor = [NSColor colorWithCalibratedWhite:(dark ? 0.271 : 1.000) alpha:1.0];

    self.classicTitleLabel.superview.layer.backgroundColor = navigationColor.CGColor;
    self.classicTitleLabel.textColor = NSColor.whiteColor;
    self.statusBarClock.textColor = NSColor.whiteColor;
    self.backButton.contentTintColor = NSColor.whiteColor;
    self.favoriteButton.contentTintColor = NSColor.whiteColor;
    self.nightModeButton.contentTintColor = NSColor.whiteColor;
    self.classicBottomBar.layer.backgroundColor = tabBarColor.CGColor;
    self.classicHomeView.backgroundColor = listBackground;

    for (NSTextField *section in self.forumSectionLabels) {
        section.textColor = sectionText;
        section.backgroundColor = listBackground;
        section.drawsBackground = YES;
    }
    for (TGForumRowView *row in self.forumRows) {
        row.layer.backgroundColor = rowBackground.CGColor;
        row.forumTitle.textColor = itemText;
        row.forumSubtitle.textColor = [NSColor colorWithCalibratedWhite:0.408 alpha:1.0];
        row.forumIcon.contentTintColor = iconColor;
        row.separator.borderColor = [NSColor colorWithCalibratedWhite:(dark ? 0.20 : 0.86) alpha:1.0];
    }

    NSString *nightAsset;
    if (self.nightModeSelection == 1) {
        nightAsset = @"night-light";
    } else if (self.nightModeSelection == 2) {
        nightAsset = @"night-night";
    } else {
        nightAsset = dark ? @"night-auto-dark" : @"night-auto";
    }
    self.nightModeButton.image = [self iOSImageNamed:nightAsset size:NSMakeSize(24, 24) template:YES];
    [self updateRootTabUI];
}

- (void)selectRootTab:(NSButton *)sender {
    self.selectedRootTab = sender.tag;
    [self updateRootTabUI];
    switch (sender.tag) {
        case 0:
            [self showClassicHome];
            break;
        case 1:
            self.classicTitleLabel.stringValue = @"發現";
            [self loadURLString:@"https://t66y.com/thread0806.php?fid=7"];
            break;
        case 2:
            self.classicTitleLabel.stringValue = @"回家";
            [self loadURLString:@"https://t66y.com/index.php"];
            break;
        case 3:
            self.classicTitleLabel.stringValue = @"我";
            [self loadURLString:@"https://t66y.com/login.php"];
            break;
        default:
            break;
    }
}

- (void)toggleNightMode:(id)sender {
    (void)sender;
    self.nightModeSelection = (self.nightModeSelection + 1) % 3;
    if (self.nightModeSelection == 1) {
        self.window.appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
    } else if (self.nightModeSelection == 2) {
        self.window.appearance = [NSAppearance appearanceNamed:NSAppearanceNameDarkAqua];
    } else {
        self.window.appearance = nil;
    }
    [self applyIOSTheme];
    BOOL makeDark = [self iOSDarkMode];
    if (!self.showingClassicHome && self.webView.URL != nil) {
        NSString *script = [NSString stringWithFormat:
            @"document.cookie='cssNight=%d; path=/; max-age=31536000'; location.reload();", makeDark ? 1 : 0];
        [self.webView evaluateJavaScript:script completionHandler:nil];
    }
}

- (void)toggleSidebar:(id)sender {
    (void)sender;
    self.sidebarVisible = !self.sidebarVisible;
    self.sidebarWidthConstraint.constant = self.sidebarVisible ? 228 : 0;
    self.sidebarScrollView.hidden = !self.sidebarVisible;
}

- (void)openSidebarRoute:(NSButton *)sender {
    if (sender.tag < 0 || sender.tag >= (NSInteger)self.sidebarRoutes.count) return;
    NSString *route = self.sidebarRoutes[(NSUInteger)sender.tag];
    [self showWebContent];
    if ([route isEqualToString:@"internal:favorites"]) {
        [self showLibraryWithTitle:@"收藏" defaultsKey:@"TonyGrassFavorites"];
    } else if ([route isEqualToString:@"internal:history"]) {
        [self showLibraryWithTitle:@"历史记录" defaultsKey:@"TonyGrassHistory"];
    } else if ([route isEqualToString:@"internal:settings"]) {
        [self showSettingsPage];
    } else {
        [self loadURLString:route];
    }
}

- (NSString *)HTMLSafe:(NSString *)value {
    NSString *result = value ?: @"";
    result = [result stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
    result = [result stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
    result = [result stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
    result = [result stringByReplacingOccurrencesOfString:@"\"" withString:@"&quot;"];
    return result;
}

- (void)showLibraryWithTitle:(NSString *)title defaultsKey:(NSString *)key {
    self.classicTitleLabel.stringValue = title;
    NSArray<NSDictionary *> *items = [NSUserDefaults.standardUserDefaults arrayForKey:key] ?: @[];
    NSMutableString *rows = [NSMutableString string];
    for (NSDictionary *item in items) {
        NSString *itemTitle = [item[@"title"] isKindOfClass:NSString.class] ? item[@"title"] : @"未命名页面";
        NSString *URL = [item[@"url"] isKindOfClass:NSString.class] ? item[@"url"] : @"";
        if (URL.length == 0) continue;
        [rows appendFormat:@"<a class='row' href=\"%@\"><b>%@</b><small>%@</small></a>",
            [self HTMLSafe:URL], [self HTMLSafe:itemTitle], [self HTMLSafe:URL]];
    }
    if (rows.length == 0) [rows appendString:@"<p class='empty'>这里还没有内容。</p>"];
    NSString *HTML = [NSString stringWithFormat:
        @"<!doctype html><meta name='viewport' content='width=device-width'><style>"
         "body{font-family:-apple-system;margin:0;background:#f4f5f6;color:#1d1d1f}"
         "main{max-width:860px;margin:0 auto;padding:42px 28px}h1{font-size:30px}"
         ".row{display:block;margin:10px 0;padding:16px 18px;background:white;border-radius:12px;"
         "text-decoration:none;color:inherit;box-shadow:0 1px 3px #0001}.row:hover{background:#eef7f1}"
         "small{display:block;color:#777;margin-top:6px;overflow:hidden;text-overflow:ellipsis}.empty{color:#777}"
         "@media(prefers-color-scheme:dark){body{background:#171717;color:#eee}.row{background:#252525}}"
         "</style><main><h1>%@</h1>%@</main>", [self HTMLSafe:title], rows];
    [self.webView loadHTMLString:HTML baseURL:[NSURL URLWithString:TGHomeURL]];
}

- (void)showSettingsPage {
    self.classicTitleLabel.stringValue = @"設定";
    NSString *HTML = @"<!doctype html><meta name='viewport' content='width=device-width'><style>"
        "body{font-family:-apple-system;margin:0;background:#f4f5f6;color:#1d1d1f}"
        "main{max-width:760px;margin:auto;padding:42px 28px}.card{background:white;border-radius:14px;"
        "padding:18px 22px;margin:12px 0;box-shadow:0 1px 3px #0001}h1{font-size:30px}"
        "@media(prefers-color-scheme:dark){body{background:#171717;color:#eee}.card{background:#252525}}"
        "</style><main><h1>设置与说明</h1>"
        "<div class='card'><b>登录状态</b><p>使用持久化 WebKit Cookie，与浏览页面共享。</p></div>"
        "<div class='card'><b>触控板与导航</b><p>支持左右滑动、后退、前进及同窗口外链。</p></div>"
        "<div class='card'><b>视频</b><p>Touch Bar 播放、进度、原生窗口全屏与 VidCatch 下载。</p></div>"
        "<div class='card'><b>架构</b><p>这是 Universal 2 客户端，同时支持 Intel x86_64 与 Apple silicon arm64。</p></div></main>";
    [self.webView loadHTMLString:HTML baseURL:[NSURL URLWithString:TGHomeURL]];
}

- (NSArray<NSDictionary *> *)storedItemsForKey:(NSString *)key {
    NSArray *value = [NSUserDefaults.standardUserDefaults arrayForKey:key];
    return [value isKindOfClass:NSArray.class] ? value : @[];
}

- (BOOL)currentPageIsFavorite {
    NSString *URL = self.webView.URL.absoluteString;
    if (URL.length == 0) return NO;
    for (NSDictionary *item in [self storedItemsForKey:@"TonyGrassFavorites"]) {
        if ([item[@"url"] isEqualToString:URL]) return YES;
    }
    return NO;
}

- (void)toggleFavorite:(id)sender {
    (void)sender;
    NSString *URL = self.webView.URL.absoluteString;
    if (URL.length == 0 || ![self.webView.URL.scheme.lowercaseString hasPrefix:@"http"]) return;
    NSMutableArray<NSDictionary *> *items = [[self storedItemsForKey:@"TonyGrassFavorites"] mutableCopy];
    NSUInteger index = [items indexOfObjectPassingTest:^BOOL(NSDictionary *item, NSUInteger idx, BOOL *stop) {
        (void)idx;
        (void)stop;
        return [item[@"url"] isEqualToString:URL];
    }];
    if (index == NSNotFound) {
        [items insertObject:@{@"url": URL, @"title": self.webView.title ?: URL} atIndex:0];
        self.statusLabel.stringValue = @"已加入收藏";
    } else {
        [items removeObjectAtIndex:index];
        self.statusLabel.stringValue = @"已取消收藏";
    }
    [NSUserDefaults.standardUserDefaults setObject:items forKey:@"TonyGrassFavorites"];
    [self updateFavoriteUI];
}

- (void)updateFavoriteUI {
    BOOL favorite = [self currentPageIsFavorite];
    self.favoriteButton.image = [self iOSImageNamed:@"button-menu" size:NSMakeSize(24, 24) template:YES];
    self.favoriteButton.contentTintColor = favorite ? NSColor.systemYellowColor : NSColor.whiteColor;
}

- (void)recordCurrentPageInHistory {
    NSURL *URL = self.webView.URL;
    if (![@[@"http", @"https"] containsObject:URL.scheme.lowercaseString] || URL.absoluteString.length == 0) return;
    NSMutableArray<NSDictionary *> *items = [[self storedItemsForKey:@"TonyGrassHistory"] mutableCopy];
    NSIndexSet *duplicates = [items indexesOfObjectsPassingTest:^BOOL(NSDictionary *item, NSUInteger idx, BOOL *stop) {
        (void)idx;
        (void)stop;
        return [item[@"url"] isEqualToString:URL.absoluteString];
    }];
    [items removeObjectsAtIndexes:duplicates];
    [items insertObject:@{@"url": URL.absoluteString, @"title": self.webView.title ?: URL.absoluteString} atIndex:0];
    if (items.count > 200) [items removeObjectsInRange:NSMakeRange(200, items.count - 200)];
    [NSUserDefaults.standardUserDefaults setObject:items forKey:@"TonyGrassHistory"];
}

- (void)goBack:(id)sender {
    (void)sender;
    if (self.showingClassicHome) return;
    if (self.webView.canGoBack) {
        [self.webView goBack];
    } else {
        self.selectedRootTab = 0;
        [self updateRootTabUI];
        [self showClassicHome];
    }
}

- (void)goForward:(id)sender {
    (void)sender;
    if (self.webView.canGoForward) [self.webView goForward];
}

- (void)reloadPage:(id)sender {
    (void)sender;
    if (self.webView.URL != nil) [self.webView reload];
}

- (void)toggleWindowFullscreen:(id)sender {
    (void)sender;
    [self.window toggleFullScreen:nil];
}

#pragma mark - WebKit navigation

- (void)webView:(WKWebView *)webView
    decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
                   decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSURL *URL = navigationAction.request.URL;
    NSString *scheme = URL.scheme.lowercaseString;

    if (navigationAction.shouldPerformDownload) {
        decisionHandler(WKNavigationActionPolicyDownload);
        return;
    }
    if (URL == nil || scheme.length == 0) {
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    if (![scheme isEqualToString:@"http"] && ![scheme isEqualToString:@"https"] &&
        ![scheme isEqualToString:@"file"] && ![scheme isEqualToString:@"about"] &&
        ![scheme isEqualToString:@"data"]) {
        [NSWorkspace.sharedWorkspace openURL:URL];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    if (navigationAction.targetFrame == nil) {
        [webView loadRequest:navigationAction.request];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView
    decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse
                     decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    (void)webView;
    if (!navigationResponse.canShowMIMEType) {
        decisionHandler(WKNavigationResponsePolicyDownload);
        return;
    }
    decisionHandler(WKNavigationResponsePolicyAllow);
}

- (WKWebView *)webView:(WKWebView *)webView
    createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration
       forNavigationAction:(WKNavigationAction *)navigationAction
            windowFeatures:(WKWindowFeatures *)windowFeatures {
    (void)configuration;
    (void)windowFeatures;
    if (navigationAction.request.URL != nil) [webView loadRequest:navigationAction.request];
    return nil;
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    (void)webView;
    (void)navigation;
    [self recordCurrentPageInHistory];
    [self updateNavigationUI];
}

- (void)webView:(WKWebView *)webView
    didFailNavigation:(WKNavigation *)navigation
             withError:(NSError *)error {
    (void)webView;
    (void)navigation;
    self.statusLabel.stringValue = error.localizedDescription ?: @"网页载入失败";
}

- (void)webView:(WKWebView *)webView
    didFailProvisionalNavigation:(WKNavigation *)navigation
                       withError:(NSError *)error {
    [self webView:webView didFailNavigation:navigation withError:error];
}

- (void)webView:(WKWebView *)webView
    didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
                     completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition,
                                                 NSURLCredential * _Nullable credential))completionHandler {
    (void)webView;
    completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
}

- (void)webView:(WKWebView *)webView
    navigationAction:(WKNavigationAction *)navigationAction
    didBecomeDownload:(WKDownload *)download {
    (void)webView;
    (void)navigationAction;
    download.delegate = self;
}

- (void)webView:(WKWebView *)webView
    navigationResponse:(WKNavigationResponse *)navigationResponse
    didBecomeDownload:(WKDownload *)download {
    (void)webView;
    (void)navigationResponse;
    download.delegate = self;
}

- (NSURL *)uniqueDownloadURLForFilename:(NSString *)suggestedFilename {
    NSURL *downloads = [NSFileManager.defaultManager URLsForDirectory:NSDownloadsDirectory
                                                             inDomains:NSUserDomainMask].firstObject;
    NSString *filename = suggestedFilename.lastPathComponent;
    if (filename.length == 0) filename = @"下载";
    NSURL *candidate = [downloads URLByAppendingPathComponent:filename];
    NSString *extension = candidate.pathExtension;
    NSString *stem = [candidate.lastPathComponent stringByDeletingPathExtension];
    NSUInteger suffix = 2;
    while ([NSFileManager.defaultManager fileExistsAtPath:candidate.path]) {
        NSString *next = [NSString stringWithFormat:@"%@-%lu", stem, (unsigned long)suffix++];
        if (extension.length > 0) next = [next stringByAppendingPathExtension:extension];
        candidate = [downloads URLByAppendingPathComponent:next];
    }
    return candidate;
}

- (void)download:(WKDownload *)download
    decideDestinationUsingResponse:(NSURLResponse *)response
                 suggestedFilename:(NSString *)suggestedFilename
                 completionHandler:(void (^)(NSURL * _Nullable destination))completionHandler {
    (void)download;
    (void)response;
    NSURL *destination = [self uniqueDownloadURLForFilename:suggestedFilename];
    self.statusLabel.stringValue = [NSString stringWithFormat:@"正在下载 %@…", destination.lastPathComponent];
    completionHandler(destination);
}

- (void)downloadDidFinish:(WKDownload *)download {
    (void)download;
    self.statusLabel.stringValue = @"下载完成，已保存到“下载”文件夹";
}

- (void)download:(WKDownload *)download
    didFailWithError:(NSError *)error
          resumeData:(NSData *)resumeData {
    (void)download;
    (void)resumeData;
    self.statusLabel.stringValue = [NSString stringWithFormat:@"下载失败：%@", error.localizedDescription];
}

#pragma mark - JavaScript bridge

- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message {
    (void)userContentController;
    if (![message.name isEqualToString:TGBridgeName] ||
        ![message.body isKindOfClass:NSDictionary.class]) return;

    NSDictionary *body = (NSDictionary *)message.body;
    NSString *type = [body[@"type"] isKindOfClass:NSString.class] ? body[@"type"] : @"";
    if ([type isEqualToString:@"state"]) {
        self.mediaFrame = message.frameInfo;
        self.elapsed = [body[@"currentTime"] respondsToSelector:@selector(doubleValue)]
            ? [body[@"currentTime"] doubleValue]
            : 0;
        self.duration = [body[@"duration"] respondsToSelector:@selector(doubleValue)]
            ? [body[@"duration"] doubleValue]
            : 0;
        self.paused = [body[@"paused"] respondsToSelector:@selector(boolValue)]
            ? [body[@"paused"] boolValue]
            : YES;
        self.pictureInPicture = [body[@"pip"] respondsToSelector:@selector(boolValue)]
            ? [body[@"pip"] boolValue]
            : NO;
        self.pictureInPictureAvailable = [body[@"pipAvailable"] respondsToSelector:@selector(boolValue)]
            ? [body[@"pipAvailable"] boolValue]
            : NO;
        self.fullscreen = [body[@"fullscreen"] respondsToSelector:@selector(boolValue)]
            ? [body[@"fullscreen"] boolValue]
            : NO;
        if (self.fullscreen) self.mediaFullscreenRequestGeneration += 1;
        double playbackRate = [body[@"rate"] respondsToSelector:@selector(doubleValue)]
            ? MAX([body[@"rate"] doubleValue], 0.0)
            : 1.0;
        if (playbackRate > 0.0) self.defaultPlaybackRate = playbackRate;
        if ([body[@"title"] isKindOfClass:NSString.class]) self.title = body[@"title"];
        [self refreshAVKitTimingWithRate:self.paused ? 0.0 : playbackRate];
        [self installTouchBarIfNeeded];
        [self updateSafariEscapeKey];
        [self updateTouchBar];
    } else if ([type isEqualToString:@"clear"] && message.frameInfo.isMainFrame) {
        // BrowserBridge runs in every iframe. Ad/player iframe reloads must not
        // tear down the active Touch Bar while the visible video keeps playing.
        [self clearMediaControls];
    } else if ([type isEqualToString:@"download"]) {
        [self beginVidCatchDownload:body];
    } else if ([type isEqualToString:@"fullscreenRequest"]) {
        self.mediaFrame = message.frameInfo;
        if (self.mediaCinemaFullscreen) [self toggleMediaFullscreen:nil];
        else if (self.fullscreen) [self evaluateCommand:@"fullscreen" value:nil];
        else [self enterCinemaFullscreenFallback];
    }
}

- (void)evaluateCommand:(NSString *)command value:(NSNumber *)value {
    NSMutableDictionary *payload = [@{
        @"__tonyGrassCommand": @YES,
        @"command": command ?: @""
    } mutableCopy];
    if (value != nil) payload[@"value"] = value;
    NSData *data = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];
    NSString *JSON = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSString *script = [NSString stringWithFormat:@"window.postMessage(%@, '*');", JSON ?: @"{}"];
    if (self.mediaFrame != nil) {
        [self.webView evaluateJavaScript:script
                                 inFrame:self.mediaFrame
                          inContentWorld:WKContentWorld.pageWorld
                       completionHandler:nil];
    } else {
        [self.webView evaluateJavaScript:script completionHandler:nil];
    }
}

- (void)evaluateTopFrameCommand:(NSString *)command value:(NSNumber *)value {
    NSMutableDictionary *payload = [@{
        @"__tonyGrassCommand": @YES,
        @"command": command ?: @""
    } mutableCopy];
    if (value != nil) payload[@"value"] = value;
    NSData *data = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];
    NSString *JSON = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSString *script = [NSString stringWithFormat:@"window.postMessage(%@, '*');", JSON ?: @"{}"];
    [self.webView evaluateJavaScript:script completionHandler:nil];
}

#pragma mark - Touch Bar

+ (NSSet<NSString *> *)keyPathsForValuesAffectingContentDuration {
    return [NSSet setWithObjects:@"duration", @"seekableTimeRanges", nil];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingPlaying {
    return [NSSet setWithObject:@"paused"];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingCanSeek {
    return [NSSet setWithObjects:@"duration", @"seekableTimeRanges", nil];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingCanBeginTouchBarScrubbing {
    return [NSSet setWithObjects:@"duration", @"seekableTimeRanges", nil];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingPictureInPictureActive {
    return [NSSet setWithObject:@"pictureInPicture"];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingCanTogglePictureInPicture {
    return [NSSet setWithObject:@"pictureInPictureAvailable"];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingAllowsPictureInPicturePlayback {
    return [NSSet setWithObject:@"pictureInPictureAvailable"];
}

- (void)installRemoteCommands {
    MPRemoteCommandCenter *commands = MPRemoteCommandCenter.sharedCommandCenter;
    commands.playCommand.enabled = YES;
    commands.pauseCommand.enabled = YES;
    commands.togglePlayPauseCommand.enabled = YES;
    commands.changePlaybackPositionCommand.enabled = YES;

    __weak typeof(self) weakSelf = self;
    [commands.playCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event) {
        (void)event;
        [weakSelf evaluateCommand:@"play" value:nil];
        return weakSelf.duration > 0.0
            ? MPRemoteCommandHandlerStatusSuccess
            : MPRemoteCommandHandlerStatusNoActionableNowPlayingItem;
    }];
    [commands.pauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event) {
        (void)event;
        [weakSelf evaluateCommand:@"pause" value:nil];
        return weakSelf.duration > 0.0
            ? MPRemoteCommandHandlerStatusSuccess
            : MPRemoteCommandHandlerStatusNoActionableNowPlayingItem;
    }];
    [commands.togglePlayPauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event) {
        (void)event;
        [weakSelf evaluateCommand:@"toggle" value:nil];
        return weakSelf.duration > 0.0
            ? MPRemoteCommandHandlerStatusSuccess
            : MPRemoteCommandHandlerStatusNoActionableNowPlayingItem;
    }];
    [commands.changePlaybackPositionCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event) {
        if (![event isKindOfClass:MPChangePlaybackPositionCommandEvent.class]) {
            return MPRemoteCommandHandlerStatusCommandFailed;
        }
        NSTimeInterval position = ((MPChangePlaybackPositionCommandEvent *)event).positionTime;
        [weakSelf evaluateCommand:@"seek" value:@(position)];
        return weakSelf.duration > 0.0
            ? MPRemoteCommandHandlerStatusSuccess
            : MPRemoteCommandHandlerStatusNoActionableNowPlayingItem;
    }];
}

- (id)newAVValueTimingWithValue:(double)value rate:(double)rate {
    if (!TGLoadMacAVKit()) return nil;
    Class timingClass = NSClassFromString(@"AVValueTiming");
    NSTimeInterval timeStamp = NSProcessInfo.processInfo.systemUptime;
    return ((id (*)(id, SEL, double, double, double))objc_msgSend)(
        [timingClass alloc],
        NSSelectorFromString(@"initWithAnchorValue:anchorTimeStamp:rate:"),
        value,
        timeStamp,
        rate
    );
}

- (void)refreshAVKitTimingWithRate:(double)rate {
    self.rate = (float)rate;
    self.timing = [self newAVValueTimingWithValue:self.elapsed rate:rate];
    if (self.duration > 0.0 && isfinite(self.duration)) {
        CMTime durationTime = CMTimeMakeWithSeconds(self.duration, 1000);
        self.seekableTimeRanges = @[
            [NSValue valueWithCMTimeRange:CMTimeRangeMake(kCMTimeZero, durationTime)]
        ];
    } else {
        self.seekableTimeRanges = @[];
    }
}

- (NSTimeInterval)contentDuration {
    return self.seekableTimeRanges.count > 0 ? self.duration : INFINITY;
}

- (NSTimeInterval)contentDurationWithinEndTimes {
    return [self contentDuration];
}

- (BOOL)isPlaying {
    return !self.paused;
}

- (void)setPlaying:(BOOL)playing {
    if (playing == [self isPlaying]) return;
    self.paused = !playing;
    [self refreshAVKitTimingWithRate:playing ? MAX(self.defaultPlaybackRate, 0.1) : 0.0];
    [self evaluateCommand:playing ? @"play" : @"pause" value:nil];
}

- (void)togglePlayback {
    [self setPlaying:self.paused];
}

- (void)togglePlayback:(id)sender {
    (void)sender;
    [self togglePlayback];
}

- (BOOL)canTogglePlayback {
    return self.duration > 0.0;
}

- (BOOL)canSeek {
    return self.duration > 0.0 && isfinite(self.duration);
}

- (BOOL)isSeeking {
    return NO;
}

- (BOOL)isCompletelySeekable {
    return [self canSeek];
}

- (BOOL)hasSeekableLiveStreamingContent {
    return NO;
}

- (BOOL)hasLiveStreamingContent {
    return NO;
}

- (NSTimeInterval)minTime {
    return 0.0;
}

- (NSTimeInterval)maxTime {
    return self.duration;
}

- (id)minTiming {
    return [self newAVValueTimingWithValue:0.0 rate:0.0];
}

- (id)maxTiming {
    return [self newAVValueTimingWithValue:self.duration rate:0.0];
}

- (NSTimeInterval)seekToTime {
    return self.elapsed;
}

- (void)setSeekToTime:(NSTimeInterval)time {
    [self seekToTime:time toleranceBefore:0.0 toleranceAfter:0.0];
}

- (void)seekToTime:(NSTimeInterval)time
    toleranceBefore:(NSTimeInterval)toleranceBefore
    toleranceAfter:(NSTimeInterval)toleranceAfter {
    (void)toleranceBefore;
    (void)toleranceAfter;
    if (!isfinite(time) || ![self canSeek]) return;
    self.elapsed = MIN(MAX(time, 0.0), self.duration);
    [self refreshAVKitTimingWithRate:self.paused ? 0.0 : MAX(self.defaultPlaybackRate, 0.1)];
    [self evaluateCommand:@"seek" value:@(self.elapsed)];
}

- (BOOL)canBeginTouchBarScrubbing {
    return [self canSeek] && isfinite([self contentDuration]);
}

- (void)beginTouchBarScrubbing {}
- (void)endTouchBarScrubbing {}
- (BOOL)hasEnabledAudio { return YES; }
- (BOOL)hasEnabledVideo { return YES; }
- (id)currentAudioTrack { return nil; }
- (id)audioWaveform { return nil; }
- (void)cancelThumbnailAndAudioAmplitudeSampleGeneration {}
- (void)cancelThumbnailGeneration {}
- (void)cancelThumbnailGenerationForRequestType:(NSInteger)requestType { (void)requestType; }

- (void)generateTouchBarThumbnailsForTimes:(NSArray *)thumbnailTimes
    tolerance:(NSTimeInterval)tolerance
    size:(CGSize)size
    thumbnailHandler:(void (^)(NSArray *, BOOL))thumbnailHandler {
    (void)thumbnailTimes;
    (void)tolerance;
    (void)size;
    if (thumbnailHandler != nil) thumbnailHandler(@[], YES);
}

- (void)generateTouchBarThumbnailsForTimes:(NSArray *)thumbnailTimes
    tolerance:(NSTimeInterval)tolerance
    size:(CGSize)size
    requestType:(NSInteger)requestType
    thumbnailHandler:(id)thumbnailHandler {
    (void)thumbnailTimes;
    (void)tolerance;
    (void)size;
    (void)requestType;
    (void)thumbnailHandler;
}

- (void)generateTouchBarAudioAmplitudeSamples:(NSInteger)numberOfSamples
    completionHandler:(void (^)(NSArray *))completionHandler {
    (void)numberOfSamples;
    if (completionHandler != nil) completionHandler(@[]);
}

- (NSArray *)audioTouchBarMediaSelectionOptions { return @[]; }
- (NSArray *)legibleTouchBarMediaSelectionOptions { return @[]; }
- (id)currentAudioTouchBarMediaSelectionOption { return nil; }
- (id)currentLegibleTouchBarMediaSelectionOption { return nil; }
- (void)setCurrentAudioTouchBarMediaSelectionOption:(id)option { (void)option; }
- (void)setCurrentLegibleTouchBarMediaSelectionOption:(id)option { (void)option; }
- (BOOL)hasTouchBarMediaSelectionOptions { return NO; }
- (BOOL)hasAudioTouchBarMediaSelectionOptions { return NO; }
- (BOOL)hasLegibleTouchBarMediaSelectionOptions { return NO; }
- (BOOL)allowsPictureInPicturePlayback { return self.pictureInPictureAvailable; }
- (BOOL)isPictureInPictureActive { return self.pictureInPicture; }

- (void)setPictureInPictureActive:(BOOL)active {
    if (active != self.pictureInPicture) [self evaluateCommand:@"pip" value:nil];
}

- (BOOL)canTogglePictureInPicture { return self.pictureInPictureAvailable; }

- (void)togglePictureInPicture {
    if (self.pictureInPictureAvailable) [self evaluateCommand:@"pip" value:nil];
}

- (void)togglePictureInPicture:(id)sender {
    (void)sender;
    [self togglePictureInPicture];
}

- (void)skipBackwardThirtySeconds:(id)sender {
    (void)sender;
    [self seekToTime:self.elapsed - 30.0 toleranceBefore:0.0 toleranceAfter:0.0];
}

- (void)gotoEndOfSeekableRanges:(id)sender {
    (void)sender;
    [self seekToTime:self.duration toleranceBefore:0.0 toleranceAfter:0.0];
}

- (BOOL)canScanForward { return NO; }
- (BOOL)canScanBackward { return NO; }
- (void)scanForward:(id)sender { (void)sender; }
- (void)scanBackward:(id)sender { (void)sender; }
- (void)controlsViewWillAppear {}
- (void)controlsViewDidDisappear {}
- (NSURL *)assetURL { return nil; }

- (BOOL)installSafariTouchBarIfAvailable {
    if (!TGLoadMacAVKit()) return NO;
    Protocol *controllerProtocol = objc_getProtocol("AVTouchBarPlaybackControlsControlling");
    if (controllerProtocol != nil) class_addProtocol(self.class, controllerProtocol);

    Class providerClass = NSClassFromString(@"AVTouchBarPlaybackControlsProvider");
    id provider = [[providerClass alloc] init];
    SEL controllerSelector = NSSelectorFromString(@"setPlaybackControlsController:");
    if (provider == nil || ![provider respondsToSelector:controllerSelector]) return NO;
    TGSendObject(provider, controllerSelector, self);

    id touchBar = TGGetObject(provider, NSSelectorFromString(@"touchBar"));
    if (touchBar == nil || self.window == nil) {
        TGSendObject(provider, controllerSelector, nil);
        return NO;
    }

    self.previousTouchBar = self.window.touchBar;
    self.touchBarProvider = provider;
    self.touchBar = touchBar;
    [self installSafariFullscreenItemIfNeeded];
    [self updateSafariEscapeKey];
    [self ensureTouchBarAttached];
    return YES;
}

- (void)installSafariFullscreenItemIfNeeded {
    if (self.touchBarProvider == nil || self.touchBar == nil) return;
    Class itemClass = NSClassFromString(@"NSButtonTouchBarItem");
    if (itemClass == Nil) return;
    NSString *identifier = @"com.tony.grass.fullscreen-toggle";
    id item = self.touchBarFullscreenItem;
    if (item == nil) {
        item = TGCreateTouchBarButton(
            itemClass,
            identifier,
            TGImageNamed(NSImageNameTouchBarEnterFullScreenTemplate),
            self,
            @selector(touchBarFullscreenPressed:)
        );
        if (item == nil) return;
        TGSendObject(item, NSSelectorFromString(@"setCustomizationLabel:"), @"全屏/退出全屏");
        self.touchBarFullscreenItem = item;
    }

    // AVKit rebuilds its template/default identifiers when playback changes
    // from paused to playing. Reassert our toggle every time instead of only
    // when the item is first created, otherwise it vanishes as playback starts.
    NSSet *existingItems = [self.touchBar respondsToSelector:NSSelectorFromString(@"templateItems")]
        ? TGGetObject(self.touchBar, NSSelectorFromString(@"templateItems"))
        : nil;
    NSMutableSet *items = existingItems != nil ? [existingItems mutableCopy] : [NSMutableSet set];
    [items addObject:item];
    TGSendObject(self.touchBar, NSSelectorFromString(@"setTemplateItems:"), items);

    NSArray *existingIdentifiers = [self.touchBar respondsToSelector:NSSelectorFromString(@"defaultItemIdentifiers")]
        ? TGGetObject(self.touchBar, NSSelectorFromString(@"defaultItemIdentifiers"))
        : nil;
    NSMutableArray *identifiers = existingIdentifiers != nil
        ? [existingIdentifiers mutableCopy]
        : [NSMutableArray array];
    [identifiers removeObject:identifier];
    [identifiers addObject:identifier];
    TGSendObject(self.touchBar, NSSelectorFromString(@"setDefaultItemIdentifiers:"), identifiers);
    [self updateFullscreenButton];
}

- (void)installTouchBarIfNeeded {
    if (self.touchBar != nil) {
        [self ensureTouchBarAttached];
        return;
    }
    if (self.duration <= 0.0) return;
    if (![self installSafariTouchBarIfAvailable]) [self installFallbackTouchBarIfNeeded];
}

- (NSWindow *)activeTouchBarHostWindow {
    NSWindow *keyWindow = NSApp.keyWindow;
    if (self.fullscreen || self.mediaCinemaFullscreen) {
        if (keyWindow != nil && keyWindow != self.window) return keyWindow;
        // WebKit's native video presentation uses an auxiliary borderless
        // window. During part of the transition AppKit can still report the
        // original browser as key, so locate the visible screen-sized window.
        for (NSWindow *candidate in NSApp.windows) {
            if (candidate == self.window || !candidate.visible || candidate.screen == nil) continue;
            NSRect screenFrame = candidate.screen.frame;
            if (candidate.frame.size.width >= screenFrame.size.width * 0.9 &&
                candidate.frame.size.height >= screenFrame.size.height * 0.9) {
                return candidate;
            }
        }
        if (keyWindow != nil) return keyWindow;
    }
    return self.window;
}

- (void)ensureTouchBarAttached {
    if (self.touchBar == nil || self.window == nil) return;
    NSWindow *hostWindow = [self activeTouchBarHostWindow];
    if (hostWindow == nil) hostWindow = self.window;

    if (self.touchBarHostWindow != hostWindow) {
        NSWindow *oldHost = self.touchBarHostWindow;
        if (oldHost != nil && oldHost != self.window && oldHost.touchBar == self.touchBar) {
            oldHost.touchBar = self.touchBarHostPreviousTouchBar;
        }
        self.touchBarHostWindow = hostWindow;
        self.touchBarHostPreviousTouchBar = hostWindow == self.window
            ? self.previousTouchBar
            : hostWindow.touchBar;
    }
    if (hostWindow.touchBar != self.touchBar) hostWindow.touchBar = self.touchBar;

    // AppKit resolves a Touch Bar through the first-responder chain before it
    // falls back to NSWindow.touchBar. WKWebView installs its own responder
    // Touch Bar when media changes from paused to playing, which is why the
    // window-owned fullscreen item used to disappear at that exact moment.
    // Bind the AVKit bar to both WKWebView and the active content responder so
    // WebKit cannot shadow it while playback or fullscreen is active.
    if (self.webView.touchBar != self.touchBar) self.webView.touchBar = self.touchBar;
    NSResponder *hostResponder = hostWindow.firstResponder;
    if (hostResponder != nil && hostResponder != hostWindow) {
        if (self.touchBarHostResponder != hostResponder) {
            NSResponder *oldResponder = self.touchBarHostResponder;
            if (oldResponder != nil && oldResponder.touchBar == self.touchBar) {
                oldResponder.touchBar = self.touchBarHostResponderPreviousTouchBar;
            }
            self.touchBarHostResponder = hostResponder;
            self.touchBarHostResponderPreviousTouchBar = hostResponder.touchBar;
        }
        if (hostResponder.touchBar != self.touchBar) hostResponder.touchBar = self.touchBar;
    }
}

- (void)refreshTouchBarPresentation {
    if (self.touchBar == nil || self.window == nil) {
        [self installTouchBarIfNeeded];
        return;
    }
    if (self.touchBarProvider != nil &&
        [self.touchBarProvider respondsToSelector:NSSelectorFromString(@"setPlaybackControlsController:")]) {
        TGSendObject(self.touchBarProvider,
                     NSSelectorFromString(@"setPlaybackControlsController:"), self);
    }
    // AppKit can detach a window-owned Touch Bar while swapping the window
    // into or out of its fullscreen Space. Reassign it after the transition so
    // the AVKit/Safari controls cannot be left as an empty strip.
    NSWindow *hostWindow = [self activeTouchBarHostWindow];
    if (hostWindow != nil) hostWindow.touchBar = nil;
    [self ensureTouchBarAttached];
    [self installSafariFullscreenItemIfNeeded];
    [self updateSafariEscapeKey];
    [self updateTouchBar];
}

- (void)installFallbackTouchBarIfNeeded {
    if (self.touchBar != nil) return;
    Class sliderItemClass = NSClassFromString(@"NSSliderTouchBarItem");
    Class buttonItemClass = NSClassFromString(@"NSButtonTouchBarItem");
    if (sliderItemClass == Nil || buttonItemClass == Nil || self.window == nil) return;

    NSString *fullscreenIdentifier = @"com.tony.grass.fullscreen-toggle";
    NSString *playIdentifier = @"com.tony.grass.play-pause";
    NSString *sliderIdentifier = @"com.tony.grass.video-scrubber";
    NSString *pipIdentifier = @"com.tony.grass.picture-in-picture";
    NSTouchBar *touchBar = [[NSTouchBar alloc] init];
    id sliderItem = ((id (*)(id, SEL, id))objc_msgSend)(
        [sliderItemClass alloc],
        NSSelectorFromString(@"initWithIdentifier:"),
        sliderIdentifier
    );
    TGSendObject(sliderItem, NSSelectorFromString(@"setLabel:"), nil);
    TGSendObject(sliderItem, NSSelectorFromString(@"setCustomizationLabel:"), @"视频时间轴");
    TGSendObject(sliderItem, NSSelectorFromString(@"setTarget:"), self);
    ((void (*)(id, SEL, SEL))objc_msgSend)(
        sliderItem,
        NSSelectorFromString(@"setAction:"),
        @selector(touchBarSliderChanged:)
    );
    TGSendDouble(sliderItem, NSSelectorFromString(@"setMinimumSliderWidth:"), 360.0);
    TGSendDouble(sliderItem, NSSelectorFromString(@"setMaximumSliderWidth:"), 720.0);
    id slider = TGGetObject(sliderItem, NSSelectorFromString(@"slider"));
    TGSendDouble(slider, NSSelectorFromString(@"setMinValue:"), 0.0);
    TGSendDouble(slider, NSSelectorFromString(@"setMaxValue:"), MAX(self.duration, 1.0));
    TGSendDouble(slider, NSSelectorFromString(@"setDoubleValue:"), self.elapsed);
    TGSendBool(slider, NSSelectorFromString(@"setContinuous:"), YES);

    id playItem = TGCreateTouchBarButton(
        buttonItemClass,
        playIdentifier,
        TGImageNamed(NSImageNameTouchBarPlayTemplate),
        self,
        @selector(touchBarPlayPausePressed:)
    );
    id pipItem = TGCreateTouchBarButton(
        buttonItemClass,
        pipIdentifier,
        [NSImage imageWithSystemSymbolName:@"pip.enter" accessibilityDescription:nil],
        self,
        @selector(touchBarPictureInPicturePressed:)
    );
    id fullscreenItem = TGCreateTouchBarButton(
        buttonItemClass,
        fullscreenIdentifier,
        TGImageNamed(NSImageNameTouchBarEnterFullScreenTemplate),
        self,
        @selector(touchBarFullscreenPressed:)
    );

    NSMutableSet *items = [NSMutableSet setWithObject:sliderItem];
    if (playItem != nil) [items addObject:playItem];
    if (pipItem != nil) [items addObject:pipItem];
    if (fullscreenItem != nil) [items addObject:fullscreenItem];
    touchBar.templateItems = items;
    touchBar.principalItemIdentifier = sliderIdentifier;

    self.previousTouchBar = self.window.touchBar;
    self.touchBar = touchBar;
    self.touchBarSliderItem = sliderItem;
    self.touchBarSlider = slider;
    self.touchBarPlayPauseItem = playItem;
    self.touchBarPictureInPictureItem = pipItem;
    self.touchBarFullscreenItem = fullscreenItem;
    [self updateTouchBar];
    [self ensureTouchBarAttached];
}

- (void)updateSafariEscapeKey {
    if (self.touchBarProvider == nil || self.touchBar == nil) return;
    BOOL full = self.fullscreen || self.mediaCinemaFullscreen;
    if (!full) {
        ((NSTouchBar *)self.touchBar).escapeKeyReplacementItemIdentifier = nil;
        self.touchBarExitFullscreenItem = nil;
        return;
    }
    if (self.touchBarExitFullscreenItem == nil) {
        NSCustomTouchBarItem *item = [[NSCustomTouchBarItem alloc]
            initWithIdentifier:@"WKMediaExitFullScreenItem"];
        NSButton *button = [NSButton
            buttonWithImage:TGImageNamed(NSImageNameTouchBarExitFullScreenTemplate)
            target:self
            action:@selector(touchBarExitFullscreenPressed:)];
        button.accessibilityTitle = @"退出全屏";
        item.view = button;
        self.touchBarExitFullscreenItem = item;
    }
    // The public NSTouchBar API takes an item *identifier*, not an item.
    // Putting the item in templateItems and assigning its identifier reserves
    // the hardware Escape-key position, matching Safari's native fullscreen
    // video behavior even while AVKit rebuilds the rest of the playback bar.
    NSMutableSet *items = [((NSTouchBar *)self.touchBar).templateItems mutableCopy];
    if (items == nil) items = [NSMutableSet set];
    [items addObject:self.touchBarExitFullscreenItem];
    ((NSTouchBar *)self.touchBar).templateItems = items;
    ((NSTouchBar *)self.touchBar).escapeKeyReplacementItemIdentifier =
        ((NSTouchBarItem *)self.touchBarExitFullscreenItem).identifier;
}

- (void)updateFullscreenButton {
    if (self.touchBarFullscreenItem == nil) return;
    BOOL full = self.fullscreen || self.mediaCinemaFullscreen;
    id image = TGImageNamed(full
        ? NSImageNameTouchBarExitFullScreenTemplate
        : NSImageNameTouchBarEnterFullScreenTemplate);
    if (image != nil) TGSendObject(self.touchBarFullscreenItem, NSSelectorFromString(@"setImage:"), image);
}

- (void)updateTouchBar {
    [self ensureTouchBarAttached];
    [self installSafariFullscreenItemIfNeeded];
    [self updateFullscreenButton];
    [self updateSafariEscapeKey];
    if (self.touchBarProvider != nil || self.touchBar == nil) {
        [self publishNowPlayingTitle:self.title rate:self.paused ? 0.0 : MAX(self.defaultPlaybackRate, 0.1)];
        return;
    }

    id playImage = TGImageNamed(self.paused
        ? NSImageNameTouchBarPlayTemplate
        : NSImageNameTouchBarPauseTemplate);
    if (playImage != nil) TGSendObject(self.touchBarPlayPauseItem, NSSelectorFromString(@"setImage:"), playImage);
    TGSendDouble(self.touchBarSlider, NSSelectorFromString(@"setMaxValue:"), MAX(self.duration, 1.0));
    TGSendDouble(self.touchBarSlider, NSSelectorFromString(@"setDoubleValue:"), self.elapsed);

    NSMutableArray *identifiers = [NSMutableArray array];
    if (self.touchBarPlayPauseItem != nil) [identifiers addObject:@"com.tony.grass.play-pause"];
    [identifiers addObject:@"com.tony.grass.video-scrubber"];
    if (self.pictureInPictureAvailable && self.touchBarPictureInPictureItem != nil) {
        [identifiers addObject:@"com.tony.grass.picture-in-picture"];
    }
    if (self.touchBarFullscreenItem != nil) [identifiers addObject:@"com.tony.grass.fullscreen-toggle"];
    TGSendObject(self.touchBar, NSSelectorFromString(@"setDefaultItemIdentifiers:"), identifiers);
    [self publishNowPlayingTitle:self.title rate:self.paused ? 0.0 : MAX(self.defaultPlaybackRate, 0.1)];
}

- (void)touchBarPlayPausePressed:(id)sender {
    (void)sender;
    [self evaluateCommand:@"toggle" value:nil];
}

- (void)touchBarPictureInPicturePressed:(id)sender {
    (void)sender;
    [self evaluateCommand:@"pip" value:nil];
}

- (void)touchBarFullscreenPressed:(id)sender {
    [self toggleMediaFullscreen:sender];
}

- (void)touchBarExitFullscreenPressed:(id)sender {
    if (self.mediaCinemaFullscreen) [self toggleMediaFullscreen:sender];
    else [self evaluateCommand:@"exitFullscreen" value:nil];
}

- (void)touchBarSliderChanged:(id)sender {
    double value = TGGetDouble(sender, NSSelectorFromString(@"doubleValue"));
    self.elapsed = value;
    [self evaluateCommand:@"seek" value:@(value)];
    [self publishNowPlayingTitle:self.title rate:self.paused ? 0.0 : 1.0];
}

- (void)publishNowPlayingTitle:(NSString *)title rate:(double)rate {
    if (self.duration <= 0.0) return;
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    info[MPMediaItemPropertyTitle] = title.length > 0 ? title : @"小草视频";
    info[MPMediaItemPropertyPlaybackDuration] = @(self.duration);
    info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = @(self.elapsed);
    info[MPNowPlayingInfoPropertyPlaybackRate] = @(rate);
    info[MPNowPlayingInfoPropertyDefaultPlaybackRate] = @1.0;
    info[MPNowPlayingInfoPropertyMediaType] = @(MPNowPlayingInfoMediaTypeVideo);
    info[MPNowPlayingInfoPropertyPlaybackProgress] = @(MIN(MAX(self.elapsed / self.duration, 0.0), 1.0));
    MPNowPlayingInfoCenter.defaultCenter.nowPlayingInfo = info;
    MPNowPlayingInfoCenter.defaultCenter.playbackState = self.paused
        ? MPNowPlayingPlaybackStatePaused
        : MPNowPlayingPlaybackStatePlaying;
}

- (void)clearMediaControls {
    MPNowPlayingInfoCenter.defaultCenter.nowPlayingInfo = nil;
    MPNowPlayingInfoCenter.defaultCenter.playbackState = MPNowPlayingPlaybackStateStopped;
    if (self.touchBarProvider != nil &&
        [self.touchBarProvider respondsToSelector:NSSelectorFromString(@"setPlaybackControlsController:")]) {
        TGSendObject(self.touchBarProvider, NSSelectorFromString(@"setPlaybackControlsController:"), nil);
    }
    NSWindow *hostWindow = self.touchBarHostWindow;
    if (hostWindow != nil && hostWindow != self.window && hostWindow.touchBar == self.touchBar) {
        hostWindow.touchBar = self.touchBarHostPreviousTouchBar;
    }
    NSResponder *hostResponder = self.touchBarHostResponder;
    if (hostResponder != nil && hostResponder.touchBar == self.touchBar) {
        hostResponder.touchBar = self.touchBarHostResponderPreviousTouchBar;
    }
    if (self.webView.touchBar == self.touchBar) self.webView.touchBar = nil;
    self.window.touchBar = self.previousTouchBar;
    self.touchBar = nil;
    self.touchBarProvider = nil;
    self.timing = nil;
    self.seekableTimeRanges = @[];
    self.touchBarSliderItem = nil;
    self.touchBarSlider = nil;
    self.touchBarPlayPauseItem = nil;
    self.touchBarPictureInPictureItem = nil;
    self.touchBarFullscreenItem = nil;
    self.touchBarExitFullscreenItem = nil;
    self.previousTouchBar = nil;
    self.touchBarHostWindow = nil;
    self.touchBarHostPreviousTouchBar = nil;
    self.touchBarHostResponder = nil;
    self.touchBarHostResponderPreviousTouchBar = nil;
    self.elapsed = 0.0;
    self.duration = 0.0;
    self.rate = 1.0f;
    self.defaultPlaybackRate = 1.0;
    self.paused = YES;
    self.pictureInPicture = NO;
    self.pictureInPictureAvailable = NO;
    self.fullscreen = NO;
    self.mediaFrame = nil;
}

- (void)setCinemaChromeHidden:(BOOL)hidden {
    self.classicTopBar.hidden = hidden;
    self.classicBottomBar.hidden = hidden;
    self.classicTopBarHeightConstraint.constant = hidden ? 0 : 64;
    self.classicBottomBarHeightConstraint.constant = hidden ? 0 : 49;
    self.progressIndicator.hidden = YES;
    [self.window.contentView layoutSubtreeIfNeeded];
}

- (void)leaveCinemaFullscreen {
    self.mediaFullscreenRequestGeneration += 1;
    [self evaluateCommand:@"cinema" value:@NO];
    [self evaluateTopFrameCommand:@"hostCinema" value:@NO];
    [self setCinemaChromeHidden:NO];
    self.mediaCinemaFullscreen = NO;
    [self updateTouchBar];
}

- (void)enterCinemaFullscreenFallback {
    if (self.mediaCinemaFullscreen || self.fullscreen) return;
    self.mediaCinemaFullscreen = YES;
    [self evaluateCommand:@"cinema" value:@YES];
    [self evaluateTopFrameCommand:@"hostCinema" value:@YES];
    [self setCinemaChromeHidden:YES];
    if ((self.window.styleMask & NSWindowStyleMaskFullScreen) == 0) {
        [self.window toggleFullScreen:nil];
    }
    [self updateTouchBar];
}

- (void)toggleMediaFullscreen:(id)sender {
    (void)sender;
    if (self.mediaCinemaFullscreen) {
        self.mediaFullscreenRequestGeneration += 1;
        if ((self.window.styleMask & NSWindowStyleMaskFullScreen) != 0) {
            [self.window toggleFullScreen:nil];
        } else {
            [self leaveCinemaFullscreen];
        }
        return;
    }
    if (self.fullscreen) {
        [self evaluateCommand:@"fullscreen" value:nil];
        return;
    }

    // Ask WebKit for the real media-player fullscreen first. Some embedded
    // players reject programmatic fullscreen because the JavaScript call no
    // longer carries browser user activation. If that happens, switch to a
    // video-only cinema window: the app chrome collapses and only the active
    // media/host iframe occupies the macOS fullscreen space.
    NSUInteger request = ++self.mediaFullscreenRequestGeneration;
    [self evaluateCommand:@"fullscreen" value:nil];
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        typeof(self) strongSelf = weakSelf;
        if (strongSelf == nil || request != strongSelf.mediaFullscreenRequestGeneration ||
            strongSelf.fullscreen || strongSelf.mediaCinemaFullscreen) return;
        [strongSelf enterCinemaFullscreenFallback];
    });
}

- (void)windowDidEnterFullScreen:(NSNotification *)notification {
    (void)notification;
    if (self.mediaCinemaFullscreen) {
        [self evaluateCommand:@"cinema" value:@YES];
        [self evaluateTopFrameCommand:@"hostCinema" value:@YES];
        [self setCinemaChromeHidden:YES];
    }
    [self refreshTouchBarPresentation];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [self refreshTouchBarPresentation];
    });
}

- (void)windowDidExitFullScreen:(NSNotification *)notification {
    (void)notification;
    if (self.mediaCinemaFullscreen) [self leaveCinemaFullscreen];
    [self refreshTouchBarPresentation];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [self refreshTouchBarPresentation];
    });
}

- (void)windowDidBecomeKey:(NSNotification *)notification {
    (void)notification;
    [self ensureTouchBarAttached];
    [self updateTouchBar];
}

#pragma mark - VidCatch companion

- (NSMutableURLRequest *)vidCatchRequestForPath:(NSString *)path method:(NSString *)method {
    NSURL *URL = [NSURL URLWithString:[TGVidCatchEndpoint stringByAppendingString:path]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    request.HTTPMethod = method;
    [request setValue:TGVidCatchToken forHTTPHeaderField:@"X-Video-Scout-Token"];
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    return request;
}

- (void)sendVidCatchStatus:(NSDictionary *)status {
    if (![NSJSONSerialization isValidJSONObject:status]) return;
    NSData *data = [NSJSONSerialization dataWithJSONObject:status options:0 error:nil];
    NSString *JSON = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSString *script = [NSString stringWithFormat:
        @"window.__tonyVidCatchStatus && window.__tonyVidCatchStatus(%@);", JSON ?: @"{}"];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.webView evaluateJavaScript:script completionHandler:nil];
        NSString *message = [status[@"message"] isKindOfClass:NSString.class] ? status[@"message"] : nil;
        if (message.length > 0) self.statusLabel.stringValue = message;
    });
}

- (void)failVidCatch:(NSString *)message {
    self.vidCatchJobID = nil;
    [self sendVidCatchStatus:@{
        @"status": @"error",
        @"message": message.length > 0 ? message : @"VidCatch 下载失败"
    }];
}

- (BOOL)cookie:(NSHTTPCookie *)cookie matchesURL:(NSURL *)URL {
    NSString *host = URL.host.lowercaseString ?: @"";
    NSString *domain = cookie.domain.lowercaseString ?: @"";
    while ([domain hasPrefix:@"."]) domain = [domain substringFromIndex:1];
    BOOL domainMatches = [host isEqualToString:domain] ||
        (domain.length > 0 && [host hasSuffix:[@"." stringByAppendingString:domain]]);
    if (!domainMatches) return NO;
    NSString *path = URL.path.length > 0 ? URL.path : @"/";
    NSString *cookiePath = cookie.path.length > 0 ? cookie.path : @"/";
    if (![path hasPrefix:cookiePath]) return NO;
    if (cookie.isSecure && ![URL.scheme.lowercaseString isEqualToString:@"https"]) return NO;
    return YES;
}

- (void)beginVidCatchDownload:(NSDictionary *)message {
    if (self.vidCatchJobID.length > 0) {
        [self sendVidCatchStatus:@{
            @"status": @"downloading",
            @"message": @"已有一个 VidCatch 下载任务正在进行",
            @"progress": @0
        }];
        return;
    }
    NSString *rawURL = [message[@"url"] isKindOfClass:NSString.class] ? message[@"url"] : @"";
    NSURL *mediaURL = [NSURL URLWithString:rawURL];
    if (mediaURL == nil ||
        (![[mediaURL.scheme lowercaseString] isEqualToString:@"http"] &&
         ![[mediaURL.scheme lowercaseString] isEqualToString:@"https"])) {
        [self failVidCatch:@"没有检测到可下载的 HTTP(S) 视频地址"];
        return;
    }

    __weak typeof(self) weakSelf = self;
    [self.webView.configuration.websiteDataStore.httpCookieStore getAllCookies:^(NSArray<NSHTTPCookie *> *cookies) {
        TGAppDelegate *strongSelf = weakSelf;
        if (strongSelf == nil) return;

        NSMutableDictionary *headers = [NSMutableDictionary dictionary];
        NSString *pageURL = [message[@"pageUrl"] isKindOfClass:NSString.class] ? message[@"pageUrl"] : @"";
        NSString *userAgent = [message[@"userAgent"] isKindOfClass:NSString.class] ? message[@"userAgent"] : @"";
        if (pageURL.length > 0) headers[@"Referer"] = pageURL;
        if (userAgent.length > 0) headers[@"User-Agent"] = userAgent;

        NSMutableArray<NSHTTPCookie *> *matching = [NSMutableArray array];
        for (NSHTTPCookie *cookie in cookies) {
            if ([strongSelf cookie:cookie matchesURL:mediaURL]) [matching addObject:cookie];
        }
        NSString *cookieHeader = [NSHTTPCookie requestHeaderFieldsWithCookies:matching][@"Cookie"];
        if (cookieHeader.length > 0) headers[@"Cookie"] = cookieHeader;

        NSString *title = [message[@"title"] isKindOfClass:NSString.class] ? message[@"title"] : @"小草视频";
        NSDictionary *payload = @{
            @"url": mediaURL.absoluteString,
            @"title": title.length > 0 ? title : @"小草视频",
            @"headers": headers,
            @"options": @{
                @"container": @"mp4",
                @"audioOnly": @NO,
                @"historyEnabled": @YES,
                @"maxConcurrent": @6,
                @"filenameTemplate": @"{title}"
            }
        };
        NSData *body = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];
        NSMutableURLRequest *request = [strongSelf vidCatchRequestForPath:@"/jobs" method:@"POST"];
        request.HTTPBody = body;
        [strongSelf sendVidCatchStatus:@{
            @"status": @"queued",
            @"message": @"正在连接 VidCatch companion…",
            @"progress": @0
        }];

        NSURLSessionDataTask *task = [strongSelf.vidCatchSession
            dataTaskWithRequest:request
            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                if (error != nil) {
                    [strongSelf failVidCatch:@"VidCatch companion 未运行。请先安装并启动 VidCatch v0.3.0。"];
                    return;
                }
                NSHTTPURLResponse *HTTP = [response isKindOfClass:NSHTTPURLResponse.class]
                    ? (NSHTTPURLResponse *)response
                    : nil;
                NSDictionary *JSON = data.length > 0
                    ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil]
                    : nil;
                NSDictionary *job = [JSON[@"job"] isKindOfClass:NSDictionary.class] ? JSON[@"job"] : nil;
                NSString *jobID = [job[@"id"] isKindOfClass:NSString.class] ? job[@"id"] : nil;
                if (HTTP.statusCode != 202 || jobID.length == 0) {
                    NSString *serverError = [JSON[@"error"] isKindOfClass:NSString.class]
                        ? JSON[@"error"]
                        : @"VidCatch 拒绝了下载任务";
                    [strongSelf failVidCatch:serverError];
                    return;
                }
                strongSelf.vidCatchJobID = jobID;
                [strongSelf sendVidCatchStatus:@{
                    @"status": @"probing",
                    @"message": @"正在分析视频轨道…",
                    @"progress": @0
                }];
                [strongSelf pollVidCatchAfterDelay:0.5];
            }];
        [task resume];
    }];
}

- (void)pollVidCatchAfterDelay:(NSTimeInterval)delay {
    NSString *jobID = self.vidCatchJobID;
    if (jobID.length == 0) return;
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        TGAppDelegate *strongSelf = weakSelf;
        if (strongSelf == nil || ![strongSelf.vidCatchJobID isEqualToString:jobID]) return;
        NSString *path = [@"/jobs/" stringByAppendingString:jobID];
        NSMutableURLRequest *request = [strongSelf vidCatchRequestForPath:path method:@"GET"];
        NSURLSessionDataTask *task = [strongSelf.vidCatchSession
            dataTaskWithRequest:request
            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                if (![strongSelf.vidCatchJobID isEqualToString:jobID]) return;
                if (error != nil) {
                    [strongSelf failVidCatch:@"VidCatch companion 已断开"];
                    return;
                }
                NSHTTPURLResponse *HTTP = [response isKindOfClass:NSHTTPURLResponse.class]
                    ? (NSHTTPURLResponse *)response
                    : nil;
                NSDictionary *JSON = data.length > 0
                    ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil]
                    : nil;
                NSDictionary *job = [JSON[@"job"] isKindOfClass:NSDictionary.class] ? JSON[@"job"] : nil;
                if (HTTP.statusCode != 200 || job == nil) {
                    [strongSelf failVidCatch:@"无法读取 VidCatch 下载状态"];
                    return;
                }
                NSString *status = [job[@"status"] isKindOfClass:NSString.class] ? job[@"status"] : @"queued";
                NSString *message = [job[@"message"] isKindOfClass:NSString.class] ? job[@"message"] : @"";
                NSNumber *progress = [job[@"progress"] isKindOfClass:NSNumber.class] ? job[@"progress"] : @0;
                [strongSelf sendVidCatchStatus:@{
                    @"status": status,
                    @"message": message,
                    @"progress": progress
                }];
                if ([status isEqualToString:@"complete"] || [status isEqualToString:@"error"] ||
                    [status isEqualToString:@"cancelled"]) {
                    strongSelf.vidCatchJobID = nil;
                } else {
                    [strongSelf pollVidCatchAfterDelay:1.0];
                }
            }];
        [task resume];
    });
}

@end

int main(int argc, const char *argv[]) {
    (void)argc;
    (void)argv;
    @autoreleasepool {
        NSApplication *application = NSApplication.sharedApplication;
        application.activationPolicy = NSApplicationActivationPolicyRegular;
        TGAppDelegate *delegate = [[TGAppDelegate alloc] init];
        application.delegate = delegate;
        [application run];
    }
    return 0;
}
