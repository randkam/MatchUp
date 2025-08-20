import SwiftUI

final class UserProfileCache: ObservableObject {
    static let shared = UserProfileCache()
    private var userIdToURL: [Int: URL?] = [:]
    private var inflightRequests: Set<Int> = []
    private let queue = DispatchQueue(label: "UserProfileCache.queue", attributes: .concurrent)

    func getProfileURL(for userId: Int, completion: @escaping (URL?) -> Void) {
        queue.sync {
            if let cached = userIdToURL[userId] {
                DispatchQueue.main.async { completion(cached ?? nil) }
                return
            }
        }

        var shouldFetch = false
        queue.sync(flags: .barrier) {
            if !inflightRequests.contains(userId) {
                inflightRequests.insert(userId)
                shouldFetch = true
            }
        }

        if !shouldFetch {
            // Another request is already in flight; poll after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                guard let self = self else { completion(nil); return }
                self.getProfileURL(for: userId, completion: completion)
            }
            return
        }

        let urlString = APIConfig.userByIdEndpoint(userId: userId)
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
            defer {
                self?.queue.async(flags: .barrier) { [weak self] in
                    self?.inflightRequests.remove(userId)
                }
            }

            guard let self = self, let data = data else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            struct LightweightUser: Codable { let profilePictureUrl: String? }

            let profileURL: URL?
            if let decoded = try? JSONDecoder().decode(LightweightUser.self, from: data),
               let urlString = decoded.profilePictureUrl,
               let formed = URL(string: urlString) {
                profileURL = formed
            } else {
                profileURL = nil
            }

            self.queue.async(flags: .barrier) {
                self.userIdToURL[userId] = profileURL
            }
            DispatchQueue.main.async { completion(profileURL) }
        }.resume()
    }
}

struct AvatarView: View {
    let userId: Int
    let userName: String
    var size: CGFloat = 30

    @State private var imageURL: URL?

    private var initials: String {
        let parts = userName.split(separator: " ")
        let first = parts.first?.first.map { String($0) } ?? ""
        let second = parts.dropFirst().first?.first.map { String($0) } ?? ""
        let combined = (first + second)
        return combined.isEmpty ? String(userName.prefix(1)) : combined
    }

    var body: some View {
        Group {
            if let url = imageURL {
                AsyncImage(url: url, transaction: Transaction(animation: .easeInOut)) { phase in
                    switch phase {
                    case .empty:
                        placeholder
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .onAppear {
            if imageURL == nil {
                UserProfileCache.shared.getProfileURL(for: userId) { url in
                    self.imageURL = url
                }
            }
        }
    }

    private var placeholder: some View {
        ZStack {
            Circle()
                .fill(Color.gray.opacity(0.3))
            Text(initials.uppercased())
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

