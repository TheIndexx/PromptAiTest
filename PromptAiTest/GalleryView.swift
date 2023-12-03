//
//  GalleryView.swift
//  bruh
//
//  Created by Rishi Cadambe on 11/30/23.
//

import SwiftUI
import PhotosUI
import AVKit

struct TestView: View {
    var body: some View {
        Text("This is another view")
            .padding()
            .navigationTitle("Another View")
    }
}

struct GalleryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>
    
    @State private var isImagePickerPresented = false
    @State private var isDeleteButtonVisible = false
    @State private var itemToDelete: Item?
    @State private var mediaToAdd: PhotosPickerItem?
    @State private var newImageData: Data?
    @State private var newMovieData: Movie?
    @State private var isSelectedViewVisible = false
    @State private var initialSelectionToView: Item?
    @State private var isImageViewVisible = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                if items.isEmpty {
                    Text("No images available")
                } else {
                    NavigationLink(destination: SelectedView(initialSelection: initialSelectionToView ?? Item()), isActive: $isSelectedViewVisible) {
                        EmptyView()
                    }
                    NavigationLink(destination: ImageView(item: initialSelectionToView ?? Item()), isActive: $isImageViewVisible) {
                        EmptyView()
                    }
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                        ForEach(items) { item in
                            PhotoGridItem(newItem: item)
                            .onTapGesture {
                                initialSelectionToView = item
                                isImageViewVisible.toggle()
                            }
                            .onLongPressGesture {
                                initialSelectionToView = item
                                isSelectedViewVisible.toggle()
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Media Gallery")
            .navigationDestination(isPresented: $isSelectedViewVisible) {
                TestView()
            }
            .toolbar {
                ToolbarItem {
                    PhotosPicker(selection: $mediaToAdd, matching: .any(of: [.images, .videos])) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            .onChange(of: mediaToAdd) {
                Task {
                    do {
                        if let movie = try await mediaToAdd?.loadTransferable(type: Movie.self) {
                            saveItem(isVideo: true, vidURL: movie.url)
                        } else if let image = try await mediaToAdd?.loadTransferable(type: Data.self) {
                            saveItem(isVideo: false, imgData: image)
                        }
                    } catch {
                        newImageData = nil
                        newMovieData = nil
                    }
                }
            }
            .alert(isPresented: $isDeleteButtonVisible, content: {
                Alert(
                    title: Text("Delete Image?"),
                    message: nil,
                    primaryButton: .default(Text("Yes")) {
                        deleteImage()
                    },
                    secondaryButton: .cancel()
                )
            })
        }
    }
    
    private func saveItem(isVideo: Bool, imgData: Data? = nil, vidURL: URL? = nil) {
        print("Starting saveItem")
        var duplicateExists = false
        if isVideo, let vidURL {
            for item in items {
                if item.isVideo, item.videoData == vidURL {
                    print("Duplicate video exists!!")
                    duplicateExists = true
                }
            }
            if !duplicateExists {
                let newMovie = Item(context: viewContext)
                newMovie.id = UUID()
                newMovie.isVideo = true
                newMovie.videoData = vidURL
                newMovie.timestamp = Date()
                do {
                    try viewContext.save()
                } catch {
                    print("Error saving new video: \(error)")
                }
            }
        } else if !isVideo, let imgData {
            for item in items {
                if !item.isVideo, item.imageData == imgData {
                    print("Duplicate photo exists!!")
                    duplicateExists = true
                }
            }
            if !duplicateExists {
                print("Creating new photo")
                let newImage = Item(context: viewContext)
                newImage.id = UUID()
                newImage.isVideo = false
                newImage.imageData = imgData
                newImage.timestamp = Date()
                do {
                    try viewContext.save()
                } catch {
                    print("Error saving new photo: \(error)")
                }
            }
        }
    }
    
    private func deleteImage() {
        if let deletedImage = itemToDelete {
            viewContext.delete(deletedImage)
            do {
                try viewContext.save()
            } catch {
                print("Unresolved error \(error)")
            }
        }
        isDeleteButtonVisible.toggle()
    }
}

#Preview {
    GalleryView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
