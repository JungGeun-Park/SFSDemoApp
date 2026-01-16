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
#import <React/RCTLog.h>
@implementation AppSealingInterfaceBridge
RCT_EXPORT_MODULE()

// Check the device for flash capabilities and return callback of success // or fail
// sync version
RCT_EXPORT_BLOCKING_SYNCHRONOUS_METHOD( IsAbnormalEnvironmentDetectedRN )
{
    RCTLogWarn(
        @"[AppSealing] IsAbnormalEnvironmentDetectedRN is deprecated. "
        @"Use IsAbnormalEnvironmentDetectedAsyncRN instead."
    );

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"        
    return [NSString stringWithFormat:@"%d", ObjC_IsAbnormalEnvironmentDetected()];
#pragma clang diagnostic pop
}
// async version
RCT_EXPORT_METHOD( IsAbnormalEnvironmentDetectedAsyncRN:( RCTPromiseResolveBlock )resolve rejecter:( RCTPromiseRejectBlock )reject )
{
    // completion == resolve
    [[[AppSealingInterface alloc] init] _IsAbnormalEnvironmentDetectedAsync:^( int result )
    {
        @try
        {
            resolve( @( result ));   // JS: number
        }
        @catch( NSException *exception )
        {
            reject( @"APPSEALING_RESOLVE_EXCEPTION", exception.reason ?: @"Unknown exception", nil );
        }
    }];
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
    if ( !completion )
        return;

    void ( ^completionCopy )( int ) = [completion copy];

    std::thread( [completionCopy]()
    {
        int result = 0;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"        
        @try
        {
            result = ObjC_IsAbnormalEnvironmentDetected();
        }
        @catch( NSException *exception )
        {
            result = 0;
        }
#pragma clang diagnostic pop
        dispatch_async( dispatch_get_main_queue(), ^{
            @try
            {
                if ( completionCopy )
                    completionCopy( result );
            }
            @catch( NSException *exception )
            {
            }
        });

   } ).detach();
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
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"        
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
#pragma clang diagnostic pop
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

- (BOOL)_EncryptData:(NSData*)plain iv:(NSData*)iv cipherOut:(NSMutableData*)cipherOut outLen:(size_t*)outLen
{
    if ( iv.length != 16 || !plain )
        return NO;
    cipherOut.length = plain.length + 32;
    BOOL result = SecureStorage_AES256_Encrypt(( uint8_t* )plain.bytes, plain.length, ( uint8_t* )iv.bytes, ( uint8_t* )cipherOut.mutableBytes, outLen ) == 0;
    if ( !result )
        cipherOut.length = 0;
    else
        cipherOut.length = *outLen;
    return result;
}

- (BOOL)_DecryptData:(NSData*)cipher iv:(NSData*)iv plainOut:(NSMutableData*)plainOut outLen:(size_t*)outLen
{
    if ( iv.length != 16 || !cipher )
        return NO;
    plainOut.length = cipher.length + 32;
    BOOL result = SecureStorage_AES256_Decrypt(( uint8_t* )cipher.bytes, cipher.length, ( uint8_t* )iv.bytes, ( uint8_t* )plainOut.mutableBytes, outLen ) == 0;
    if ( !result )
        plainOut.length = 0;
    else
        plainOut.length = *outLen;
    return result;
}

- (NSString *)_EncryptString:(NSString*)plain iv:(NSData*)iv
{
    NSData *plainData = [plain dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableData *cipherData = [NSMutableData dataWithLength:plainData.length + 32];
    size_t outLen = 0;
    BOOL result = [self _EncryptData:plainData iv:iv cipherOut:cipherData outLen:&outLen];
    if ( !result )
        return nil;
    cipherData.length = outLen;
    // Base64 encode for string-safe output
    return [cipherData base64EncodedStringWithOptions:0];
}

- (NSString *)_DecryptString:(NSString*)cipherBase64 iv:(NSData*)iv
{
    NSData *cipherData = [[NSData alloc] initWithBase64EncodedString:cipherBase64 options:0];
    NSMutableData *plainData = [NSMutableData dataWithLength:cipherData.length + 32];
    size_t outLen = 0;
    BOOL result = [self _DecryptData:cipherData iv:iv plainOut:plainData outLen:&outLen];
    if ( !result )
        return nil;
    plainData.length = outLen;
    return [[NSString alloc] initWithData:plainData encoding:NSUTF8StringEncoding];
}
@end
