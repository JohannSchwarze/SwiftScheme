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
        var env = SchemeEnvironment<SchemeEnvironmentLocation<SchemeValue>>()
        env.bind(name: "x", value: SchemeEnvironmentLocation(value: .number(value: 12345)))
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


    @Test func testNativeProcedures01() throws {
        var runtime = SchemeRuntime(environment: SchemeEnvironment())
        try runtime.loadNativeProcedures()
        let value = try runtime.evaluate("(+ 3 7)", env: runtime.environment)
        let exp: SchemeValue = .number(value: 10)
        #expect(exp == value)
    }



    @Test func testProgram01() throws {
        var runtime = SchemeRuntime(environment: SchemeEnvironment())
        try runtime.loadNativeProcedures()

        let data = """
        (define fact
            (lambda (n)
                (if (< n 2) 1
                    (* n (fact (- n 1))))))
        """
        var parser = Parser(lexer: Lexer(data: data))
        let program = try parser.parseProgram()
        try runtime.loadProgram(program: program)

        let value = try runtime.evaluate("(fact 5)", env: runtime.environment)
        let exp: SchemeValue = .number(value: 120)
        #expect(exp == value)
    }

    @Test func testProgram02() throws {
        var runtime = SchemeRuntime(environment: SchemeEnvironment())
        try runtime.loadNativeProcedures()

        let data = """
        (define fib
             (lambda (n)
                (if (< n 2) n
                     (+ (fib (- n 1)) (fib (- n 2))))))
        """
        var parser = Parser(lexer: Lexer(data: data))
        let program = try parser.parseProgram()
        try runtime.loadProgram(program: program)

        #expect(try runtime.evaluate("(fib 1)", env: runtime.environment) == .number(value: 1))
        #expect(try runtime.evaluate("(fib 2)", env: runtime.environment) == .number(value: 1))
        #expect(try runtime.evaluate("(fib 3)", env: runtime.environment) == .number(value: 2))
        #expect(try runtime.evaluate("(fib 4)", env: runtime.environment) == .number(value: 3))
        #expect(try runtime.evaluate("(fib 5)", env: runtime.environment) == .number(value: 5))
        #expect(try runtime.evaluate("(fib 6)", env: runtime.environment) == .number(value: 8))
        #expect(try runtime.evaluate("(fib 7)", env: runtime.environment) == .number(value: 13))
    }

}