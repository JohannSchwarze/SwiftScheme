

enum SchemeEnvironmentError: Error {
    case unboundVariable(name: String)
}



struct SchemeEnvironment<T: Equatable>: Equatable {
    var locations: [[String : T]] = [[:]]





    mutating func bind(name: String, value: T) {
        locations[locations.count - 1].updateValue(value, forKey: name)
    }

    mutating func pushRegion() {
        self.locations.append([:])
    }

    mutating func popRegion() {
        self.locations.removeLast()
    }

    func value(name: String) throws -> T {
        for i in stride(from: locations.count - 1, through: 0, by: -1) {
            let value = locations[i][name]
            if let value {
                return value
            }
        }

        throw SchemeEnvironmentError.unboundVariable(name: name)
    }
}





class SchemeEnvironmentLocation<T> {
    let value: T

    init(value: T) {
        self.value = value
    }
}