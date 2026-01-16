#include "AppSealingiOS.h"
#include <thread>

/////////////////////////////////////////////////////////////////////////////// LEA AREA BEGIN : DO NOT DELETE THIS LINE !!!!
bool __se_use_lea;
unsigned char __se_iv[16], __se_key[16], __se_key_table[248620];
/////////////////////////////////////////////////////////////////////////////// LEA AREA END : DO NOT DELETE THIS LINE !!!!

// MARK: constants
extern const int kAppSealingErrorNone                = 0;
extern const int kAppSealingErrorJailbreakDetected   = 1 << 0;
extern const int kAppSealingErrorDRMDecrypted        = 1 << 1;
extern const int kAppSealingErrorDebugAttached       = 1 << 2;
extern const int kAppSealingErrorHashInfoCorrupted   = 1 << 3;
extern const int kAppSealingErrorCodesignCorrupted   = 1 << 4;
extern const int kAppSealingErrorHashModified        = 1 << 5;
extern const int kAppSealingErrorExecutableCorrupted = 1 << 6;
extern const int kAppSealingErrorCertificateChanged  = 1 << 7;
extern const int kAppSealingErrorBlacklistCorrupted  = 1 << 8;
extern const int kAppSealingErrorCheatToolDetected   = 1 << 9;

// MARK: main code

void iOS()
{
    Appsealing();
}

#if REACT_NATIVE_0_71
@implementation AppSealingInterfaceBridge
RCT_EXPORT_MODULE()

// Check the device for flash capabilities and return callback of success // or fail
// sync version
RCT_EXPORT_BLOCKING_SYNCHRONOUS_METHOD( IsAbnormalEnvironmentDetectedRN )
{
    return [NSString stringWithFormat:@"%d", ObjC_IsAbnormalEnvironmentDetected()];
}
// async version
RCT_EXPORT_METHOD( IsAbnormalEnvironmentDetectedAsync:( RCTPromiseResolveBlock )resolve rejecter:( RCTPromiseRejectBlock )reject )
{
    dispatch_async( dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 ), ^{
        int result = ObjC_IsAbnormalEnvironmentDetected();
        dispatch_async( dispatch_get_main_queue(), ^{
            resolve( @( result ));
        });
    });
}

RCT_EXPORT_BLOCKING_SYNCHRONOUS_METHOD( IsSwizzlingDetectedReturnRN )
{
  return [NSString stringWithFormat:@"%d", ObjC_IsSwizzlingDetectedReturn()];
}

RCT_EXPORT_METHOD( ExitApp )
{
    exit( 0 );
}
@end
#endif


@interface AppSealingInterface()
@end

@implementation AppSealingInterface
- (instancetype)init
{
    return self;
}

-(int)_IsAbnormalEnvironmentDetected
{
    return ObjC_IsAbnormalEnvironmentDetected() ;
}
-(void)_IsAbnormalEnvironmentDetectedAsync:(void (^)( int result ))completion
{
    std::thread([completion]()
    {
        int result = ObjC_IsAbnormalEnvironmentDetected();
        dispatch_async( dispatch_get_main_queue(), ^{
            completion( result );
        });
    }).detach();
}

char appSealingDeviceID[64];
-(const char*)_GetAppSealingDeviceID
{
    if( ObjC_GetAppSealingDeviceID( appSealingDeviceID ) == 0 )
    {
        return appSealingDeviceID;
    }
    return "";
}

char appSealingCredential[290];
-(const char*)_GetEncryptedCredential
{
    if( ObjC_GetEncryptedCredential( appSealingCredential ) == 0 )
    {
        return appSealingCredential;
    }
    return "";
}
- (void)_GetEncryptedCredentialAsync:(void (^)( const char *result ))completion
{
    std::thread([completion]()
    {
        char buffer[290] = {0};
        if ( ObjC_GetEncryptedCredential( buffer ) == 0 )
        {
            char* resultCopy = strdup( buffer );
            dispatch_async( dispatch_get_main_queue(), ^{
                completion( resultCopy );
                free( resultCopy );
            });
        }
        else
        {
            dispatch_async( dispatch_get_main_queue(), ^{
                completion( nullptr );
            });
        }
    }).detach();
}
+( NSString* )_DSS: ( NSString* )string  // Decrypt String  (for Objective-C / Swift)
{
    char* ret = ObjC_DecryptString(( char* )[string UTF8String] );
    return [NSString stringWithUTF8String:ret];
}
+( NSString* )_DSC: ( char* )string  // Decrypt String (for C++)
{
    char* ret = ObjC_DecryptString( string );
    return [NSString stringWithUTF8String:ret];
}

+(void)_NotifySwizzlingDetected: (void (^)(NSString*))handler
{
    dispatch_queue_t queue = dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 );
    dispatch_async( queue, ^{
        NSArray *messages = @[@"Unknown", @"Jailbreak detected !!!", @"Swizzling detected !!!", @"Hooking detected !!!", @"Cheat tool detected !!!", @"Integrity check failed !!!", @"Abnormal env detected !!!"];
        int ret = ObjC_IsSwizzlingDetected();        
        if (ret >= 1 && ret <= 5)
            dispatch_async( dispatch_get_main_queue(), ^{ handler(messages[ret]); } );
    } );
}

@end
