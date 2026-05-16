//
//  ProfileView.swift
//  RealMatch-app
//
//  Created by Natali Samaan on 2026-05-16.
import SwiftUI
import PhotosUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

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
                                    .overlay(Text("Bild \(index + 1)"))
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            
       
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
        
     
        .onAppear {
            loadImages()
        }
        
        .onChange(of: selectedItems) { newItems in
            
            images.removeAll()
            
            for item in newItems {
                item.loadTransferable(type: Data.self) { result in
                    
                    switch result {
                    case .success(let data):
                        if let data = data, let uiImage = UIImage(data: data) {
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
    
    // MARK: - Upload to Firebase Storage + Firestore
    func uploadImages() {
        
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let storage = Storage.storage().reference()
        let db = Firestore.firestore()
        
        imageURLs.removeAll()
        
        for (index, image) in images.enumerated() {
            
            guard let imageData = image.jpegData(compressionQuality: 0.6) else { continue }
            
            let ref = storage.child("users/\(userId)/image\(index).jpg")
            
            ref.putData(imageData, metadata: nil) { _, error in
                
                if let error = error {
                    print("Upload error: \(error)")
                    return
                }
                
                ref.downloadURL { url, error in
                    
                    if let url = url {
                        
                        imageURLs.append(url.absoluteString)
                        
                        db.collection("users")
                            .document(userId)
                            .setData([
                                "images": imageURLs
                            ], merge: true)
                    }
                }
            }
        }
    }
    
    // MARK: - Load from Firestore
    func loadImages() {
        
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        
        db.collection("users").document(userId).getDocument { snapshot, error in
            
            if let error = error {
                print("Load error: \(error)")
                return
            }
            
            guard let data = snapshot?.data(),
                  let urls = data["images"] as? [String] else {
                return
            }
            
            self.imageURLs = urls
            self.images = []
            
            for urlString in urls {
                
                guard let url = URL(string: urlString) else { continue }
                
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
