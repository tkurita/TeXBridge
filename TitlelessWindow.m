#import "TitlelessWindow.h"


@implementation TitlelessWindow
- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle
                  backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {
	self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask
                                                 backing:bufferingType defer:flag];
    [self setLevel: NSStatusWindowLevel];
    [self setAlphaValue:0.8];
	[self center];
    return self;
}
@end
