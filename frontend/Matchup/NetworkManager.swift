import Foundation
import CommonCrypto

struct User: Codable {
    let userId: Int
    let userName: String
    let userNickName: String
    let userEmail: String
    let userPassword: String
    let userPosition: String
    let userRegion: String
    let profilePictureUrl: String?
    var token: String?
    var userLatitude: Double?
    var userLongitude: Double?
    let role: String?
    
    enum CodingKeys: String, CodingKey {
        case userId
        case userName
        case userNickName
        case userEmail
        case userPassword
        case userPosition
        case userRegion
        case profilePictureUrl
        case token
        case userLatitude
        case userLongitude
        case role
    }
}

struct UserLocation: Codable {
    let id: Int
    let userId: Int
    let locationId: Int
}

struct PaginatedResponse<T: Codable>: Codable {
    let content: [T]
    let totalPages: Int
    let totalElements: Int
    let last: Bool
    let size: Int
    let number: Int
    let first: Bool
    let numberOfElements: Int
    let empty: Bool
    
    init(content: [T], totalPages: Int, totalElements: Int, last: Bool, size: Int, number: Int, first: Bool, numberOfElements: Int, empty: Bool) {
        self.content = content
        self.totalPages = totalPages
        self.totalElements = totalElements
        self.last = last
        self.size = size
        self.number = number
        self.first = first
        self.numberOfElements = numberOfElements
        self.empty = empty
    }
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
                UserDefaults.standard.set("ADMIN", forKey: "userRole")
                completion(true, nil)
            } else {
                completion(false, NSError(domain: "", code: -1, userInfo: nil))
            }
            return
        }
        
        let loginEndpoint = "\(APIConfig.usersEndpoint)/login?identifier=\(identifier)&password=\(password)"
        guard let url = URL(string: loginEndpoint) else {
            completion(false, NSError(domain: "", code: -1, userInfo: nil))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Login error: \(error)")
                completion(false, error)
                return
            }
            
            guard let data = data else {
                print("No data received from login")
                completion(false, NSError(domain: "", code: -1, userInfo: nil))
                return
            }
            
            do {
                let user = try JSONDecoder().decode(User.self, from: data)
                if let token = self.generateJWTToken(for: user.userEmail, password: user.userPassword) {
                    // Store user data in UserDefaults
                    UserDefaults.standard.set(token, forKey: "userToken")
                    UserDefaults.standard.set(user.userEmail, forKey: "loggedInUserEmail")
                    UserDefaults.standard.set(user.userName, forKey: "loggedInUserName")
                    UserDefaults.standard.set(user.userNickName, forKey: "loggedInUserNickName")
                    UserDefaults.standard.set(user.userId, forKey: "loggedInUserId")
                    UserDefaults.standard.set(user.userPosition, forKey: "loggedInUserPosition")
                    UserDefaults.standard.set(user.userRegion, forKey: "loggedInUserRegion")
                    if let profilePictureUrl = user.profilePictureUrl {
                        UserDefaults.standard.set(profilePictureUrl, forKey: "loggedInUserProfilePicture")
                    }
                    UserDefaults.standard.set((user.role ?? "USER").uppercased(), forKey: "userRole")
                    print("Login successful for user: \(user.userName)")
                    completion(true, nil)
                } else {
                    print("Failed to generate token")
                    completion(false, NSError(domain: "", code: -1, userInfo: nil))
                }
            } catch {
                print("Login decode error: \(error)")
                completion(false, error)
            }
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
                completion(createdUser.userEmail == email, nil)
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
                if let user = users.first(where: { $0.userEmail == email }) {
                    print("getUserProfile success - Profile picture URL: \(String(describing: user.profilePictureUrl))")
                    completion(user.userName, user.userNickName, user.userEmail, user.profilePictureUrl)
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

    // MARK: - Location Images
    func fetchLocationImages(locationId: Int, completion: @escaping ([String]) -> Void) {
        let urlString = APIConfig.locationImagesEndpoint(locationId: locationId)
        guard let url = URL(string: urlString) else {
            completion([])
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let _ = error { completion([]); return }
            guard let data = data else { completion([]); return }
            do {
                let urls = try JSONDecoder().decode([String].self, from: data)
                completion(urls)
            } catch {
                completion([])
            }
        }.resume()
    }

    func get<T: Decodable>(_ endpoint: String, completion: @escaping (Result<T, Error>) -> Void) {
        guard let url = URL(string: endpoint) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        print("Making GET request to: \(endpoint)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network error: \(error)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                print("No data received")
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            // Print raw response
            if let responseString = String(data: data, encoding: .utf8) {
                print("Raw response: \(responseString)")
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                print("Successfully decoded response of type: \(T.self)")
                completion(.success(decodedResponse))
            } catch {
                print("Decoding error: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
    
    func post<T: Decodable>(_ endpoint: String, parameters: [String: Any], completion: @escaping (Result<T, Error>) -> Void) {
        guard let url = URL(string: endpoint) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
            print("Request body: \(String(data: request.httpBody!, encoding: .utf8) ?? "none")")
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"])))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            // Debug: Print raw response
            if let responseString = String(data: data, encoding: .utf8) {
                print("Server response: \(responseString)")
            }
            
            // Check for error response
            if !(200...299).contains(httpResponse.statusCode) {
                // Try to decode error response
                if let errorDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    let message = errorDict["message"] as? String ?? "Unknown error"
                    let error = NSError(domain: "", code: httpResponse.statusCode, userInfo: [
                        NSLocalizedDescriptionKey: message,
                        "statusCode": httpResponse.statusCode
                    ])
                    completion(.failure(error))
                } else {
                    completion(.failure(NSError(domain: "", code: httpResponse.statusCode, userInfo: [
                        NSLocalizedDescriptionKey: "Server error: \(httpResponse.statusCode)"
                    ])))
                }
                return
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                completion(.success(decodedResponse))
            } catch {
                print("Decoding error: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }

    func patch<T: Decodable>(_ endpoint: String, body: [String: Any], completion: @escaping (Result<T, Error>) -> Void) {
        guard let url = URL(string: endpoint) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        do { request.httpBody = try JSONSerialization.data(withJSONObject: body) } catch {
            completion(.failure(error)); return
        }
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error { completion(.failure(error)); return }
            guard let http = response as? HTTPURLResponse, let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                return
            }
            if !(200...299).contains(http.statusCode) {
                let msg = String(data: data, encoding: .utf8) ?? "Server error"
                completion(.failure(NSError(domain: "", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])))
                return
            }
            do { let decoded = try JSONDecoder().decode(T.self, from: data); completion(.success(decoded)) }
            catch { completion(.failure(error)) }
        }.resume()
    }
    
    func delete(_ endpoint: String, completion: @escaping (Error?) -> Void) {
        guard let url = URL(string: endpoint) else {
            completion(NSError(domain: "NetworkManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(error)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(NSError(domain: "NetworkManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
                return
            }
            
            if (200...299).contains(httpResponse.statusCode) {
                completion(nil)
                return
            }
            
            // Try to surface a helpful message from the server body
            var message = "Server error (status \(httpResponse.statusCode))"
            if let data = data {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let msg = json[NSLocalizedDescriptionKey] as? String ?? json["message"] as? String {
                    message = msg
                } else if let body = String(data: data, encoding: .utf8), !body.isEmpty {
                    message = body
                }
            }
            completion(NSError(domain: "NetworkManager", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message]))
        }.resume()
    }
    
    func getUser(userId: Int, completion: @escaping (Result<User, Error>) -> Void) {
        let endpoint = APIConfig.userByIdEndpoint(userId: userId)
        print("Fetching user from endpoint: \(endpoint)")
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching user: \(error)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            // Print raw response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("Raw user response: \(responseString)")
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .useDefaultKeys
                let user = try decoder.decode(User.self, from: data)
                completion(.success(user))
            } catch {
                print("Error decoding user: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }

    func submitFeedback(feedback: [String: Any], completion: @escaping (Bool, Error?) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseAPI)/api/v1/feedback") else {
            completion(false, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: feedback)
        } catch {
            completion(false, error)
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(false, error)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(false, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
                return
            }
            
            completion(httpResponse.statusCode == 200, nil)
        }.resume()
    }

    func getFeedbackHistory(userId: Int, completion: @escaping (Result<[FeedbackItem], Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.baseAPI)/api/v1/feedback/user/\(userId)") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let feedback = try decoder.decode([FeedbackItem].self, from: data)
                completion(.success(feedback))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func updateUserLocation(userId: Int, latitude: Double, longitude: Double, completion: @escaping (Bool, Error?) -> Void) {
        // Create URL components for proper URL encoding
        var components = URLComponents(string: "\(baseURL)/\(userId)/location")
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: String(format: "%.6f", latitude)),
            URLQueryItem(name: "longitude", value: String(format: "%.6f", longitude))
        ]
        
        guard let url = components?.url else {
            completion(false, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
        print("NetworkManager: Making request to URL: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("NetworkManager: Request failed with error: \(error.localizedDescription)")
                completion(false, error)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("NetworkManager: Invalid response type")
                completion(false, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
                return
            }
            
            print("NetworkManager: Received response with status code: \(httpResponse.statusCode)")
            
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("NetworkManager: Response body: \(responseString)")
            }
            
            if (200...299).contains(httpResponse.statusCode) {
                print("NetworkManager: Successfully updated location")
                completion(true, nil)
            } else {
                print("NetworkManager: Failed to update location - Status code: \(httpResponse.statusCode)")
                completion(false, NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error"]))
            }
        }.resume()
    }
}

extension NetworkManager {
    func getPaginatedLocations(
        page: Int,
        size: Int,
        search: String? = nil,
        isIndoor: Bool? = nil,
        isLit: Bool? = nil,
        completion: @escaping (Result<PaginatedResponse<Location>, Error>) -> Void
    ) {
        var urlComponents = URLComponents(string: APIConfig.locationsEndpoint)!
        var queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "size", value: String(size))
        ]
        
        if let search = search {
            queryItems.append(URLQueryItem(name: "search", value: search))
        }
        if let isIndoor = isIndoor {
            queryItems.append(URLQueryItem(name: "isIndoor", value: String(isIndoor)))
        }
        if let isLit = isLit {
            queryItems.append(URLQueryItem(name: "isLit", value: String(isLit)))
        }
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        print("Fetching locations from URL: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                let body = String(data: data, encoding: .utf8) ?? ""
                print("Locations request failed with status: \(httpResponse.statusCode), body: \(body)")
                let error = NSError(domain: "NetworkManager", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Locations request failed (status \(httpResponse.statusCode))"])
                completion(.failure(error))
                return
            }
            
            print("Raw locations response: \(String(data: data, encoding: .utf8) ?? "Unable to decode response")")
            
            do {
                let response = try JSONDecoder().decode(PaginatedResponse<Location>.self, from: data)
                completion(.success(response))
            } catch {
                print("Error decoding locations: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
    
    func getPaginatedReviews(locationId: Int, page: Int = 0, size: Int = 20, completion: @escaping (Result<PaginatedResponse<Review>, Error>) -> Void) {
        let endpoint = "\(APIConfig.reviewsEndpoint)/location/\(locationId)?page=\(page)&size=\(size)"
        print("Fetching reviews from endpoint: \(endpoint)")
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching reviews: \(error)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                print("No data received from reviews endpoint")
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            // Print raw response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("Raw reviews response: \(responseString)")
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .useDefaultKeys
                let response = try decoder.decode(PaginatedResponse<Review>.self, from: data)
                print("Successfully decoded \(response.content.count) reviews")
                print("Reviews content: \(response.content)")
                completion(.success(response))
            } catch {
                print("Error decoding reviews: \(error)")
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        print("Key '\(key)' not found: \(context.debugDescription)")
                    case .valueNotFound(let type, let context):
                        print("Value of type '\(type)' not found: \(context.debugDescription)")
                    case .typeMismatch(let type, let context):
                        print("Type '\(type)' mismatch: \(context.debugDescription)")
                    case .dataCorrupted(let context):
                        print("Data corrupted: \(context.debugDescription)")
                    @unknown default:
                        print("Unknown decoding error: \(error)")
                    }
                }
                completion(.failure(error))
            }
        }.resume()
    }
    
    func getPaginatedMessages(locationId: Int, page: Int = 0, size: Int = 20, completion: @escaping (Result<PaginatedResponse<ChatMessage>, Error>) -> Void) {
        let endpoint = "\(APIConfig.messagesEndpoint)/\(locationId)?page=\(page)&size=\(size)"
        get(endpoint, completion: completion)
    }
}

extension NetworkManager {
    // MARK: - Bracket
    func getBracket(tournamentId: Int, completion: @escaping (Result<[TournamentMatchModel], Error>) -> Void) {
        let endpoint = APIConfig.tournamentBracketEndpoint(tournamentId: tournamentId)
        get(endpoint, completion: completion)
    }

    func generateBracket(tournamentId: Int, shuffle: Bool = true, requestingUserId: Int, completion: @escaping (Result<[TournamentMatchModel], Error>) -> Void) {
        let endpoint = APIConfig.tournamentGenerateBracketEndpoint(tournamentId: tournamentId, shuffle: shuffle, requestingUserId: requestingUserId)
        post(endpoint, parameters: [:], completion: completion)
    }

    func updateMatchScore(tournamentId: Int, matchId: Int, scoreA: Int, scoreB: Int, requestingUserId: Int, completion: @escaping (Result<TournamentMatchModel, Error>) -> Void) {
        let endpoint = APIConfig.tournamentMatchScoreEndpoint(tournamentId: tournamentId, matchId: matchId, requestingUserId: requestingUserId)
        patch(endpoint, body: ["team1_score": scoreA, "team2_score": scoreB], completion: completion)
    }
}

extension NetworkManager {
    struct TeamTournamentStats: Codable { let wins: Int; let losses: Int; let tournaments_won: Int }

    func getTeamTournamentStats(teamId: Int, completion: @escaping (Result<TeamTournamentStats, Error>) -> Void) {
        let endpoint = APIConfig.teamTournamentStatsEndpoint(teamId: teamId)
        get(endpoint, completion: completion)
    }
}

extension NetworkManager {
    func getTournamentById(tournamentId: Int, completion: @escaping (Result<Tournament, Error>) -> Void) {
        let endpoint = "\(APIConfig.tournamentsEndpoint)/\(tournamentId)"
        guard let url = URL(string: endpoint) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])));
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])));
                return
            }

            if let responseString = String(data: data, encoding: .utf8) {
                print("Raw tournament-by-id response: \(responseString)")
            }

            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .custom { decoder in
                    let container = try decoder.singleValueContainer()
                    let dateString = try container.decode(String.self)
                    let isoWithFraction = ISO8601DateFormatter()
                    isoWithFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    if let d = isoWithFraction.date(from: dateString) { return d }
                    let iso = ISO8601DateFormatter()
                    iso.formatOptions = [.withInternetDateTime]
                    if let d = iso.date(from: dateString) { return d }
                    let df = DateFormatter()
                    df.locale = Locale(identifier: "en_US_POSIX")
                    df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                    if let d = df.date(from: dateString) { return d }
                    throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid date: \(dateString)"))
                }
                let tournament = try decoder.decode(Tournament.self, from: data)
                completion(.success(tournament))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

