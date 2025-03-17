import SwiftUI
import UIKit  // Added UIKit for UIImage

struct ProfileView: View {
    @State private var showingCustomization = false
    @State private var showingImagePicker = false
    @State private var showingEditCredentials = false
    @State private var image: UIImage?
    @State private var userName = ""
    @State private var userNickName = ""
    @State private var userEmail = ""
    @State private var isOnline = false
    @State private var showingFriendsList = false
    @State private var imagePickerSourceType: UIImagePickerController.SourceType = .photoLibrary
    @Binding var isAuthenticated: Bool  // Binding to control authentication state

    var body: some View {
        VStack {
            HStack {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        .padding(.trailing, 10)
                } else {
                    Image(systemName: "person.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        .padding(.trailing, 10)
                }

                VStack(alignment: .leading) {
                    Text(userNickName)
                        .font(.headline)
                    Text(userName)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text(userEmail)
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                Spacer()
                Button("Customize") {
                    showingCustomization = true
                }
                .foregroundColor(.blue)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
            }
            .padding()

            Form {
                Section(header: Text("Account")) {
                    Text("Username: \(userName)")
                    Text("Nickname: \(userNickName)")
                    Text("Email: \(userEmail)")
                    Toggle("Online Status", isOn: $isOnline)
                    Button("Edit Credentials") {
                        showingEditCredentials = true
                    }
                }

                Section(header: Text("Friends")) {
                    Button("View Friends") {
                        showingFriendsList = true
                    }
                }
            }

            Button(action: logout) {
                Text("Logout")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(10)
            }
            .padding()
        }
        .onAppear(perform: fetchUserProfile)  // Fetch user profile when the view appears
        .actionSheet(isPresented: $showingCustomization) {
            ActionSheet(title: Text("Select Photo"), message: nil, buttons: [
                .default(Text("Choose from Library")) {
                    self.imagePickerSourceType = .photoLibrary
                    self.showingImagePicker = true
                },
                .default(Text("Take a Photo")) {
                    self.imagePickerSourceType = .camera
                    self.showingImagePicker = true
                },
                .cancel()
            ])
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $image, sourceType: imagePickerSourceType)
        }
        .sheet(isPresented: $showingEditCredentials) {
            EditCredentialsView(userName: $userName, userNickName: $userNickName)
        }
//        .sheet(isPresented: $showingFriendsList) {
//            FriendsListView()
//        }
        .navigationTitle("Profile")
    }

    private func logout() {
        isAuthenticated = false
    }

    private func fetchUserProfile() {
        let networkManager = NetworkManager()
        networkManager.getUserProfile { fetchedUserName, fetchedUserNickName, fetchedUserEmail in
            DispatchQueue.main.async {
                self.userName = fetchedUserName ?? "Unknown"
                self.userNickName = fetchedUserNickName ?? "Unknown"
                self.userEmail = fetchedUserEmail ?? "Unknown"
            }
        }
    }
}
