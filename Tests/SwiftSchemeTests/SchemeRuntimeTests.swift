@testable import SwiftScheme
import Testing




struct SchemeRuntimeTests {
    @Test func testBoolean01() throws {
        let runtime = SchemeRuntime(environment: SchemeEnvironment())
        let value = try runtime.evaluate("#t", env: SchemeEnvironment())
        let exp: SchemeValue = .boolean(value: true)
        #expect(exp == value)
    }

    @Test func testBoolean02() throws {
        let runtime = SchemeRuntime(environment: SchemeEnvironment())
        let value = try runtime.evaluate("#f", env: SchemeEnvironment())
        let exp: SchemeValue = .boolean(value: false)
        #expect(exp == value)
    }

    @Test func testNumber01() throws {
        let runtime = SchemeRuntime(environment: SchemeEnvironment())
        let value = try runtime.evaluate("12345", env: SchemeEnvironment())
        let exp: SchemeValue = .number(value: 12345)
        #expect(exp == value)
    }

    @Test func testVariable01() throws {
        let runtime = SchemeRuntime(environment: SchemeEnvironment())
        var env = SchemeEnvironment<SchemeValue>()
        env.bind(name: "x", value: .number(value: 12345))
        let value = try runtime.evaluate("x", env: env)
        let exp: SchemeValue = .number(value: 12345)
        #expect(exp == value)
    }

    @Test func testProcedures01() throws {
        let runtime = SchemeRuntime(environment: SchemeEnvironment())
        let value = try runtime.evaluate("((lambda (n) n) 5)", env: SchemeEnvironment())
        let exp: SchemeValue = .number(value: 5)
        #expect(exp == value)
    }

    @Test func testProcedures02() throws {
        let runtime = SchemeRuntime(environment: SchemeEnvironment())
        let value = try runtime.evaluate("((lambda (a b c) b) 1 2 3)", env: SchemeEnvironment())
        let exp: SchemeValue = .number(value: 2)
        #expect(exp == value)
    }

    @Test func testProcedures03() throws {
        let runtime = SchemeRuntime(environment: SchemeEnvironment())
        let value = try runtime.evaluate("((lambda (a b c) (a b c)) (lambda (b c) b) 2 3)", env: SchemeEnvironment())
        let exp: SchemeValue = .number(value: 2)
        #expect(exp == value)
    }

    @Test func testConditionals01() throws {
        let runtime = SchemeRuntime(environment: SchemeEnvironment())
        let value = try runtime.evaluate("(if #t 5 10)", env: SchemeEnvironment())
        let exp: SchemeValue = .number(value: 5)
        #expect(exp == value)
    }

    @Test func testConditionals02() throws {
        let runtime = SchemeRuntime(environment: SchemeEnvironment())
        let value = try runtime.evaluate("(if #f 5 10)", env: SchemeEnvironment())
        let exp: SchemeValue = .number(value: 10)
        #expect(exp == value)
    }
}