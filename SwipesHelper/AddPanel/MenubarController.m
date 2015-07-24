#import "MenubarController.h"
#import "StatusItemView.h"

@interface MenubarController ()
@property (nonatomic, strong) NSStatusItem *realStatusItem;
@end

@implementation MenubarController

@synthesize statusItemView = _statusItemView;

#pragma mark -

- (id)init
{
    self = [super init];
    if (self != nil)
    {
        // Install status item into the menu bar
        NSStatusItem *statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:STATUS_ITEM_VIEW_WIDTH];
        statusItem.highlightMode = NO;
        _statusItemView = [[StatusItemView alloc] initWithStatusItem:statusItem];
        [self setStatusImage];
        _statusItemView.alternateImage = [NSImage imageNamed:@"StatusHighlighted"];
        _statusItemView.action = @selector(togglePanel:);
        [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(setStatusImage) name:@"AppleInterfaceThemeChangedNotification" object:nil];
    }
    return self;
}
-(void)setStatusImage{
    NSDictionary *dict = [[NSUserDefaults standardUserDefaults] persistentDomainForName:NSGlobalDomain];
    id style = [dict objectForKey:@"AppleInterfaceStyle"];
    BOOL darkModeOn = ( style && [style isKindOfClass:[NSString class]] && NSOrderedSame == [style caseInsensitiveCompare:@"dark"] );
    NSLog(@"%@",style);
    if (darkModeOn) {
        
        NSImage *statusImage = [NSImage imageNamed:@"StatusTemplate"];
        [statusImage setTemplate:YES];
        _statusItemView.image = statusImage;
    }
    else {
        NSImage *statusImage = [NSImage imageNamed:@"Status"];
        [statusImage setTemplate:YES];
        _statusItemView.image = statusImage;
    }
}
- (void)dealloc
{
    [[NSStatusBar systemStatusBar] removeStatusItem:self.statusItem];
}

#pragma mark -
#pragma mark Public accessors

- (NSStatusItem *)statusItem
{
    return self.statusItemView.statusItem;
}

#pragma mark -

- (BOOL)hasActiveIcon
{
    return self.statusItemView.isHighlighted;
}

- (void)setHasActiveIcon:(BOOL)flag
{
    self.statusItemView.isHighlighted = flag;
}

@end