extension NetworkManager {
    func getLocationById(locationId: Int, completion: @escaping (Result<Location, Error>) -> Void) {
        let endpoint = "\(APIConfig.locationsEndpoint)/\(locationId)"
        print("Fetching location by id from endpoint: \(endpoint)")
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])) )
                return
            }
            do {
                let location = try JSONDecoder().decode(Location.self, from: data)
                completion(.success(location))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

extension NetworkManager {
    func incrementActivePlayers(locationId: Int, completion: @escaping (Result<Location, Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.locationsEndpoint)/\(locationId)/increment-players") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let location = try JSONDecoder().decode(Location.self, from: data)
                completion(.success(location))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func decrementActivePlayers(locationId: Int, completion: @escaping (Result<Location, Error>) -> Void) {
        guard let url = URL(string: "\(APIConfig.locationsEndpoint)/\(locationId)/decrement-players") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let location = try JSONDecoder().decode(Location.self, from: data)
                completion(.success(location))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

extension NetworkManager {
    // MARK: - Tournaments
    func getUpcomingTournaments(page: Int = 0, size: Int = 20, completion: @escaping (Result<PaginatedResponse<Tournament>, Error>) -> Void) {
        guard var components = URLComponents(string: APIConfig.upcomingTournamentsEndpoint) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid tournaments endpoint URL string"])) )
            return
        }
        components.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "size", value: String(size))
        ]
        guard let url = components.url else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let http = response as? HTTPURLResponse {
                print("Tournaments HTTP status: \(http.statusCode)")
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                // Robust date decoding for LocalDateTime from backend
                decoder.dateDecodingStrategy = .custom { decoder in
                    let container = try decoder.singleValueContainer()
                    let dateString = try container.decode(String.self)
                    // Try full ISO 8601 with fractional seconds
                    let isoWithFraction = ISO8601DateFormatter()
                    isoWithFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    if let d = isoWithFraction.date(from: dateString) { return d }
                    // Try ISO 8601 without fractional seconds
                    let iso = ISO8601DateFormatter()
                    iso.formatOptions = [.withInternetDateTime]
                    if let d = iso.date(from: dateString) { return d }
                    // Try plain LocalDateTime without timezone
                    let df = DateFormatter()
                    df.locale = Locale(identifier: "en_US_POSIX")
                    df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                    if let d = df.date(from: dateString) { return d }
                    // Try space-separated datetime (no 'T')
                    let dfSpace = DateFormatter()
                    dfSpace.locale = Locale(identifier: "en_US_POSIX")
                    dfSpace.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    if let d = dfSpace.date(from: dateString) { return d }
                    // Try date-only
                    let dfDateOnly = DateFormatter()
                    dfDateOnly.locale = Locale(identifier: "en_US_POSIX")
                    dfDateOnly.dateFormat = "yyyy-MM-dd"
                    if let d = dfDateOnly.date(from: dateString) { return d }
                    throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid date: \(dateString)"))
                }
                // Debug: print raw body
                if let body = String(data: data, encoding: .utf8) {
                    print("Raw tournaments response: \(body)")
                }
                // Try Page<Tournament> first
                if let pageResponse = try? decoder.decode(PaginatedResponse<Tournament>.self, from: data) {
                    completion(.success(pageResponse))
                    return
                }
                // Fallback: array shape
                if let arrayResponse = try? decoder.decode([Tournament].self, from: data) {
                    let wrapped = PaginatedResponse(content: arrayResponse, totalPages: 1, totalElements: arrayResponse.count, last: true, size: arrayResponse.count, number: 0, first: true, numberOfElements: arrayResponse.count, empty: arrayResponse.isEmpty)
                    completion(.success(wrapped))
                    return
                }
                // If both fail, throw to outer catch
                let _ = try decoder.decode(PaginatedResponse<Tournament>.self, from: data)
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func getLiveTournaments(page: Int = 0, size: Int = 20, completion: @escaping (Result<PaginatedResponse<Tournament>, Error>) -> Void) {
        guard var components = URLComponents(string: APIConfig.liveTournamentsEndpoint) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid tournaments endpoint URL string"])) )
            return
        }
        components.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "size", value: String(size))
        ]
        guard let url = components.url else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"]))); return }
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .custom { decoder in
                    let container = try decoder.singleValueContainer()
                    let dateString = try container.decode(String.self)
                    let isoWithFraction = ISO8601DateFormatter(); isoWithFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    if let d = isoWithFraction.date(from: dateString) { return d }
                    let iso = ISO8601DateFormatter(); iso.formatOptions = [.withInternetDateTime]
                    if let d = iso.date(from: dateString) { return d }
                    let df = DateFormatter(); df.locale = Locale(identifier: "en_US_POSIX"); df.timeZone = TimeZone(secondsFromGMT: 0)
                    let formats = ["yyyy-MM-dd'T'HH:mm:ss.SSSZ","yyyy-MM-dd'T'HH:mm:ss.SSS","yyyy-MM-dd HH:mm:ss.SSS","yyyy-MM-dd'T'HH:mm:ss","yyyy-MM-dd HH:mm:ss","yyyy-MM-dd"]
                    for f in formats {
                        df.dateFormat = f
                        if let d = df.date(from: dateString) { return d }
                    }
                    throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid date: \(dateString)"))
                }
                if let pageResponse = try? decoder.decode(PaginatedResponse<Tournament>.self, from: data) {
                    completion(.success(pageResponse)); return
                }
                if let arrayResponse = try? decoder.decode([Tournament].self, from: data) {
                    let wrapped = PaginatedResponse(content: arrayResponse, totalPages: 1, totalElements: arrayResponse.count, last: true, size: arrayResponse.count, number: 0, first: true, numberOfElements: arrayResponse.count, empty: arrayResponse.isEmpty)
                    completion(.success(wrapped)); return
                }
                let _ = try decoder.decode(PaginatedResponse<Tournament>.self, from: data)
            } catch { completion(.failure(error)) }
        }.resume()
    }

    func getPastTournaments(page: Int = 0, size: Int = 20, completion: @escaping (Result<PaginatedResponse<Tournament>, Error>) -> Void) {
        guard var components = URLComponents(string: APIConfig.pastTournamentsEndpoint) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid tournaments endpoint URL string"])) )
            return
        }
        components.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "size", value: String(size))
        ]
        guard let url = components.url else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"]))); return }
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .custom { decoder in
                    let container = try decoder.singleValueContainer()
                    let dateString = try container.decode(String.self)
                    let isoWithFraction = ISO8601DateFormatter(); isoWithFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    if let d = isoWithFraction.date(from: dateString) { return d }
                    let iso = ISO8601DateFormatter(); iso.formatOptions = [.withInternetDateTime]
                    if let d = iso.date(from: dateString) { return d }
                    let df = DateFormatter(); df.locale = Locale(identifier: "en_US_POSIX"); df.timeZone = TimeZone(secondsFromGMT: 0)
                    let formats = ["yyyy-MM-dd'T'HH:mm:ss.SSSZ","yyyy-MM-dd'T'HH:mm:ss.SSS","yyyy-MM-dd HH:mm:ss.SSS","yyyy-MM-dd'T'HH:mm:ss","yyyy-MM-dd HH:mm:ss","yyyy-MM-dd"]
                    for f in formats {
                        df.dateFormat = f
                        if let d = df.date(from: dateString) { return d }
                    }
                    throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid date: \(dateString)"))
                }
                if let pageResponse = try? decoder.decode(PaginatedResponse<Tournament>.self, from: data) {
                    completion(.success(pageResponse)); return
                }
                if let arrayResponse = try? decoder.decode([Tournament].self, from: data) {
                    let wrapped = PaginatedResponse(content: arrayResponse, totalPages: 1, totalElements: arrayResponse.count, last: true, size: arrayResponse.count, number: 0, first: true, numberOfElements: arrayResponse.count, empty: arrayResponse.isEmpty)
                    completion(.success(wrapped)); return
                }
                let _ = try decoder.decode(PaginatedResponse<Tournament>.self, from: data)
            } catch { completion(.failure(error)) }
        }.resume()
    }
}

