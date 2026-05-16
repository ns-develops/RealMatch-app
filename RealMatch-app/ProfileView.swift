//
//  ProfileView.swift
//  RealMatch-app
//
//  Created by Natali Samaan on 2026-05-16.
import SwiftUI
import PhotosUI
import FirebaseAuth
import FirebaseStorage
import FirebaseDatabase

struct ProfileView: View {
    
    @Binding var isLoggedIn: Bool
    
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var images: [UIImage] = []
    @State private var imageURLs: [String] = []
    
    var body: some View {
        
        VStack(spacing: 20) {
            
            Text("Profile")
                .font(.largeTitle)
                .bold()
            
            // MARK: - Image Picker
            PhotosPicker(selection: $selectedItems,
                         maxSelectionCount: 4,
                         matching: .images) {
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 15) {
                    
                    ForEach(0..<4, id: \.self) { index in
                        
                        ZStack {
                            
                            if index < images.count {
                                
                                Image(uiImage: images[index])
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 150)
                                    .clipped()
                                    .cornerRadius(12)
                                
                            } else {
                                
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 150)
                                    .overlay(
                                        Text("Bild \(index + 1)")
                                    )
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // MARK: - Save Button
            Button {
                uploadImages()
            } label: {
                Text("Spara bilder")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            // MARK: - Logout
            Button {
                try? Auth.auth().signOut()
                isLoggedIn = false
            } label: {
                Text("Logga ut")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        
        // MARK: - Load Images
        .onAppear {
            loadImages()
        }
        
        // MARK: - Handle Selected Images
        .onChange(of: selectedItems) { newItems in
            
            images.removeAll()
            
            for item in newItems {
                
                item.loadTransferable(type: Data.self) { result in
                    
                    switch result {
                        
                    case .success(let data):
                        
                        if let data = data,
                           let uiImage = UIImage(data: data) {
                            
                            DispatchQueue.main.async {
                                images.append(uiImage)
                            }
                        }
                        
                    case .failure(let error):
                        print(error)
                    }
                }
            }
        }
    }
    
    // MARK: - Upload Images
    func uploadImages() {
        
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let storage = Storage.storage().reference()
        let db = Database.database().reference()
        
        var uploadedURLs: [String] = []
        
        let group = DispatchGroup()
        
        for (index, image) in images.enumerated() {
            
            guard let imageData = image.jpegData(compressionQuality: 0.6) else {
                continue
            }
            
            group.enter()
            
            let ref = storage.child("users/\(userId)/image\(index).jpg")
            
            ref.putData(imageData, metadata: nil) { _, error in
                
                if let error = error {
                    print("Upload error: \(error)")
                    group.leave()
                    return
                }
                
                ref.downloadURL { url, error in
                    
                    if let url = url {
                        uploadedURLs.append(url.absoluteString)
                    }
                    
                    group.leave()
                }
            }
        }
        
        // MARK: - Save URLs to Realtime Database
        group.notify(queue: .main) {
            
            db.child("users")
                .child(userId)
                .setValue([
                    "images": uploadedURLs
                ])
            
            self.imageURLs = uploadedURLs
            
            print("Alla bilder sparade i Realtime Database")
        }
    }
    
    // MARK: - Load Images From Realtime Database
    func loadImages() {
        
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Database.database().reference()
        
        db.child("users")
            .child(userId)
            .observeSingleEvent(of: .value) { snapshot in
                
                guard let data = snapshot.value as? [String: Any],
                      let urls = data["images"] as? [String] else {
                    return
                }
                
                self.imageURLs = urls
                self.images.removeAll()
                
                for urlString in urls {
                    
                    guard let url = URL(string: urlString) else {
                        continue
                    }
                    
                    URLSession.shared.dataTask(with: url) { data, _, _ in
                        
                        if let data = data,
                           let image = UIImage(data: data) {
                            
                            DispatchQueue.main.async {
                                self.images.append(image)
                            }
                        }
                        
                    }.resume()
                }
            }
    }
}
