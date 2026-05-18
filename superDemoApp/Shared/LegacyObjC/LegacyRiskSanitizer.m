//
//  LegacyRiskSanitizer.m
//  superDemoApp
//

#import "LegacyRiskSanitizer.h"

@implementation LegacyRiskSanitizer

- (NSString *)normalizedRiskCodeFromTitle:(NSString *)title owner:(nullable NSString *)owner {
    NSString *rawValue = owner.length > 0 ? [NSString stringWithFormat:@"%@-%@", owner, title] : title;
    NSCharacterSet *allowed = [NSCharacterSet alphanumericCharacterSet];
    NSMutableString *result = [NSMutableString string];

    for (NSUInteger index = 0; index < rawValue.length; index += 1) {
        unichar character = [rawValue characterAtIndex:index];
        if ([allowed characterIsMember:character]) {
            [result appendFormat:@"%C", character];
        } else if (result.length > 0 && ![result hasSuffix:@"-"]) {
            [result appendString:@"-"];
        }
    }

    NSString *trimmed = [result stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"-"]];
    return trimmed.uppercaseString;
}

@end