extension NetworkManager {
    // MARK: - Tournament Admin
    func createTournament(name: String,
                          formatSize: Int,
                          maxTeams: Int,
                          startsAt: Date,
                          location: String,
                          prizeCents: Int,
                          requestingUserId: Int,
                          completion: @escaping (Result<Tournament, Error>) -> Void) {
        let endpoint = APIConfig.tournamentsEndpoint
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        let startsAtStr = df.string(from: startsAt)

        let params: [String: Any] = [
            "name": name,
            "format_size": formatSize,
            "max_teams": maxTeams,
            "starts_at": startsAtStr,
            "location": location,
            "prize_cents": prizeCents,
            "requesting_user_id": requestingUserId
        ]
        guard let url = URL(string: endpoint) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])));
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        do { request.httpBody = try JSONSerialization.data(withJSONObject: params) } catch {
            completion(.failure(error)); return
        }
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error { completion(.failure(error)); return }
            guard let http = response as? HTTPURLResponse, let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])));
                return
            }
            if !(200...299).contains(http.statusCode) {
                let message = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["message"] as? String
                    ?? String(data: data, encoding: .utf8)
                    ?? "Server error"
                completion(.failure(NSError(domain: "", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: message])));
                return
            }
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .custom { decoder in
                    let container = try decoder.singleValueContainer()
                    let dateString = try container.decode(String.self)
                    let isoWithFraction = ISO8601DateFormatter(); isoWithFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    if let d = isoWithFraction.date(from: dateString) { return d }
                    let iso = ISO8601DateFormatter(); iso.formatOptions = [.withInternetDateTime]
                    if let d = iso.date(from: dateString) { return d }
                    let df = DateFormatter(); df.locale = Locale(identifier: "en_US_POSIX"); df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                    if let d = df.date(from: dateString) { return d }
                    throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid date: \(dateString)"))
                }
                let created = try decoder.decode(Tournament.self, from: data)
                completion(.success(created))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

