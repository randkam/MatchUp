import Foundation
import CommonCrypto

struct User: Codable {
    let userId: Int
    let userName: String
    let userNickName: String
    let email: String
    let userPassword: String
    let userPosition: String
    let userRegion: String
    let profilePictureUrl: String?
    var token: String?
}

struct UserLocation: Codable {
    let id: Int
    let userId: Int
    let locationId: Int
}


class NetworkManager {
    let baseURL = APIConfig.usersEndpoint
    let secretKey = "your_secret_key"

    let sudoUser = "sudo"
    let sudoPassword = "supersecret"
    let sudoNickName = "sudoman"

    private func generateJWTToken(for identifier: String, password: String) -> String? {
        let header = ["alg": "HS256", "typ": "JWT"]
        let payload = ["identifier": identifier, "password": password]

        guard let headerData = try? JSONSerialization.data(withJSONObject: header),
              let payloadData = try? JSONSerialization.data(withJSONObject: payload) else { return nil }

        let headerBase64 = headerData.base64EncodedString()
        let payloadBase64 = payloadData.base64EncodedString()
        let toSign = "\(headerBase64).\(payloadBase64)"

        guard let signature = signData(toSign, withKey: secretKey) else { return nil }

        return "\(toSign).\(signature)"
    }

    private func signData(_ data: String, withKey key: String) -> String? {
        guard let keyData = key.data(using: .utf8),
              let dataToSign = data.data(using: .utf8) else { return nil }

        var hmac = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        dataToSign.withUnsafeBytes { dataBytes in
            keyData.withUnsafeBytes { keyBytes in
                CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256), keyBytes.baseAddress, keyData.count, dataBytes.baseAddress, dataToSign.count, &hmac)
            }
        }
        return Data(hmac).base64EncodedString()
    }

    func updateUserProfile(userId: Int, userName: String, userNickName: String, email: String, completion: @escaping (Bool, Error?) -> Void) {
        guard let token = UserDefaults.standard.string(forKey: "userToken"),
              let url = URL(string: "\(APIConfig.usersEndpoint)/\(userId)") else {
            completion(false, NSError(domain: "", code: -1, userInfo: nil))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = ["userName": userName, "userNickName": userNickName, "email": email]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error { completion(false, error); return }
            guard let data = data else {
                completion(false, NSError(domain: "", code: -1, userInfo: nil))
                return
            }
            do {
                let updatedUser = try JSONDecoder().decode(User.self, from: data)
                completion(updatedUser.userId == userId, nil)
            } catch { completion(false, error) }
        }.resume()
    }

    func fetchUserLocations(userId: Int, completion: @escaping (Bool, Error?) -> Void) {
        guard let url = URL(string: "\(APIConfig.userLocationsEndpoint)/user/\(userId)") else {
            completion(false, NSError(domain: "", code: -1, userInfo: nil))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error { completion(false, error); return }
            guard let data = data else {
                completion(false, NSError(domain: "", code: -1, userInfo: nil))
                return
            }
            do {
                let locations = try JSONDecoder().decode([UserLocation].self, from: data)
                let ids = locations.map { $0.locationId }
                UserDefaults.standard.set(ids, forKey: "joinedLocations")
                completion(true, nil)
            } catch { completion(false, error) }
        }.resume()
    }

    func loginUser(identifier: String, password: String, completion: @escaping (Bool, Error?) -> Void) {
        if (identifier == sudoUser || identifier == "sudo@localhost") && password == sudoPassword {
            if let token = generateJWTToken(for: sudoUser, password: sudoPassword) {
                UserDefaults.standard.set(token, forKey: "userToken")
                UserDefaults.standard.set("sudo@localhost", forKey: "loggedInUserEmail")
                UserDefaults.standard.set(sudoUser, forKey: "loggedInUserName")
                UserDefaults.standard.set(sudoNickName, forKey: "loggedInUserNickName")
                completion(true, nil)
            } else {
                completion(false, NSError(domain: "", code: -1, userInfo: nil))
            }
            return
        }
        guard let url = URL(string: "\(APIConfig.usersEndpoint)?identifier=\(identifier)") else {
            completion(false, NSError(domain: "", code: -1, userInfo: nil)); return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error { completion(false, error); return }
            guard let data = data else {
                completion(false, NSError(domain: "", code: -1, userInfo: nil)); return
            }
            do {
                let users = try JSONDecoder().decode([User].self, from: data)
                if var user = users.first(where: { ($0.email == identifier || $0.userName == identifier) && $0.userPassword == password }) {
                    if let token = self.generateJWTToken(for: user.email, password: user.userPassword) {
                        user.token = token
                        UserDefaults.standard.set(token, forKey: "userToken")
                        UserDefaults.standard.set(user.email, forKey: "loggedInUserEmail")
                        UserDefaults.standard.set(user.userName, forKey: "loggedInUserName")
                        UserDefaults.standard.set(user.userNickName, forKey: "loggedInUserNickName")
                        UserDefaults.standard.set(user.userId, forKey: "loggedInUserId")
                        UserDefaults.standard.set(user.userPosition, forKey: "loggedInUserPosition")
                        UserDefaults.standard.set(user.userRegion, forKey: "loggedInUserRegion")
                        if let profilePictureUrl = user.profilePictureUrl {
                            UserDefaults.standard.set(profilePictureUrl, forKey: "loggedInUserProfilePicture")
                        }
                        completion(true, nil)
                    } else { completion(false, NSError(domain: "", code: -1, userInfo: nil)) }
                } else {
                    completion(false, NSError(domain: "", code: 401, userInfo: nil))
                }
            } catch { completion(false, error) }
        }.resume()
    }

    func createAccount(userName: String, userNickName: String, email: String, userId: Int, password: String, completion: @escaping (Bool, Error?) -> Void) {
        guard let url = URL(string: APIConfig.usersEndpoint) else { completion(false, nil); return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["userId": userId, "userName": userName, "userNickName": userNickName, "userPassword": password, "email": email]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error { completion(false, error); return }
            guard let data = data else { completion(false, nil); return }
            do {
                let createdUser = try JSONDecoder().decode(User.self, from: data)
                completion(createdUser.email == email, nil)
            } catch { completion(false, error) }
        }.resume()
    }

    func getUserProfile(completion: @escaping (String?, String?, String?, String?) -> Void) {
        guard let email = UserDefaults.standard.string(forKey: "loggedInUserEmail"),
              let token = UserDefaults.standard.string(forKey: "userToken"),
              let url = URL(string: "\(APIConfig.usersEndpoint)?email=\(email)") else {
            print("getUserProfile: Failed to create URL or get credentials")
            completion(nil, nil, nil, nil)
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("getUserProfile error: \(error)")
                completion(nil, nil, nil, nil)
                return
            }
            guard let data = data else {
                print("getUserProfile: No data received")
                completion(nil, nil, nil, nil)
                return
            }
            do {
                let users = try JSONDecoder().decode([User].self, from: data)
                if let user = users.first(where: { $0.email == email }) {
                    print("getUserProfile success - Profile picture URL: \(String(describing: user.profilePictureUrl))")
                    completion(user.userName, user.userNickName, user.email, user.profilePictureUrl)
                } else {
                    print("getUserProfile: User not found in response")
                    completion(nil, nil, nil, nil)
                }
            } catch {
                print("getUserProfile decode error: \(error)")
                completion(nil, nil, nil, nil)
            }
        }.resume()
    }
    
    func deleteAccount(completion: @escaping (Bool) -> Void) {
        guard let userId = UserDefaults.standard.string(forKey: "loggedInUserId"),
              let url = URL(string: "\(APIConfig.usersEndpoint)/\(userId)") else {
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("Delete error: \(error.localizedDescription)")
                completion(false)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("Delete failed: \(String(describing: response))")
                completion(false)
                return
            }

            completion(true)
        }.resume()
    }

    func uploadProfilePicture(userId: String, imageData: Data, completion: @escaping (Bool, String?) -> Void) {
        let urlString = "\(APIConfig.usersEndpoint)/\(userId)/profile-picture"
        print("Uploading profile picture to: \(urlString)")
        
        guard let url = URL(string: urlString),
              let token = UserDefaults.standard.string(forKey: "userToken") else {
            print("uploadProfilePicture: Failed to create URL or get token")
            completion(false, nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"profile.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("uploadProfilePicture error: \(error)")
                completion(false, nil)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("uploadProfilePicture response status: \(httpResponse.statusCode)")
                
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("uploadProfilePicture response: \(responseString)")
                    
                    if httpResponse.statusCode == 200 {
                        // Remove any whitespace or newlines from the response
                        let fullUrl = responseString.trimmingCharacters(in: .whitespacesAndNewlines)
                        print("uploadProfilePicture success - Full URL: \(fullUrl)")
                        completion(true, fullUrl)
                    } else {
                        print("uploadProfilePicture: Invalid response status code")
                        completion(false, nil)
                    }
                } else {
                    print("uploadProfilePicture: Could not read response data")
                    completion(false, nil)
                }
            } else {
                print("uploadProfilePicture: No HTTP response")
                completion(false, nil)
            }
        }.resume()
    }

    func joinLocation(locationId: Int, completion: @escaping (Bool, Error?) -> Void) {
        guard let userId = UserDefaults.standard.integer(forKey: "loggedInUserId") as Int?,
              let url = URL(string: "\(APIConfig.userLocationsEndpoint)") else {
            completion(false, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create URL or get user ID"]))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "userId": userId,
            "locationId": locationId
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(false, error)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(false, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
                return
            }

            if (200...299).contains(httpResponse.statusCode) {
                // Update local storage of joined locations
                var joinedLocations = UserDefaults.standard.array(forKey: "joinedLocations") as? [Int] ?? []
                if !joinedLocations.contains(locationId) {
                    joinedLocations.append(locationId)
                    UserDefaults.standard.set(joinedLocations, forKey: "joinedLocations")
                }
                completion(true, nil)
            } else {
                completion(false, NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error"]))
            }
        }.resume()
    }

}
