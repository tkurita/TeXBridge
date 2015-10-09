#import "DVIPreviewModeTransformer.h"

@implementation DVIPreviewModeTransformer

+ (Class)transformedValueClass
{
	return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation
{
	return YES;
}

- (id)transformedValue:(NSNumber *)number
{
    int mode = [number intValue];
    switch (mode) {
        case 0:
            break;
        // shift an index because Mxdvi (index was 1) support was dropped.
        default:
            mode--;
            break;
    }
    
    return @(mode);
}

- (id)reverseTransformedValue:(NSNumber *)number
{
    int mode = [number intValue];
    switch (mode) {
        case 0:
            break;
        default:
            mode++;
            break;
    }
    
    return @(mode);
}

@end
