



indirect enum DatumKind: Equatable {
    case boolean(value: Bool)
    case number(value: Int)
    case symbol(value: String)
    case list(value: [Datum])
}


struct Datum: Equatable {
    let start: Int
    let end: Int
    let kind: DatumKind
}










