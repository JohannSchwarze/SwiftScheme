import Foundation
import SwiftScheme

@main
struct SwiftSchemeCLI {
    static func main() {
        do {
            var interpreter = try SchemeInterpreter()

            for file in CommandLine.arguments.dropFirst() {
                let source = try String(contentsOfFile: file, encoding: .utf8)
                print("Loading \(file) ...")
                try interpreter.load(source: source)
            }

            let prompt = "> "
            while true {
                print(prompt, terminator: "")
                guard let line = readLine() else { break }
                print(try interpreter.evaluate(source: line))
            }
        } catch {
            print(error.localizedDescription)
        }
    }
}