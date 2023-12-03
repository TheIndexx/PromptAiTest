//
//  imageView.swift
//  bruh
//
//  Created by Rishi Cadambe on 12/2/23.
//

import SwiftUI
import AVKit
import CoreML

struct closeUpImage: View {
    let item: Item
    
    var body: some View {
        if !item.isVideo, let imageData = item.imageData, let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(width: UIScreen.main.bounds.width)
                .clipped()
        }
        else if item.isVideo, let movieURL = item.videoData {
            VideoPlayer(player: AVPlayer(url: movieURL))
                .scaledToFit()
                .frame(width: UIScreen.main.bounds.width)
        }
    }
}

struct ImageView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>
    
    var item: Item
    @State private var firstImage = true
    @State private var currentIndex: Int = 0
    @State private var itemsArr: [Item] = []
    @State private var itemsArrDefined = false
    @State private var results: [String]?
    
    var body: some View {
        VStack {
            Spacer()
            if firstImage {
                closeUpImage(item: item)
                if !item.isVideo, let imgData = item.imageData {
                    Button("Run Object Detection") {
                        results = analyzeImage(image: UIImage(data: imgData))
                    }
                }
            } else {
                closeUpImage(item: itemsArr[currentIndex])
                if !itemsArr[currentIndex].isVideo,
                   let imgData = itemsArr[currentIndex].imageData {
                    Button("Run Object Detection") {
                        results = analyzeImage(image: UIImage(data: imgData))
                    }
                }
            }
            if let results {
                ForEach(results, id: \.self) { result in
                    let nlSep = result.components(separatedBy: ",")
                    if nlSep.count > 1,
                       let firstC = nlSep.first,
                       let lastC = nlSep.last,
                       let val = lastC.components(separatedBy: ": ").last {
                        Text("\(firstC): \(val)").foregroundStyle(.white)
                    } else {
                        Text("\(result)").foregroundStyle(.white)
                    }
                }
            }
            Spacer()
        }
        .gesture(DragGesture(minimumDistance: 20, coordinateSpace: .global)
            .onEnded { value in
                if !itemsArrDefined {
                    itemsArr = Array(items)
                    itemsArrDefined = true
                }
                if firstImage {
                    currentIndex = itemsArr.firstIndex(of: item) ?? 0
                }
                firstImage = false
                
                let horizontalAmount = value.translation.width
                if horizontalAmount < 0 { // Left Swipe, Image moves to Right
                    if currentIndex < itemsArr.count-1 {
                        currentIndex += 1
                    }
                } else { // Right Swipe, Image moves to Left
                    if currentIndex > 0 {
                        currentIndex -= 1
                    }
                }
        })
        .background(Color.black)
    }
    
    private func analyzeImage(image: UIImage?) -> [String] {
        guard let buffer = image?.resize(size: CGSize(width: 224, height: 224))?
                .getCVPixelBuffer() else {
            return []
        }

        do {
            let config = MLModelConfiguration()
            let model = try MobileNetV2_Int8_LUT(configuration: config)
            let input = MobileNetV2_Int8_LUTInput(image: buffer)

            let output = try model.prediction(input: input)
            let predictions = output.classLabelProbs.sorted { $0.value > $1.value }.prefix(5)
            let text = predictions.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
            let textSep = text.components(separatedBy: "\n")
            print(textSep)
            return textSep
        }
        catch {
            return [error.localizedDescription]
        }
    }
}

#Preview {
    GalleryView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
