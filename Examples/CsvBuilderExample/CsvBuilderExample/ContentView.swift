import CsvBuilder
import SwiftUI

struct ContentView: View {

    @State private var composition: CsvCompositionExample = .init()
    @State private var image: CGImage?

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
            if let image = image {
                Image(
                    nsImage: NSImage(
                        cgImage: image, size: CGSize(width: image.width, height: image.height))
                )
                .resizable()
                .aspectRatio(contentMode: .fit)
            }
        }
        .padding()
        .task {
            composition = .init()
            composition.ages.append(contentsOf: ["98", "99", "100"])
            composition.names.append(contentsOf: ["Yamada", "Tanaka", "Sato"])
            let csv = try! composition.build()
            let data = try! await csv.generate(fontSize: 20, exportType: .png)
            self.image = data.base as! CGImage
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
