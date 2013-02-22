#import <Cocoa/Cocoa.h>


@interface TeXDocument : NSObject {
	NSURL *file;
	NSString *textEncoding;
	NSString *name;
	NSString *pathWithoutSuffix;
	BOOL hasMaster;
}

@property (retain) NSURL *file;
@property (retain) NSString *textEncoding;
@property (retain) NSString *name;
@property (retain) NSString *pathWithoutSuffix;
@property BOOL hasMaster;

+ (TeXDocument *)frontTexDocumentReturningError:(NSError **)error;
+ (TeXDocument *)texDocumentWithPath:(NSString *)pathname textEncoding:(NSString *)encodingName;
- (TeXDocument *)resolveMasterFromEditor;

@end
