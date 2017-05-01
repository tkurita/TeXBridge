#import "AppleEventExtra.h"


@implementation NSAppleEventDescriptor (AppleEventExtra)

+ (NSAppleEventDescriptor *)descriptorWithShort:(short)a_value
{
	return [self descriptorWithDescriptorType:typeSInt16 
										bytes:&a_value
									   length:sizeof(a_value)];
}

+ (NSAppleEventDescriptor *)descriptorWithUnsignedShort:(unsigned short)a_value
{
	return [self descriptorWithDescriptorType:typeUInt16 
										bytes:&a_value
									   length:sizeof(a_value)];
}

+ (NSAppleEventDescriptor *)descriptorWithUnsignedLong:(unsigned long)a_value
{
	return [self descriptorWithDescriptorType:typeUInt32 
										bytes:&a_value
									   length:sizeof(a_value)];
}

+ (NSAppleEventDescriptor *)descriptorWithLongLong:(long long)a_value
{
	return [self descriptorWithDescriptorType:typeSInt64 
										bytes:&a_value
									   length:sizeof(a_value)];
}

+ (NSAppleEventDescriptor *)descriptorWithUnsignedLongLong:(unsigned long long)a_value
{
	return [self descriptorWithDescriptorType:typeUInt64 
										bytes:&a_value
									   length:sizeof(a_value)];
}

+ (NSAppleEventDescriptor *)descriptorWithFloat:(float)a_value
{
	return [self descriptorWithDescriptorType:typeIEEE32BitFloatingPoint 
										bytes:&a_value
									   length:sizeof(a_value)];
}

+ (NSAppleEventDescriptor *)descriptorWithDouble:(double)a_value
{
	return [self descriptorWithDescriptorType:typeIEEE32BitFloatingPoint 
										bytes:&a_value
									   length:sizeof(a_value)];
}
@end

@implementation NSString (AppleEventExtra)
- (NSAppleEventDescriptor *)appleEventDescriptor
{
	return [NSAppleEventDescriptor descriptorWithString:self];
}
@end

@implementation NSNumber (AppleEventExtra)
- (NSAppleEventDescriptor *)appleEventDescriptor
{
	const char *type = [self objCType];

	if(strcmp(type, @encode(BOOL)) == 0)
		return [NSAppleEventDescriptor descriptorWithBoolean:[self boolValue]];
	else if(strcmp(type, @encode(short)) == 0)
		return [NSAppleEventDescriptor descriptorWithShort:[self shortValue]];
	else if(strcmp(type, @encode(unsigned short)) == 0)
		return [NSAppleEventDescriptor descriptorWithUnsignedShort:[self unsignedShortValue]];
	else if(strcmp(type, @encode(int)) == 0)
		return [NSAppleEventDescriptor descriptorWithInt32:[self intValue]];
	else if(strcmp(type, @encode(unsigned int)) == 0)
		return [NSAppleEventDescriptor descriptorWithUnsignedLong:[self unsignedIntValue]];
	else if(strcmp(type, @encode(long)) == 0)
		return [NSAppleEventDescriptor descriptorWithInt32:(int)[self longValue]];
	else if(strcmp(type, @encode(unsigned long)) == 0)
		return [NSAppleEventDescriptor descriptorWithUnsignedLong:[self unsignedLongValue]];
	else if(strcmp(type, @encode(float)) == 0)
		return [NSAppleEventDescriptor descriptorWithFloat:[self floatValue]];
	else if(strcmp(type, @encode(double)) == 0)
		return [NSAppleEventDescriptor descriptorWithDouble:[self doubleValue]];
	
	return nil;
}


@end
