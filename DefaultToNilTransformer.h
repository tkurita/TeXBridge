#import <Cocoa/Cocoa.h>

@interface DefaultToNilTransformer : NSValueTransformer {
	NSString *nilWord;
}
@property (retain, readwrite) NSString *nilWord;

@end
