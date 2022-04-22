import Foundation

public enum ERWeakLinkHandle: ExpressibleByStringLiteral, Hashable {
    /**
     Can be any kind of link handle
     */
    case string(String)
    case framework(String)
    case privateFramework(String)
    case dylib(String)
    case raw(UnsafeMutableRawPointer)
    
    public init(stringLiteral value: String) {
        self = .string(value)
    }
    
    private static let allSolidCases: [ERWeakLinkHandle] = [.framework(""), .privateFramework(""), .dylib("")]
    
    private var innerValue: String {
        switch self {
        case .raw: return ""
        case .string(let string), .dylib(let string), .framework(let string), .privateFramework(let string):
            return string
        }
    }
    
    private var fileExtension: String {
        switch self {
        case .framework, .privateFramework:
            return ".framework"
        case .dylib:
            return ".dylib"
        default:
            return ""
        }
    }
    
    public var fileName: String {
        innerValue.withExtension(fileExtension)
    }
    
    @_spi(weakLinkSearchPaths) public var searchPaths: [String] {
        switch self {
        case .raw, .string: return []
        case .framework: return Self.frameworkSearchPaths
        case .privateFramework: return Self.privateFrameworkSearchPaths
        case .dylib: return Self.librarySearchPaths
        }
    }
    
    @_spi(weakLinkSearchPaths) public var absoluteSearchPaths: [String] {
        switch self {
        case .framework(let innerValue), .privateFramework(let innerValue), .dylib(let innerValue):
            return searchPaths.lazy.map { $0.withExtension("/") + fileName + "/" + innerValue.withoutExtension(fileExtension) }
        case .string(let innerValue):
            return [innerValue]
        case .raw:
            return []
        }
    }
    
    /**
     Searches for the first existing
     */
    public func openFirstMatch(_ mode: Int32) -> UnsafeMutableRawPointer! {
        if case .raw(let image) = self {
            return image
        }
        for searchPath in absoluteSearchPaths {
            if let handle = dlopen(searchPath, mode) {
                return handle
            }
        }
        return nil
    }
    
    public func openFirstMatch() -> UnsafeMutableRawPointer! {
        openFirstMatch(RTLD_LAZY)
    }
}

public extension ERWeakLinkHandle {
    private static let _frameworkSearchPathsBase: [String] = [
        "/System/Library/Frameworks",
        "/Library/Frameworks",
        "/Library/Apple/Frameworks"
    ]
    
    static let frameworkSearchPaths: [String] = (_frameworkSearchPathsBase + [
        
    ])
    
    static let privateFrameworkSearchPaths: [String] = [
         "/System/Library/PrivateFrameworks",
        "/Library/PrivateFrameworks",
        "/Library/Apple/PrivateFrameworks"
    ]
    
    static let librarySearchPaths: [String] = [
        "/usr/lib", "/usr/local/lib", "/usr/homebrew/lib"
    ]
}

/**
 Links against a symbol by passing it to dlsym.
 
 ```
 let APSError: @convention(c) (CInt, NSString) -> NSError = ERWeakLinkSymbol("APSError", .privateFramework("ApplePushService"))!
 let error = APSError(1, "generic error")
 ```
 */
public func ERWeakLinkSymbol<T>(_ symbol: UnsafePointer<CChar>, _ handle: ERWeakLinkHandle!) -> T! {
    dlsym(handle?.openFirstMatch(), symbol).flatMap {
        if T.self is AnyObject.Type {
            return $0.assumingMemoryBound(to: T.self).pointee
        } else {
            return unsafeBitCast($0, to: T.self)
        }
    }
}

/**
 Links against a class that is accessible from the Objective-C runtime. Be careful (or don't, if that's the goal), types are not validated.
 
 ```
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
 */
public func ERWeakLinkObjC<T>(_ aClassName: String, _ handle: ERWeakLinkHandle!) -> T! {
    guard handle?.openFirstMatch() != nil else {
        return nil
    }
    guard let cls = NSClassFromString(aClassName) as? NSObject.Type else {
        return nil
    }
    return unsafeBitCast(cls, to: T.self)
}

extension String {
    func withoutExtension(_ fileExtension: String) -> String {
        if fileExtension.isEmpty || !self.hasSuffix(fileExtension) {
            return self
        }
        return String(self[...index(endIndex, offsetBy: -fileExtension.count)])
    }
    
    func withExtension(_ fileExtension: String) -> String {
        if fileExtension.isEmpty || hasSuffix(fileExtension) {
            return self
        }
        return self + fileExtension
    }
}
