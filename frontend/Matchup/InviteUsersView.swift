import SwiftUI

struct InviteUsersView: View {
    let team: TeamModel
    @State private var query: String = ""
    @State private var results: [User] = []
    @State private var isSearching = false
    @State private var toast: String? = nil
    private let network = NetworkManager()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search users by name or email", text: $query)
                    .onChange(of: query) { _ in debouncedSearch() }
            }
            .padding()
            .background(ModernColorScheme.surface)
            .cornerRadius(12)
            .padding(.horizontal)
            
            if isSearching && results.isEmpty {
                ProgressView().tint(ModernColorScheme.primary)
            }
            
            List(results, id: \.userId) { u in
                HStack {
                    VStack(alignment: .leading) {
                        Text(u.userNickName.isEmpty ? u.userName : u.userNickName)
                            .foregroundColor(ModernColorScheme.text)
                        Text(u.userEmail)
                            .font(.caption)
                            .foregroundColor(ModernColorScheme.textSecondary)
                    }
                    Spacer()
                    Button("Invite") { invite(userId: Int(u.userId)) }
                        .buttonStyle(.borderedProminent)
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle("Invite Users")
        .navigationBarTitleDisplayMode(.inline)
        .toast(message: toast)
        .onDisappear { debounceWorkItem?.cancel() }
    }
    
    // MARK: - Search
    @State private var debounceWorkItem: DispatchWorkItem? = nil
    private func debouncedSearch() {
        debounceWorkItem?.cancel()
        let work = DispatchWorkItem { performSearch() }
        debounceWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: work)
    }
    private func performSearch() {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { results = []; return }
        isSearching = true
        network.searchUsers(query: query) { res in
            DispatchQueue.main.async {
                isSearching = false
                switch res {
                case .success(let users): results = users
                case .failure: results = []
                }
            }
        }
    }
    
    // MARK: - Invite
    private func invite(userId: Int) {
        network.sendTeamInvite(teamId: team.id, inviteeUserId: userId) { res in
            DispatchQueue.main.async {
                switch res {
                case .success: toast = "Invite sent"; performSearch()
                case .failure(let err): toast = err.localizedDescription
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { toast = nil }
            }
        }
    }
}

// Simple toast view modifier
private struct ToastModifier: ViewModifier {
    let message: String?
    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content
            if let message = message {
                Text(message)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(.black.opacity(0.75))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.bottom, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: message)
    }
}

private extension View {
    func toast(message: String?) -> some View { self.modifier(ToastModifier(message: message)) }
}


