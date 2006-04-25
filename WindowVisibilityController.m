#import <Carbon/Carbon.h>
#import "WindowVisibilityController.h"
#import "miClient.h"
#import "PaletteWindowController.h"

#define useLog 0

static id sharedObj;
extern id EditorClient;

#define TIMERINVERVAL 1

static OSStatus appSwitched(EventHandlerCallRef nextHandler, EventRef theEvent, void* userData)
{
    [(id)userData updateVisibility];
	return(CallNextEventHandler(nextHandler, theEvent));
}

@implementation WindowVisibilityController

- (id)init
{
	if (self = [super init]) {
		_windowControllers = [[NSMutableArray alloc] init];;
	}
	
	if (sharedObj == nil) {
		sharedObj = self;
	}
	_installedAppSwitchEvent = NO;
	return self;
}

- (void) dealloc
{
	[_windowControllers release];
	[super dealloc];
}

- (void)addWindowController:(id)windowController
{
	if (_displayToggleTimer == nil) {
		[self setDisplayToggleTimer];
		[self setupAppChangeEvent];
		_installedAppSwitchEvent = YES;
	}

/*	if (!_installedAppSwitchEvent) {
		[self setupAppChangeEvent];
		_installedAppSwitchEvent = YES;
	}*/
	[_windowControllers addObject:windowController];
}

- (void)removeWindowController:(id)windowController
{
	[_windowControllers removeObject:windowController];
	if ([_windowControllers count] == 0) {
		[self stopDisplayToggleTimer];
	}
}

- (BOOL)isWorkingDisplayToggleTimer
{
	if (_displayToggleTimer == nil) return NO;
	return [_displayToggleTimer isValid];
}

- (int)judgeVisibilityForApp:(NSString *)appName
{
	/*
	result = -1 : can't judge in this routine
		0 : should hide	
		1: should show
		2: should not change
	*/
	if ([appName isEqualToString:[EditorClient name]]) {
		NSString *theMode;
		@try{
			theMode = [EditorClient currentDocumentMode];
		}
		@catch(NSException *exception){
			NSNumber *err = [[exception userInfo] objectForKey:@"result code"];
			if ([err intValue] == -1704) {
				// maybe menu is opened
				return 2;
			}
			else {
				// maybe no documents opened
				return 0;
			}	
		}
		
		if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"SupportedModes"]
				containsObject:theMode]) {
			return 1;
		} else {
			return 0;
		}
	}
	
	return -1;
}

- (void)updateVisibilityWithTimer:(NSTimer *)theTimer
{
	[self updateVisibility];
}

- (void)updateVisibility
{
#if useLog
	NSLog(@"updateVisibility:");
#endif
	NSString *appName = [[[NSWorkspace sharedWorkspace] activeApplication] objectForKey:@"NSApplicationName"];
	if (appName == nil) {
		return;
	}
	
	NSEnumerator *enumerator = [_windowControllers objectEnumerator];
	int showFlag = [self judgeVisibilityForApp:appName];
	id theObj;
	BOOL shouldShow = YES;
	while(theObj = [enumerator nextObject]) {
		switch (showFlag) {
			case -1 : 
				shouldShow = [theObj shouldUpdateVisibilityForApp:appName];
				break;
			case 0 :
				shouldShow = NO;
				break;
			case 1 : 
				shouldShow = YES;
				break;
			case 2 :
				return;
		}
		[theObj setVisibility:shouldShow];
	}
}

- (void)restartStopDisplayToggleTimer
{
	if (_isWorkedDisplayToggleTimer) {
		[self setDisplayToggleTimer];
	}
}

- (void)temporaryStopDisplayToggleTimer
{
	if (_displayToggleTimer != nil) {
		[_displayToggleTimer invalidate];
		[_displayToggleTimer release];
		_displayToggleTimer = nil;		
		_isWorkedDisplayToggleTimer = YES;
	}
	else {
		_isWorkedDisplayToggleTimer = NO;
	}
}

- (void)stopDisplayToggleTimer
{
	if (_displayToggleTimer != nil) {
		[_displayToggleTimer invalidate];
		[_displayToggleTimer release];
		_displayToggleTimer = nil;
	}
}

- (void)setDisplayToggleTimer
{
	if (_displayToggleTimer != nil) {
		[_displayToggleTimer invalidate];
	}
	[_displayToggleTimer release];
	_displayToggleTimer = [NSTimer scheduledTimerWithTimeInterval:TIMERINVERVAL target:self selector:@selector(updateVisibilityWithTimer:) userInfo:nil repeats:YES];
	[_displayToggleTimer retain];
}

- (void)setupAppChangeEvent {
    EventTypeSpec spec = { kEventClassApplication,  kEventAppFrontSwitched };
	EventHandlerUPP handlerUPP = NewEventHandlerUPP(appSwitched);
    OSStatus err = InstallApplicationEventHandler(handlerUPP, 1, &spec, (void*)self, NULL);
	if (err != noErr) NSLog(@"fail to InstallApplicationEventHandler");
	DisposeEventHandlerUPP(handlerUPP);
}
@end
