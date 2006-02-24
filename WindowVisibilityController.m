#import "WindowVisibilityController.h"
#import "miClient.h"
#import "PaletteWindowController.h"

#define useLog 0

static id sharedObj;
extern id EditorClient;

@implementation WindowVisibilityController

- (id)init
{
	if (self = [super init]) {
		_windowControllers = [[NSMutableArray alloc] init];;
	}
	
	if (sharedObj == nil) {
		sharedObj = self;
	}
	
	return self;
}

- (void) dealloc {
	[_windowControllers release];
	[super dealloc];
}

- (void)addWindowController:(id)windowController
{
	if (_displayToggleTimer == nil) {
		[self setDisplayToggleTimer];
	}
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
	if ([appName isEqualToString:@"mi"]) {
		NSString *theMode = [EditorClient currentDocumentMode];
		if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"SupportedModes"]
				containsObject:theMode]) {
			return 1;
		} else {
			return 0;
		}
	}
	
	return -1;
}

- (void)updateVisibility:(NSTimer *)theTimer
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
	_displayToggleTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateVisibility:) userInfo:nil repeats:YES];
	[_displayToggleTimer retain];
}

@end
