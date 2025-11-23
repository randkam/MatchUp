import SwiftUI
import AVKit

struct LoadingScreenView: View {
    @StateObject private var authCoordinator = AuthenticationCoordinator.shared
    @State private var player: AVPlayer?
    @State private var isLoadingComplete = false
    @State private var logoOpacity: Double = 0
    
    var body: some View {
        ZStack {
            ModernColorScheme.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Logo/Video - minimal and clean
                if let player = player {
                    VideoPlayerView(player: player)
                        .frame(width: 160, height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .opacity(logoOpacity)
                        .onAppear {
                            player.play()
                            withAnimation(.easeIn(duration: 0.6)) {
                                logoOpacity = 1.0
                            }
                        }
                } else {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 160, height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .opacity(logoOpacity)
                        .onAppear {
                            withAnimation(.easeIn(duration: 0.6)) {
                                logoOpacity = 1.0
                            }
                        }
                }
                
                // Minimal loading indicator
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: ModernColorScheme.primary))
                    .scaleEffect(1.0)
                    .padding(.top, 60)
                
                Spacer()
            }
            
            if isLoadingComplete {
                NavigationLink(destination: CustomTabView()) {
                    EmptyView()
                }
                .opacity(0)
                .frame(width: 0, height: 0)
                .disabled(!isLoadingComplete)
            }
        }
        .onAppear {
            setupPlayer()
        }
    }
    
    private func setupPlayer() {
        if let url = Bundle.main.url(forResource: "logo", withExtension: "mp4") {
            player = AVPlayer(url: url)
            player?.isMuted = true
            player?.actionAtItemEnd = .none
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: player?.currentItem,
                queue: .main
            ) { _ in
                player?.seek(to: .zero)
                player?.play()
            }
            player?.play()
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                isLoadingComplete = true
            }
        } else {
            print("Error: Video file not found")
            // Still allow navigation after delay even if video fails
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isLoadingComplete = true
            }
        }
    }
}

struct NextView: View {
    var body: some View {
        Text("Next View")
    }
}

struct LoadingScreenView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            LoadingScreenView()
        }
    }
}
