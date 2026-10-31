@testable import SwiftScheme
import Testing





struct SchemeStdlibTests {
    @Test func test_not() throws {
        var runtime = SchemeRuntime(environment: SchemeEnvironment())
        try runtime.loadLibrary(SchemeStdlib())

        #expect(try runtime.evaluate("(not #t)", env: runtime.environment) == .boolean(value: false))
        #expect(try runtime.evaluate("(not 3)", env: runtime.environment) == .boolean(value: false))
        #expect(try runtime.evaluate("(not #f)", env: runtime.environment) == .boolean(value: true))
        #expect(try runtime.evaluate("(not '())", env: runtime.environment) == .boolean(value: false))
    }

    @Test func test_boolean_pred() throws {
        var runtime = SchemeRuntime(environment: SchemeEnvironment())
        try runtime.loadLibrary(SchemeStdlib())

        #expect(try runtime.evaluate("(boolean? #f)", env: runtime.environment) == .boolean(value: true))
        #expect(try runtime.evaluate("(boolean? #t)", env: runtime.environment) == .boolean(value: true))
        #expect(try runtime.evaluate("(boolean? 0)", env: runtime.environment) == .boolean(value: false))
    }
}