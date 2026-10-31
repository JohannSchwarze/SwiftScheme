public struct SchemeInterpreter {
    private var runtime: SchemeRuntime

    public init() throws {
        var runtime = SchemeRuntime(
            environment: SchemeEnvironment<SchemeEnvironmentLocation<SchemeValue>>()
        )
        try runtime.loadLibrary(SchemeStdlib())
        self.runtime = runtime
    }

    public mutating func load(source: String) throws {
        var parser = Parser(lexer: Lexer(data: source))
        let program = try parser.parseProgram()
        try runtime.loadProgram(program: program)
    }

    public func evaluate(source: String) throws -> String {
        var parser = Parser(lexer: Lexer(data: source))
        let expression = try parser.parseExpression()
        let value = try runtime.evaluate(expr: expression, env: runtime.environment)
        return runtime.print(value: value)
    }
}
