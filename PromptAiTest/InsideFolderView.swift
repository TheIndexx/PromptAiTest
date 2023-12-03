//
//  DetailView.swift
//  bruh
//
//  Created by Rishi Cadambe on 12/1/23.
//

import SwiftUI
import PhotosUI
import AVKit

extension FolderEntity {
    public var itemsInThisFolder:[Item]{
        let set = folderToItem as? Set<Item> ?? []
        return set.sorted{
            $0.timestamp! < $1.timestamp!
        }
    }
}

extension Item {
    public var foldersWithThisItem:[FolderEntity]{
        let set = itemToFolder as? Set<FolderEntity> ?? []
        return set.sorted{
            $0.name! < $1.name!
        }
    }
}

struct Movie: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let copy = URL.documentsDirectory.appending(path: "movie.mp4")

            if FileManager.default.fileExists(atPath: copy.path()) {
                try FileManager.default.removeItem(at: copy)
            }

            try FileManager.default.copyItem(at: received.file, to: copy)
            return Self.init(url: copy)
        }
    }
}

struct ReceivedImage: Transferable {
    let url: URL
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(importedContentType: .image) { received in
            let copy: URL = URL(fileURLWithPath: "&lt;#...#>")
            try FileManager.default.copyItem(at: received.file, to: copy)
            return Self.init(url: copy)
        }
    }
}

struct PhotoGridItem: View {
    let newItem: Item
    
    var body: some View {
        if !newItem.isVideo, let imageData = newItem.imageData, let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: (UIScreen.main.bounds.width - 32) / 3, height: (UIScreen.main.bounds.width - 32) / 3)
                .cornerRadius(8)
        }
        else if newItem.isVideo, let movieURL = newItem.videoData {
            VideoPlayer(player: AVPlayer(url: movieURL))
                .scaledToFit()
                .frame(width: (UIScreen.main.bounds.width - 32) / 3, height: (UIScreen.main.bounds.width - 32) / 3)
                .cornerRadius(8)
        }
    }
}

struct DetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>
    var parentFolder: FolderEntity
    
    @State private var isImagePickerPresented = false
    @State private var isDeleteButtonVisible = false
    @State private var itemToDelete: Item?
    @State private var mediaToAdd: PhotosPickerItem?
    @State private var newImageData: Data?
    @State private var newMovieData: Movie?
    
    var body: some View {
        ScrollView {
            if items.isEmpty {
                Text("No images available")
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                    ForEach(parentFolder.itemsInThisFolder) { item in
                        PhotoGridItem(newItem: item)
                        .onTapGesture {
                            isDeleteButtonVisible.toggle()
                            itemToDelete = item
                        }
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle(parentFolder.name ?? "Unnamed")
        .toolbar {
            ToolbarItem {
                PhotosPicker(selection: $mediaToAdd, matching: .any(of: [.images, .videos])) {
                    Label("Add Item", systemImage: "plus")
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
    }
    
    private func saveItem(isVideo: Bool, imgData: Data? = nil, vidURL: URL? = nil) {
        print("Starting saveItem")
        var duplicateExists = false
        var matchingItemElsewhere: Item?
        if isVideo, let vidURL {
            for item in items {
                if item.isVideo, item.videoData == vidURL {
                    if item.foldersWithThisItem.contains(parentFolder) {
                        print("Duplicate video exists!!")
                        duplicateExists = true
                    }
                    matchingItemElsewhere = item
                }
            }
            if !duplicateExists {
                if let matchingItemElsewhere {
                    matchingItemElsewhere.addToItemToFolder(parentFolder)
                } else {
                    let newMovie = Item(context: viewContext)
                    newMovie.id = UUID()
                    newMovie.isVideo = true
                    newMovie.videoData = vidURL
                    newMovie.timestamp = Date()
                    newMovie.addToItemToFolder(parentFolder)
                    do {
                        try viewContext.save()
                    } catch {
                        print("Error saving new video: \(error)")
                    }
                }
            }
        } else if !isVideo, let imgData {
            for item in items {
                if !item.isVideo, item.imageData == imgData {
                    if item.foldersWithThisItem.contains(parentFolder) {
                        print("Duplicate photo exists!!")
                        duplicateExists = true
                    }
                    matchingItemElsewhere = item
                }
            }
            if !duplicateExists {
                if let matchingItemElsewhere { // If image uploaded to another folder, add folder to that image
                    print("Photo exists elsewhere")
                    matchingItemElsewhere.addToItemToFolder(parentFolder)
                } else { // Create new Item Entity
                    print("Creating new photo")
                    let newImage = Item(context: viewContext)
                    newImage.id = UUID()
                    newImage.isVideo = false
                    newImage.imageData = imgData
                    newImage.timestamp = Date()
                    newImage.addToItemToFolder(parentFolder)
                    print("New image folders:", newImage.foldersWithThisItem)
                    do {
                        try viewContext.save()
                    } catch {
                        print("Error saving new photo: \(error)")
                    }
                }
            }
        }
    }
    
    private func deleteImage() {
        if let deletedImage = itemToDelete {
            parentFolder.removeFromFolderToItem(deletedImage)
            do {
                try viewContext.save()
            } catch {
                print("Unresolved error \(error)")
            }
        }
        isDeleteButtonVisible.toggle()
    }
}
