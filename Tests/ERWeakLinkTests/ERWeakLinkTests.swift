import XCTest
@_spi(weakLinkSearchPaths) @testable import ERWeakLink

@objc protocol AKAppleIDAuthenticationContext: NSObjectProtocol {
    @objc init()
    @objc var username: String { get set }
}

final class ERWeakLinkTests: XCTestCase {
    func testDlopen() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        let handles: [ERWeakLinkHandle] = [
            .privateFramework("IMCore"), .framework("CoreGraphics")
        ]
        
        for handle in handles {
            XCTAssertNotNil(handle.openFirstMatch(), "Couldn't dlopen \(handle.fileName)")
        }
    }
    
    func testObjCLinking() throws {
        guard let AKAppleIDAuthenticationContext$: AKAppleIDAuthenticationContext.Type = ERWeakLinkObjC("AKAppleIDAuthenticationContext", .privateFramework("AuthKit")) else {
            XCTFail("Missing class AKAppleIDAuthenticationContext from AuthKit")
            return
        }
        let context = AKAppleIDAuthenticationContext$.init()
        context.username = "timmy.cook@apple.com"
        XCTAssert(context.username == "timmy.cook@apple.com")
    }
    
    func testExternLinking() throws {
        guard let APSError: @convention(c) (CInt, NSString) -> NSError? = ERWeakLinkSymbol("APSError", .privateFramework("ApplePushService")) else {
            XCTFail("Missing extern APSError from ApplePushService")
            return
        }
        XCTAssert(APSError(1, "heyyyyy").map { $0.className == "NSError" } ?? false)
    }
    
    func testSymbolLinking() throws {
        guard let AKServiceNameiMessage: NSString = ERWeakLinkSymbol("AKServiceNameiMessage", .privateFramework("AuthKit")) else {
            return
        }
        print(ERWeakLinkSymbol("kMMProperty", .privateFramework("AOSAccounts")) as CFString)
        XCTAssertEqual(AKServiceNameiMessage, "imessage")
    }
}
