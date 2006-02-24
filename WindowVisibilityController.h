#import <Cocoa/Cocoa.h>


@interface WindowVisibilityController : NSObject {
	NSMutableArray *_windowControllers;
	NSTimer *_displayToggleTimer;
	BOOL _isWorkedDisplayToggleTimer;
}

- (void)addWindowController:(id)windowController;
- (void)removeWindowController:(id)windowController;

- (void)setDisplayToggleTimer;
- (void)stopDisplayToggleTimer;
- (void)temporaryStopDisplayToggleTimer;
- (void)restartStopDisplayToggleTimer;
- (void)updateVisibility:(NSTimer *)theTimer;
- (BOOL)isWorkingDisplayToggleTimer;
- (int)judgeVisibilityForApp:(NSString *)appName;

@end
