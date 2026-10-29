import XCTest

final class CliAccessPolicyTests: XCTestCase {
    func testOrdinaryAndDebugLaunchesKeepPortClosed() {
        for arguments in [["AltTab"], ["AltTab", "--logs=debug"], ["AltTab", "--qa-lifecycle-session=7DDFB849-5918-4B1A-AB44-EE663F73C336"]] {
            XCTAssertFalse(CliAccessPolicy.isEnabled(arguments: arguments))
        }
    }

    func testExplicitOptInEnablesPort() {
        XCTAssertTrue(CliAccessPolicy.isEnabled(arguments: ["AltTab", "--logs=debug", "--enable-cli"]))
    }

    func testExecutableNameAndSimilarFlagsDoNotOptIn() {
        for arguments in [["--enable-cli"], ["AltTab", "--enable-cli=false"], ["AltTab", "--enable-cli-extra"]] {
            XCTAssertFalse(CliAccessPolicy.isEnabled(arguments: arguments))
        }
    }
}
