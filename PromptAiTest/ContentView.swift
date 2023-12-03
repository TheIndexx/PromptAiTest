////
////  ContentView.swift
////  ImageGallery
////
////  Created by Rishi Cadambe on 11/30/23.
////

import PhotosUI
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            FolderView().tabItem {
                Image(systemName: "folder.fill")
                Text("Folders")
            }
            GalleryView().tabItem {
                Image(systemName: "photo.on.rectangle")
                Text("Gallery")
            }
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
