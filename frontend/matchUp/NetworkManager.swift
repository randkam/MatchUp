import Foundation
import CommonCrypto  // For HMAC algorithm

// Define the User model (if not already present in your project)
struct User: Codable {
    let userId: Int
    let userName: String
    let userNickName: String
    let email: String
    let userPassword: String
    var token: String?  // Assuming you want to store the JWT token here
}
struct UserLocation: Codable {
    let id: Int
    let userId: Int
    let locationId: Int
}

class NetworkManager {
//    static let shared = NetworkManager()
//       
//    private init() { } // Prevents external instantiation
    
    let secretKey = "your_secret_key"  // Replace with your actual secret key
    
    let sudoUser = "sudo"
    let sudoPassword = "supersecret"
    let sudoNickName = "sudoman"

    // Function to generate a JWT token based on email and password
    private func generateJWTToken(for identifier: String, password: String) -> String? {
        let header = ["alg": "HS256", "typ": "JWT"]
        let payload = ["identifier": identifier, "password": password]
        
        guard let headerData = try? JSONSerialization.data(withJSONObject: header, options: []),
              let payloadData = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            return nil
        }
        
        let headerBase64 = headerData.base64EncodedString()
        let payloadBase64 = payloadData.base64EncodedString()
        let toSign = "\(headerBase64).\(payloadBase64)"
        
        guard let signature = signData(toSign, withKey: secretKey) else {
            return nil
        }
        