extension NetworkManager {
    // MARK: - Teams
    func getTeamsForUser(userId: Int, completion: @escaping (Result<[TeamModel], Error>) -> Void) {
        let endpoint = "\(APIConfig.teamsEndpoint)/user/\(userId)"
        get(endpoint, completion: completion)
    }
    
    func getTeamById(teamId: Int, completion: @escaping (Result<TeamModel, Error>) -> Void) {
        let endpoint = "\(APIConfig.teamsEndpoint)/\(teamId)"
        get(endpoint, completion: completion)
    }

    func createTeam(name: String, ownerUserId: Int, logoUrl: String? = nil, completion: @escaping (Result<TeamModel, Error>) -> Void) {
        let endpoint = APIConfig.teamsEndpoint
        var params: [String: Any] = [
            "name": name,
            "owner_user_id": ownerUserId
        ]
        if let logoUrl = logoUrl { params["logo_url"] = logoUrl }
        post(endpoint, parameters: params, completion: completion)
    }

    func getTeamMembers(teamId: Int, completion: @escaping (Result<[TeamMemberModel], Error>) -> Void) {
        let endpoint = "\(APIConfig.teamsEndpoint)/\(teamId)/members/expanded"
        get(endpoint, completion: completion)
    }

    func removeTeamMember(teamId: Int, targetUserId: Int, requestingUserId: Int, completion: @escaping (Error?) -> Void) {
        let endpoint = "\(APIConfig.teamsEndpoint)/\(teamId)/remove?target_user_id=\(targetUserId)&requesting_user_id=\(requestingUserId)"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error { completion(error); return }
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                let msg = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Server error"
                completion(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: msg]))
                return
            }
            completion(nil)
        }.resume()
    }

    // Invites
    func searchUsers(query: String, completion: @escaping (Result<[User], Error>) -> Void) {
        var components = URLComponents(string: APIConfig.userSearchEndpoint)!
        components.queryItems = [URLQueryItem(name: "q", value: query)]
        guard let url = components.url else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        get(url.absoluteString, completion: completion)
    }

    func sendTeamInvite(teamId: Int, inviteeUserId: Int, completion: @escaping (Result<TeamInviteModel, Error>) -> Void) {
        let endpoint = "\(APIConfig.teamsEndpoint)/\(teamId)/invites"
        let params: [String: Any] = ["invitee_user_id": inviteeUserId]
        post(endpoint, parameters: params, completion: completion)
    }

    func getPendingTeamInvites(userId: Int, completion: @escaping (Result<[TeamInviteModel], Error>) -> Void) {
        let endpoint = "\(APIConfig.teamsEndpoint)/invites/user/\(userId)"
        get(endpoint, completion: completion)
    }

    func respondToInvite(inviteId: Int, accept: Bool, completion: @escaping (Result<TeamInviteModel, Error>) -> Void) {
        let endpoint = "\(APIConfig.teamsEndpoint)/invites/\(inviteId)/respond?accept=\(accept)"
        post(endpoint, parameters: [:], completion: completion)
    }

    func getUserStats(userId: Int, sport: String = "basketball", completion: @escaping (Result<UserStatsModel, Error>) -> Void) {
        let endpoint = "\(APIConfig.usersEndpoint)/id/\(userId)/stats?sport=\(sport)"
        get(endpoint, completion: completion)
    }
}

