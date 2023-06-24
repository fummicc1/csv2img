import SwiftUI
import Csv2Img
import CsvBuilder


struct SecondContentView: View {
    @State private var composition: CsvCompositionExample = .init()
    @State private var image: CGImage?

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
            if let image = image {
                Image(nsImage: NSImage(cgImage: image, size: CGSize(width: image.width, height: image.height)))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
        }
        .padding()
        .task {
            let yamada = Csv.Row(index: 0, values: ["98", "Yamada"])
            let tanaka = Csv.Row(index: 0, values: ["99", "Tanaka"])
            let sato = Csv.Row(index: 0, values: ["100", "Sato"])
            let csv = try! CsvCompositionParser.parse(type: CsvCompositionExample.self, rows: [yamada, tanaka, sato,])
            let data = try! await csv.generate(fontSize: 20, exportType: .png)
            self.image = data.base as! CGImage
        }
    }
}

struct SecondContentView_Previews: PreviewProvider {
    static var previews: some View {
        SecondContentView()
    }
}