        return "\(toSign).\(signature)"
    }
    
    // Function to sign data with a secret key
    private func signData(_ data: String, withKey key: String) -> String? {
        guard let keyData = key.data(using: .utf8),
              let dataToSign = data.data(using: .utf8) else {
            return nil
        }
        
        var hmac = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        dataToSign.withUnsafeBytes { dataBytes in
            keyData.withUnsafeBytes { keyBytes in
                CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256), keyBytes.baseAddress, keyData.count, dataBytes.baseAddress, dataToSign.count, &hmac)
            }
        }
        
        let hmacData = Data(hmac)
        return hmacData.base64EncodedString()
    }
    func updateUserProfile(userId: Int, userName: String, userNickName: String, email: String, completion: @escaping (Bool, Error?) -> Void) {
        guard let token = UserDefaults.standard.string(forKey: "userToken"),
              let url = URL(string: "\(APIConfig.usersEndpoint)/\(userId)") else {
            print("Profile Update Error: Invalid URL or missing token")
            completion(false, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL or missing token"]))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "userName": userName,
            "userNickName": userNickName,
            "email": email
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Profile Update Error: \(error.localizedDescription)")
                completion(false, error)
                return
            }

            guard let data = data else {
                print("Profile Update Error: No data received")
                completion(false, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received from the server."]))
                return
            }

            // Print the raw data as a string to debug the format
            if let rawResponse = String(data: data, encoding: .utf8) {
                print("Raw Server Response: \(rawResponse)")
            }
            
            do {
                let updatedUser = try JSONDecoder().decode(User.self, from: data)
                if updatedUser.userId == userId {
                    print("Profile updated successfully for user: \(updatedUser.userName)")
                    completion(true, nil)
                } else {
                    print("Profile Update Error: Profile update failed")
                    completion(false, NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Profile update failed"]))
                }
            } catch {
                print("Profile Update Error: \(error.localizedDescription)")
                completion(false, error)
            }
        }.resume()
    }
    
    // Function to fetch user locations and store them in UserDefaults
       func fetchUserLocations(userId: Int, completion: @escaping (Bool, Error?) -> Void) {
           guard let url = URL(string: "\(APIConfig.userLocationsEndpoint)/user/\(userId)") else {
               print("Invalid URL for fetching user locations")
               completion(false, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
               return
           }

           var request = URLRequest(url: url)
           request.httpMethod = "GET"
           request.addValue("application/json", forHTTPHeaderField: "Content-Type")
           



           URLSession.shared.dataTask(with: request) { data, response, error in
               if let data = data {
                   if let jsonString = String(data: data, encoding: .utf8) {
                       print("Server Response: \(jsonString)")
                   }
               }
               if let error = error {
                   print("Fetch User Locations Error: \(error.localizedDescription)")
                   completion(false, error)
                   return
               }

               guard let data = data else {
                   print("Fetch User Locations Error: No data received")
                   completion(false, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received from the server."]))
                   return
               }

               do {
                   let locations = try JSONDecoder().decode([UserLocation].self, from: data)
                   
                   // Extract location IDs and store in UserDefaults
                   let locationIds = locations.map { $0.locationId }
                   UserDefaults.standard.set(locationIds, forKey: "joinedLocations")
                   
                   print("Fetched and stored user locations: \(locationIds)")
                   completion(true, nil)
               } catch {
                   print("Fetch User Locations Error: \(error.localizedDescription)")
                   completion(false, error)
               }
           }.resume()
       }

    
    // Updated loginUser function with sudo user and login via either email or username
    func loginUser(identifier: String, password: String, completion: @escaping (Bool, Error?) -> Void) {
        // Check if it's the sudo user
        if (identifier == sudoUser || identifier == "sudo@localhost") && password == sudoPassword {
            print("Logged in as sudo user")

            // Generate a JWT token for the sudo user
            if let token = generateJWTToken(for: sudoUser, password: sudoPassword) {
                // Store sudo user data in UserDefaults
                UserDefaults.standard.set(token, forKey: "userToken")
                UserDefaults.standard.set("sudo@localhost", forKey: "loggedInUserEmail")
                UserDefaults.standard.set(sudoUser, forKey: "loggedInUserName")
                UserDefaults.standard.set(sudoNickName, forKey: "loggedInUserNickName")

                print("Logged in with sudo user: \(sudoUser), JWT Token: \(token)")
                completion(true, nil)
            } else {
                print("Login Error: Could not generate JWT token for sudo user")
                completion(false, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not generate JWT token for sudo user"]))
            }
            return
        }
    
    

        // Proceed with the regular login if not the sudo user
        guard let url = URL(string: "\(APIConfig.usersEndpoint)?identifier=\(identifier)") else {
            completion(false, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                print("🔁 Status Code: \(httpResponse.statusCode)")
                print("🔁 Response Headers: \(httpResponse.allHeaderFields)")
            }

            if let error = error {
                print("❌ URLSession Error: \(error.localizedDescription)")
            }

            if let data = data, let body = String(data: data, encoding: .utf8) {
                print("📦 Response Body: \(body)")
            }

            if let error = error {
                print("Login Error: \(error.localizedDescription)")
                completion(false, error)
                return
            }

            guard let data = data else {
                print("Login Error: No data received")
                completion(false, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received from the server."]))
                return
            }

            do {
                let users: [User] = try JSONDecoder().decode([User].self, from: data)

                // Check if the identifier matches email or username
                if var matchedUser = users.first(where: { ($0.email == identifier || $0.userName == identifier) && $0.userPassword == password }) {
                    print("Login successful for user: \(matchedUser.userName)")

                    // Generate JWT token for the user
                    if let token = self.generateJWTToken(for: matchedUser.email, password: matchedUser.userPassword) {
                        matchedUser.token = token
                        print("Generated JWT Token: \(token)")

                        // Store user data and token in UserDefaults
                        UserDefaults.standard.set(token, forKey: "userToken")
                        UserDefaults.standard.set(matchedUser.email, forKey: "loggedInUserEmail")
                        UserDefaults.standard.set(matchedUser.userName, forKey: "loggedInUserName")
                        UserDefaults.standard.set(matchedUser.userNickName, forKey: "loggedInUserNickName")
                        UserDefaults.standard.set(matchedUser.userId, forKey: "loggedInUserId")
                        

                        print("Logged in with email/username: \(matchedUser.email), JWT Token: \(token)")
                        completion(true, nil)
                    } else {
                        print("Login Error: Could not generate JWT token")
                        completion(false, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not generate JWT token"]))
                    }
                } else {
                    print("Login Error: Invalid credentials")
                    completion(false, NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invalid credentials"]))
                }
            } catch {
                print("Login Error: \(error.localizedDescription)")
                completion(false, error)
            }
        }.resume()
    }
    
    // Function to create a new account
    func createAccount(userName: String, userNickName: String, email: String,userId: Int, password: String, completion: @escaping (Bool, Error?) -> Void) {
        guard let url = URL(string: APIConfig.usersEndpoint) else {
            completion(false, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "userName": userName,
            "userNickName": userNickName,
            "email": email,
            "userPassword": password,  // Ensure this matches the expected key in your backend
            "userId" : userId
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Create Account Error: \(error.localizedDescription)")
                completion(false, error)
                return
            }
            
            guard let data = data else {
                print("Create Account Error: No data received")
                completion(false, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received from the server."]))
                return
            }
            
            // Print the raw data as a string to debug the format
            if let rawResponse = String(data: data, encoding: .utf8) {
                print("Raw Server Response: \(rawResponse)")
            }
            
            do {
                let createdUser = try JSONDecoder().decode(User.self, from: data)
                if createdUser.email == email {
                    print("Account created successfully for user: \(createdUser.userName)")
                    completion(true, nil)
                } else {
                    print("Create Account Error: Account creation failed")
                    completion(false, NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Account creation failed"]))
                }
            } catch {
                print("Create Account Error: \(error.localizedDescription)")
                completion(false, error)
            }
        }.resume()
    }
    
    // Function to get user profile
    func getUserProfile(completion: @escaping (String?, String?, String?) -> Void) {
        // Retrieve email and token from UserDefaults
        guard let email = UserDefaults.standard.string(forKey: "loggedInUserEmail"),
              let token = UserDefaults.standard.string(forKey: "userToken") else {
            print("Profile Error: loggedInUserEmail or userToken is nil when trying to fetch profile")
            completion(nil, nil, nil)
            return
        }
        
        print("Fetching profile for email: \(email)")
        
        guard let url = URL(string: "\(APIConfig.usersEndpoint)?email=\(email)") else {
            print("Profile Error: Invalid URL")
            completion(nil, nil, nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")  // Add the token to the header
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Profile Error: \(error.localizedDescription)")
                completion(nil, nil, nil)
                return
            }
            
            guard let data = data else {
                print("Profile Error: No data received")
                completion(nil, nil, nil)
                return
            }
            
            do {
                let users = try JSONDecoder().decode([User].self, from: data)
                if let user = users.first(where: { $0.email == email }) {
                    print("Profile fetched for user: \(user.userName)")
                    completion(user.userName, user.userNickName, user.email)
                } else {
                    print("Profile Error: No user found with the email \(email)")
                    completion(nil, nil, nil)
                }
            } catch {
                print("Profile Error: \(error.localizedDescription)")
                completion(nil, nil, nil)
            }
        }.resume()
    }
}
