//
//  GalleryView.swift
//  bruh
//
//  Created by Rishi Cadambe on 12/2/23.
//

import SwiftUI
import PhotosUI
import AVKit

struct SelectedPhotoGridItem: View {
    let newItem: Item
    
    var body: some View {
        if !newItem.isVideo, let imageData = newItem.imageData, let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: (UIScreen.main.bounds.width - 130) / 3, height: (UIScreen.main.bounds.width - 130) / 3)
                .cornerRadius(8)
        }
        else if newItem.isVideo, let movieURL = newItem.videoData {
            VideoPlayer(player: AVPlayer(url: movieURL))
                .scaledToFit()
                .frame(width: (UIScreen.main.bounds.width - 130) / 3, height: (UIScreen.main.bounds.width - 130) / 3)
                .cornerRadius(8)
        }
    }
}

struct SelectedView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FolderEntity.name, ascending: true)],
        animation: .default)
    private var folders: FetchedResults<FolderEntity>
    
    let initialSelection: Item
    @State private var itemToDelete: Item?
    @State private var selectedItems: [Item] = []
    @State private var isPopoverPresented = false
    
    init(initialSelection: Item) {
        self.initialSelection = initialSelection
        self._selectedItems = State(initialValue: [initialSelection])
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                if items.isEmpty {
                    Text("No images available")
                } else {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                        ForEach(items) { item in
                            if selectedItems.contains(item) {
                                SelectedPhotoGridItem(newItem: item)
                                    .onTapGesture {
                                        if let itemIndex = selectedItems.firstIndex(of: item) {
                                            selectedItems.remove(at: itemIndex)
                                            print(selectedItems)
                                        }
                                    }
                            } else {
                                PhotoGridItem(newItem: item)
                                    .onTapGesture {
                                        selectedItems.append(item)
                                        print(selectedItems)
                                    }
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Selections")
            .toolbar {
                ToolbarItem {
                    HStack {
                        Button(action: {
                            isPopoverPresented.toggle()
                        }, label: {
                            Label("addToFolder", systemImage: "folder.fill.badge.plus")
                        })
                        .popover(isPresented: $isPopoverPresented) {
                            List {
                                ForEach(folders) { folder in
                                    Button(folder.name ?? "Folder") {
                                        addSelectedItemsToFolder(folderToAddTo: folder)
                                    }
                                }
                            }
                        }
                        Button(action: {
                            deleteSelectedItems()
                        }, label: {
                            Label("Delete", systemImage: "minus.circle.fill")
                        })
                    }
                }
            }
        }
    }
    
    private func addSelectedItemsToFolder(folderToAddTo: FolderEntity) {
        for sItem in selectedItems {
            if !folderToAddTo.itemsInThisFolder.contains(sItem) {
                folderToAddTo.addToFolderToItem(sItem)
                do {
                    try viewContext.save()
                } catch {
                    print("Error saving new video: \(error)")
                }
            }
        }
        selectedItems.removeAll()
        isPopoverPresented.toggle()
    }
    
    private func deleteSelectedItems() {
        for sItem in selectedItems {
            viewContext.delete(sItem)
            do {
                try viewContext.save()
            } catch {
                print("Unresolved error \(error)")
            }
        }
        selectedItems.removeAll()
    }
}

#Preview {
    GalleryView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