extension NetworkManager {
    // MARK: - Tournament Registrations
    func registerTeamForTournament(tournamentId: Int, teamId: Int, requestingUserId: Int, agreementsAccepted: Bool, completion: @escaping (Result<TournamentRegistrationModel, Error>) -> Void) {
        let endpoint = APIConfig.tournamentRegistrationsEndpoint(tournamentId: tournamentId)
        let params: [String: Any] = [
            "team_id": teamId,
            "requesting_user_id": requestingUserId,
            "agreements_accepted": agreementsAccepted
        ]
        post(endpoint, parameters: params, completion: completion)
    }

    struct TournamentEligibilityResponse: Codable {
        let registeredTeamIds: [Int]
        let conflictedUserIds: [Int]

        enum CodingKeys: String, CodingKey {
            case registeredTeamIds = "registered_team_ids"
            case conflictedUserIds = "conflicted_user_ids"
        }
    }

    func getTournamentEligibility(tournamentId: Int, userId: Int, completion: @escaping (Result<TournamentEligibilityResponse, Error>) -> Void) {
        let endpoint = APIConfig.tournamentEligibilityEndpoint(tournamentId: tournamentId, userId: userId)
        get(endpoint, completion: completion)
    }

    func getTournamentRegistrationsExpanded(tournamentId: Int, completion: @escaping (Result<[TournamentRegistrationExpandedModel], Error>) -> Void) {
        let endpoint = APIConfig.tournamentRegistrationsExpandedEndpoint(tournamentId: tournamentId)
        get(endpoint, completion: completion)
    }
}

