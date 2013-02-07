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

@interface SBApplicationController : NSObject
- (SBApplication *)applicationWithDisplayIdentifier:(NSString *)displayID;
@end

@interface SBUIController : NSObject
- (void)activateApplicationFromSwitcher:(SBApplication *)app;
@end

@interface BKSWorkspace : NSObject
- (NSString *)topApplication;
@end

@interface SBWorksace : NSObject
- (BKSWorkspace *)bksWorkspace;
@end