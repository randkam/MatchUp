import SwiftUI

struct InviteUsersView: View {
    let team: TeamModel
    @State private var query: String = ""
    @State private var results: [User] = []
    @State private var isSearching = false
    @State private var toast: String? = nil
    private let network = NetworkManager()
    
    var body: some View {
        ZStack(alignment: .top) {
            ModernColorScheme.background
                .ignoresSafeArea()
            VStack(alignment: .leading, spacing: 12) {
            // Search bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(ModernColorScheme.accentMinimal)
                TextField("Search users by name or email", text: $query)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .onSubmit { performSearch() }
                    .onChange(of: query) { _ in debouncedSearch() }
                if !query.isEmpty {
                    Button(action: clearSearch) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(ModernColorScheme.accentMinimal)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(14)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(14)
            .padding(.horizontal)

            // States
            if isSearching && results.isEmpty {
                loadingSkeleton
                    .padding(.horizontal)
            } else if !isSearching && results.isEmpty && !query.trimmingCharacters(in: .whitespaces).isEmpty {
                emptyState
                    .padding(.horizontal)
            } else {
                // Results list
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(results, id: \.userId) { u in
                            HStack(spacing: 12) {
                                AvatarView(userId: u.userId, userName: u.userNickName.isEmpty ? u.userName : u.userNickName, size: 42)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(u.userNickName.isEmpty ? u.userName : u.userNickName)
                                        .foregroundColor(ModernColorScheme.text)
                                        .font(.system(size: 16, weight: .semibold))
                                    Text(u.userEmail)
                                        .font(.caption)
                                        .foregroundColor(ModernColorScheme.textSecondary)
                                }
                                Spacer()
                                Button {
                                    invite(userId: Int(u.userId))
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "paperplane.fill")
                                        Text("Invite")
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .padding(12)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
    private func clearSearch() {
        query = ""
        results = []
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

    // MARK: - Subviews
    private var loadingSkeleton: some View {
        VStack(spacing: 10) {
            ForEach(0..<6, id: \.self) { _ in
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.gray.opacity(0.25))
                        .frame(width: 42, height: 42)
                    VStack(alignment: .leading, spacing: 6) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.25))
                            .frame(height: 12)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 180, height: 10)
                    }
                    Spacer()
                }
                .padding(12)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                .redacted(reason: .placeholder)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 40))
                .foregroundColor(ModernColorScheme.accentMinimal)
            Text("No users found")
                .font(.headline)
                .foregroundColor(ModernColorScheme.text)
            Text("Try a full email or a different name.")
                .font(.subheadline)
                .foregroundColor(ModernColorScheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 40)
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


