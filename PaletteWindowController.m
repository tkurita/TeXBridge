#import "PaletteWindowController.h"

#define useLog 0

static id VisibilityController;

@implementation PaletteWindowController

+ (void)setVisibilityController:(id)theObj
{
	[theObj retain];
	[VisibilityController release];
	VisibilityController = theObj;
}

+ (id)visibilityController
{
	return VisibilityController;
}

#pragma mark init and actions
- (IBAction)showWindow:(id)sender
{
	[super showWindow:sender];
	[VisibilityController addWindowController:self];
	NSNotificationCenter *notiCenter = [NSNotificationCenter defaultCenter];
	[notiCenter addObserver:self selector:@selector(willApplicationQuit:) name:NSApplicationWillTerminateNotification object:nil];
}

- (void)dealloc
{
	[frameName release];
	[applicationsFloatingOn release];
	[contentViewBuffer release];
	
	[super dealloc];
}

- (void)setFrameName:(NSString *)theName
{
	[frameName autorelease];
	frameName = [theName retain];
}

#pragma mark methods for applications the window float on
- (void)useFloating
{
	NSWindow *theWindow = [self window];
	[theWindow setHidesOnDeactivate:NO];
	[theWindow setLevel:NSFloatingWindowLevel];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqualToString:applicationsFloatingOnKeyPath]) {
		NSArray *appList = [[[object values] valueForKey:applicationsFloatingOnEntryName] valueForKey:@"appName"];
		[self setApplicationsFloagingOn:appList];
	}
}

- (void)setApplicationsFloagingOnKeyPathFromKey:(NSString *)theKey
{
	[theKey retain];
	[applicationsFloatingOnEntryName release];
	applicationsFloatingOnEntryName = theKey;
	
	NSString *firstKey = @"values";
	NSString *keyPath = [firstKey stringByAppendingPathExtension:theKey];
	
	[keyPath retain];
	[applicationsFloatingOnKeyPath release];
	applicationsFloatingOnKeyPath = keyPath;
}

- (void)bindApplicationsFloatingOnForKey:(NSString *)theKey
{
#if useLog
	NSLog(@"start bindApplicationsFloatingOnForKey");
#endif
	[self setApplicationsFloagingOnKeyPathFromKey:theKey];
	NSUserDefaultsController *defaultsController = [NSUserDefaultsController sharedUserDefaultsController];
	NSArray *appList = [[[defaultsController values] valueForKey:theKey] valueForKey:@"appName"];
	[self setApplicationsFloagingOn:appList];
	[defaultsController addObserver:self forKeyPath:applicationsFloatingOnKeyPath options:NSKeyValueObservingOptionNew context:nil];
}

- (void)setApplicationsFloatingOnFromDefaultName:(NSString *)entryName
{
#if useLog
	NSLog(@"setApplicationsFloatingOnFromDefaultName");
#endif
	NSArray *appList = [[[NSUserDefaults standardUserDefaults] 
						arrayForKey:entryName] valueForKey:@"appName"];
	[self setApplicationsFloagingOn:appList];
}

- (void)setApplicationsFloagingOn:(NSArray *)appList
{
	[appList retain];
	[applicationsFloatingOn release];
	applicationsFloatingOn = appList;
}

#pragma mark methods for others
- (void)willApplicationQuit:(NSNotification *)aNotification
{
	[self saveDefaults];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)saveDefaults
{
	NSWindow *theWindow = [self window];
	if (!isCollapsed) [theWindow saveFrameUsingName:frameName];
}

#pragma mark methods for toggle visibility
- (BOOL)shouldUpdateVisibilityForApp:(NSString *)appName
{
	return [applicationsFloatingOn containsObject:appName];;
}

- (void)setVisibility:(BOOL)shouldShow
{
	NSWindow *theWindow = [self window];
	
	if (shouldShow){
		if (![theWindow isVisible]) {
			[theWindow orderBack:self];
		}
	}
	else {
		if ([theWindow isVisible]) {
			if ([theWindow attachedSheet] == nil) {
				[theWindow orderOut:self];
			}
		}
	}
}

#pragma mark methods for collapsing
- (BOOL)isCollapsed
{
	return isCollapsed;
}
- (float)titleBarHeight
{
	id theWindow = [self window];
	 NSRect windowRect = [theWindow frame];
	 NSRect contentRect = [NSWindow contentRectForFrameRect:windowRect
												  styleMask:[theWindow styleMask]];
	 //NSRect contentRect = [[theWindow contentView] frame];
	 return NSHeight(windowRect) - NSHeight(contentRect);
}

- (void)collapseAction
{
	[self toggleCollapseWithAnimate:NO];
}

- (void)toggleCollapseWithAnimate:(BOOL)flag
{
	NSWindow *theWindow = [self window];
	NSRect windowRect = [theWindow frame];

	if (isCollapsed) {
		windowRect.origin.y = windowRect.origin.y - expandedRect.size.height + windowRect.size.height;
		windowRect.size.height = expandedRect.size.height;
		[theWindow setFrame:windowRect display:YES animate:flag];
		[theWindow saveFrameUsingName:frameName];
		[theWindow setContentView:contentViewBuffer];
		isCollapsed = NO;
		
	}
	else {
		expandedRect = windowRect;
		NSRect contentRect = [NSWindow contentRectForFrameRect:windowRect styleMask:[theWindow styleMask]];
		windowRect.origin.y = windowRect.origin.y + NSHeight(contentRect);
		windowRect.size.height = NSHeight(windowRect) - NSHeight(contentRect);
		[theWindow saveFrameUsingName:frameName];
		[theWindow setContentView:nil];
		[theWindow setFrame:windowRect display:YES animate:flag];
		
		isCollapsed = YES;		
	}
}


- (void)useWindowCollapse
{
	isCollapsed = NO;
	id theWindow = [self window];
	contentViewBuffer = [[theWindow contentView] retain];
	NSButton *zoomButton = [theWindow standardWindowButton:NSWindowZoomButton];
	[zoomButton setTarget:self];
	[zoomButton setAction:@selector(collapseAction)];
}

#pragma mark delegates and overriding methods
- (void)windowDidLoad
{
	NSWindow *theWindow = [self window];
	[theWindow center];
	[theWindow setFrameUsingName:frameName];
	[super windowDidLoad];
}

- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)proposedFrameSize
{
	if (isCollapsed) {
		NSRect currentRect = [sender frame];
		return currentRect.size;
	}
	else {
		return proposedFrameSize;
	}
}

- (void)windowWillClose:(NSNotification *)aNotification
{
#if useLog
	NSLog(@"start windowWillClose:");
#endif
	[VisibilityController removeWindowController:self];
	[self saveDefaults];
}

- (BOOL)windowShouldClose:(id)sender
{
#if useLog
	NSLog(@"start windowShouldClose");
#endif
	[self saveDefaults];
	[VisibilityController removeWindowController:self];
	return YES;
}

@end
