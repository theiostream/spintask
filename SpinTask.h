@interface SBAppSwitcherModel : NSObject
+ (id)sharedInstance;
- (id)identifiers;
@end

@interface SBApplication : NSObject
- (NSString *)displayIdentifier;
@end

@interface SBIconModel : NSObject
+ (id)sharedInstance;
- (NSString *)leafIconForIdentifier:(NSString *)identifier;
@end

@interface SBIcon : NSObject
- (UIImage *)generateIconImage:(int)type;
@end