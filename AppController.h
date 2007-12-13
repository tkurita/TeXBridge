/* AppController */

#import <Cocoa/Cocoa.h>
#import "miClient.h"

NSArray *orderdEncodingCandidates(NSString *firstCandidateName);

@interface AppController : NSObject
{
	IBOutlet id startupWindow;
	
	NSTimer *appQuitTimer;
	NSDictionary *factoryDefaults;
}

+ (id)sharedAppController;

- (void)anApplicationIsTerminated:(NSNotification *)aNotification;
- (void)checkQuit:(NSTimer *)aTimer;
- (id)factoryDefaultForKey:(NSString *)theKey;
- (void)revertToFactoryDefaultForKey:(NSString *)theKey;

@end


