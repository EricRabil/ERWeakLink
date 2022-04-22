# ERWeakLink

Weak linking for Swift with a splash of fun

## Weak link a function
```swift
let APSError: @convention(c) (CInt, NSString) -> NSError = ERWeakLinkSymbol("APSError", .privateFramework("ApplePushService"))!
let error = APSError(1, "generic error")
```

## Weak link a string
```swift
let AKServiceNameiMessage: NSString = ERWeakLinkSymbol("AKServiceNameiMessage", .privateFramework("AuthKit"))
print(AKServiceNameiMessage) // imessage
```

## Weak link an Objective-C class
```swift
@objc protocol AKAppleIDAuthenticationContext: NSObjectProtocol {
    @objc init()
    @objc var username: String { get set }
}
 
guard let AKAppleIDAuthenticationContext$: AKAppleIDAuthenticationContext.Type = ERWeakLinkObjC("AKAppleIDAuthenticationContext", .privateFramework("AuthKit")) else {
    fatalError("crap")
}
let context = AKAppleIDAuthenticationContext$.init()
context.username = "asdf"
```
