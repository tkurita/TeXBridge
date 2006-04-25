#import <Cocoa/Cocoa.h>

@interface WindowVisibilityController : NSObject {
	NSMutableArray *_windowControllers;
	NSTimer *_displayToggleTimer;
	BOOL _isWorkedDisplayToggleTimer;
	BOOL _installedAppSwitchEvent;
}

- (void)addWindowController:(id)windowController;
- (void)removeWindowController:(id)windowController;

- (void)setDisplayToggleTimer;
- (void)stopDisplayToggleTimer;
- (void)temporaryStopDisplayToggleTimer;
- (void)restartStopDisplayToggleTimer;
- (void)updateVisibility;
- (BOOL)isWorkingDisplayToggleTimer;
- (int)judgeVisibilityForApp:(NSString *)appName;
- (void)setupAppChangeEvent;

@end
