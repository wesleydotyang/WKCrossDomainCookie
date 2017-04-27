#import <Foundation/Foundation.h>
#import <WebKit/WKWebView.h>

@interface FFWKCookieManager : NSObject

+(instancetype)shared;

-(void)setCrossDomainCookie:(NSHTTPCookie*)cookie forWebView:(WKWebView*)webview completion:(dispatch_block_t)completion;

@end
