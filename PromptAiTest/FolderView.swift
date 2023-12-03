//
//  FolderView.swift
//  ImageGallery
//
//  Created by Rishi Cadambe on 11/30/23.
//

import SwiftUI

struct ElementRow: View {
    var folder: FolderEntity

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            if let firstItem = folder.itemsInThisFolder.first,
               !firstItem.isVideo,
               let imgData = firstItem.imageData,
               let uiImage = UIImage(data: imgData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .frame(width: 60, height: 50)
                    .cornerRadius(8)
            }
            else {
                Image(systemName: "folder")
                    .resizable()
                    .frame(width: 60, height: 50)
                    .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(folder.name ?? "Unnamed")
                    .font(.headline)
            }
        }
    }
}

struct FolderView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FolderEntity.name, ascending: true)],
        animation: .default)
    private var folders: FetchedResults<FolderEntity>
    
    @State private var newFolderName: String = ""
    @State private var isAddFolderPresented: Bool = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(folders) { folder in
                    NavigationLink(destination: DetailView(parentFolder: folder)) {
                        ElementRow(folder: folder)
                        Text("\(folder.itemsInThisFolder.count) items")
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .navigationTitle("Folders")
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        isAddFolderPresented.toggle()
                    }) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            .alert("Enter Folder Name", isPresented: $isAddFolderPresented) {
                TextField("Type something", text: $newFolderName)
                Button("Add") {
                    addFolder()
                }
            }
        }
    }
    
    private func addFolder() {
        let newFolder = FolderEntity(context: viewContext)
        newFolder.id = UUID()
        newFolder.name = newFolderName
        do {
            try viewContext.save()
        } catch {
            print("Error saving new folder: \(error)")
        }
        printFolderNames()
        newFolderName = ""
        isAddFolderPresented.toggle()
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { folders[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func printFolderNames() {
        let folderNames = folders.map { $0.name ?? "Unnamed" }
        let joinedNames = folderNames.joined(separator: ", ")
        print("Folder Names: \(joinedNames)")
    }
}

#Preview {
    FolderView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
