//
//  LegacyRiskSanitizer.h
//  superDemoApp
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Tiny legacy surface kept in Objective-C to show incremental interop.
/// Stable Objective-C should migrate only when risk, crash data, or business value justify it.
@interface LegacyRiskSanitizer : NSObject

- (NSString *)normalizedRiskCodeFromTitle:(NSString *)title owner:(nullable NSString *)owner;

@end

NS_ASSUME_NONNULL_END
