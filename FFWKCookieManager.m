#import "FFWKCookieManager.h"
#import <WebKit/WebKit.h>

@interface FFWKCookieManager()<WKNavigationDelegate>
{
    NSString *_cookieJS;
}
@property (nonatomic,strong)  WKWebView *internalWebView;
@property (nonatomic,copy) dispatch_block_t completionBlock;
@end

@implementation FFWKCookieManager

+(instancetype)shared
{
    static FFWKCookieManager *__sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __sharedInstance = [[FFWKCookieManager alloc] init];
    });
    return __sharedInstance;
}

-(void)setCrossDomainCookie:(NSHTTPCookie *)cookie forWebView:(WKWebView *)webview completion:(dispatch_block_t)completion
{
    self.completionBlock = completion;
    NSString *nameJS = [NSString stringWithFormat:@"%@=%@",cookie.name,cookie.value];
    NSString *path = cookie.path.length>0 ? cookie.path : @"/";
    NSString *domainPathJS = [NSString stringWithFormat:@"domain=%@;path=%@",cookie.domain,path];

    _cookieJS = [NSString stringWithFormat:@"document.cookie ='%@;%@'",nameJS,domainPathJS];
    
    if (cookie.expiresDate) {
        _cookieJS = [_cookieJS stringByAppendingFormat:@"+';expires='+(new Date(%.0f)).toGMTString()",[cookie.expiresDate timeIntervalSince1970]*1000];
    }
    
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.processPool = webview.configuration.processPool;
    WKWebView *iwebView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
    NSString *schema = cookie.isSecure ? @"https" : @"http";
    NSString *url = [NSString stringWithFormat:@"%@://%@",schema,cookie.domain];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    iwebView.navigationDelegate = self;
    [iwebView loadRequest:request];
    iwebView.hidden = YES;
    _internalWebView = iwebView;
    
    [[UIApplication sharedApplication].keyWindow addSubview:iwebView];
}


- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    __weak FFWKCookieManager *wself = self;
    [webView evaluateJavaScript:_cookieJS completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        [wself.internalWebView removeFromSuperview];
        wself.internalWebView = nil;
        if (wself.completionBlock) {
            dispatch_block_t completionBlock = wself.completionBlock;
            wself.completionBlock = nil;
            completionBlock();
        }
    }];
}

@end
