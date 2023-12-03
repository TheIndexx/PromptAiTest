//
//  imageView.swift
//  bruh
//
//  Created by Rishi Cadambe on 12/2/23.
//

import SwiftUI
import AVKit

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
    
    var body: some View {
        VStack {
            Spacer()
            if firstImage {
                closeUpImage(item: item)
            } else {
                closeUpImage(item: itemsArr[currentIndex])
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
        .toolbar {
            ToolbarItem {
                Button("Text") {
                    
                }
            }
        }
    }
}

#Preview {
    GalleryView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
