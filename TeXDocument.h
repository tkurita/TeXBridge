#import <Cocoa/Cocoa.h>


@interface TeXDocument : NSObject

@property NSURL *file;
@property NSString *textEncoding;
@property (retain) NSString *name;
@property (retain) NSString *pathWithoutSuffix;
@property BOOL hasMaster;

+ (TeXDocument *)frontTexDocumentReturningError:(NSError **)error;
+ (TeXDocument *)texDocumentWithPath:(NSString *)pathname textEncoding:(NSString *)encodingName;
- (TeXDocument *)resolveMasterFromEditorReturningError:(NSError **)error;

@end