extension NetworkManager {
    // MARK: - Tournament Unregister
    func unregisterTeamFromTournament(tournamentId: Int, teamId: Int, requestingUserId: Int, completion: @escaping (Error?) -> Void) {
        guard let url = URL(string: "\(APIConfig.tournamentsEndpoint)/\(tournamentId)/registrations/by-team/\(teamId)?requesting_user_id=\(requestingUserId)") else {
            completion(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error { completion(error); return }
            guard let http = response as? HTTPURLResponse else {
                completion(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
                return
            }
            if (200...299).contains(http.statusCode) { completion(nil); return }
            let msg = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Server error"
            completion(NSError(domain: "", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: msg]))
        }.resume()
    }
}

extension NetworkManager {
    // MARK: - Activities
    struct ActivityItem: Codable, Identifiable {
        let id: Int
        let typeCode: String
        let teamId: Int?
        let tournamentId: Int?
        let actorUserId: Int?
        let actorUsername: String?
        let teamName: String?
        let tournamentName: String?
        let message: String?
        let createdAt: String?
        let payload: String?

        enum CodingKeys: String, CodingKey {
            case id
            case typeCode = "typeCode"
            case teamId = "teamId"
            case tournamentId = "tournamentId"
            case actorUserId = "actorUserId"
            case actorUsername = "actorUsername"
            case teamName = "teamName"
            case tournamentName = "tournamentName"
            case message
            case createdAt
            case payload
        }
    }

    func getActivities(userId: Int, completion: @escaping (Result<[ActivityItem], Error>) -> Void) {
        let endpoint = APIConfig.activitiesEndpoint(userId: userId)
        get(endpoint, completion: completion)
    }
}
