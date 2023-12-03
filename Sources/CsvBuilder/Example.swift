/// Just an example
struct ExampleComposition: CsvComposition {
    @CsvRows(
        column: "age"
    )
    var ages: [String]
    
    @CsvRows(
        column: "name"
    )
    var names: [String]
    
    init() {
        
    }
}
