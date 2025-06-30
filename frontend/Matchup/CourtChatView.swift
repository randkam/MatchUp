// import SwiftUI
// import CoreLocation
//
// struct CourtChatMessage: Identifiable {
//     let id = UUID()
//     let username: String
//     let message: String
//     let isCurrentUser: Bool
//     let timestamp: Date
// }
//
// struct CourtChatView: View {
//     let courtName: String
//     var isNewGame: Bool = false // Added to track if this is a new game or joining existing
//     @Environment(\.presentationMode) var presentationMode
//     @State private var messageText = ""
//     @State private var messages: [CourtChatMessage] = []
//     @State private var showWelcomeMessage = true
//    
//     // Sample data for demonstration
//     let sampleUsernames = ["JohnB", "MichaelJ", "SarahL", "CoachK", "DaveH"]
//     let sampleMessages = [
//         "Anyone up for a game?",
//         "I'll be there in 10 minutes",
//         "How many people are at the court now?",
//         "The weather is perfect for basketball today!",
//         "Looking for one more player for 3v3",
//         "Just finished a great game, anyone else want to play?",
//         "Does anyone have an extra ball?",
//         "I'm bringing water bottles for everyone"
//     ]
//    
//     var body: some View {
//         VStack {
//             // Header
//             HStack {
//                 Text(courtName)
//                     .font(ModernFontScheme.heading)
//                     .foregroundColor(ModernColorScheme.text)
//                
//                 Spacer()
//                
//                 Button(action: { presentationMode.wrappedValue.dismiss() }) {
//                     Image(systemName: "xmark.circle.fill")
//                         .font(.title2)
//                         .foregroundColor(ModernColorScheme.textSecondary)
//                 }
//             }
//             .padding()
//            
//             // Welcome Banner
//             if showWelcomeMessage {
//                 VStack(alignment: .leading, spacing: 8) {
//                     Text(isNewGame ? "Game Created!" : "Welcome to the Court Chat!")
//                         .font(ModernFontScheme.heading)
//                         .foregroundColor(.white)
//                    
//                     Text(isNewGame ? "You've started a new game at this court. Other players can now join you!" : "Join the conversation with players at this court.")
//                         .font(ModernFontScheme.body)
//                         .foregroundColor(.white.opacity(0.9))
//                    
//                     Button(action: {
//                         withAnimation {
//                             showWelcomeMessage = false
//                         }
//                     }) {
//                         Text("Dismiss")
//                             .font(ModernFontScheme.caption)
//                             .foregroundColor(.white)
//                             .padding(.vertical, 6)
//                             .padding(.horizontal, 12)
//                             .background(Color.white.opacity(0.3))
//                             .cornerRadius(8)
//                     }
//                 }
//                 .padding()
//                 .frame(maxWidth: .infinity, alignment: .leading)
//                 .background(isNewGame ? ModernColorScheme.primary : Color.green)
//                 .cornerRadius(12)
//                 .padding(.horizontal)
//                 .padding(.bottom, 8)
//             }
//            
//             // Messages
//             ScrollViewReader { scrollView in
//                 ScrollView {
//                     LazyVStack(alignment: .leading, spacing: 12) {
//                         ForEach(messages) { message in
//                             MessageBubble(message: message)
//                                 .id(message.id)
//                         }
//                     }
//                     .padding(.horizontal)
//                 }
//                 .onChange(of: messages.count) { _ in
//                     if let lastMessage = messages.last {
//                         withAnimation {
//                             scrollView.scrollTo(lastMessage.id, anchor: .bottom)
//                         }
//                     }
//                 }
//             }
//            
//             // Input area
//             HStack {
//                 TextField("Type a message...", text: $messageText)
//                     .padding(10)
//                     .background(ModernColorScheme.surface)
//                     .cornerRadius(20)
//                     .foregroundColor(ModernColorScheme.text)
//                
//                 Button(action: sendMessage) {
//                     Image(systemName: "paperplane.fill")
//                         .font(.title3)
//                         .foregroundColor(ModernColorScheme.primary)
//                         .padding(10)
//                         .background(ModernColorScheme.surface)
//                         .clipShape(Circle())
//                 }
//             }
//             .padding()
//         }
//         .background(ModernColorScheme.background.edgesIgnoringSafeArea(.all))
//         .onAppear {
//             loadInitialMessages()
//         }
//     }
//    
//     private func loadInitialMessages() {
//         // Load sample messages for demonstration
//         let now = Date()
//         let calendar = Calendar.current
//        
//         for i in 0..<5 {
//             let randomUsername = sampleUsernames.randomElement() ?? "User"
//             let randomMessage = sampleMessages.randomElement() ?? "Hello!"
//             let isCurrentUser = Bool.random()
//             let timestamp = calendar.date(byAdding: .minute, value: -i * 5, to: now) ?? now
//            
//             messages.append(CourtChatMessage(
//                 username: isCurrentUser ? "You" : randomUsername,
//                 message: randomMessage,
//                 isCurrentUser: isCurrentUser,
//                 timestamp: timestamp
//             ))
//         }
//        
//         // Sort messages by timestamp
//         messages.sort { $0.timestamp < $1.timestamp }
//     }
//    
//     private func sendMessage() {
//         guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
//        
//         let newMessage = CourtChatMessage(
//             username: "You",
//             message: messageText,
//             isCurrentUser: true,
//             timestamp: Date()
//         )
//        
//         messages.append(newMessage)
//         messageText = ""
//        
//         // Simulate a response after a short delay
//         DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 2...5)) {
//             let randomUsername = sampleUsernames.randomElement() ?? "User"
//             let randomMessage = sampleMessages.randomElement() ?? "Hello!"
//            
//             let responseMessage = CourtChatMessage(
//                 username: randomUsername,
//                 message: randomMessage,
//                 isCurrentUser: false,
//                 timestamp: Date()
//             )
//            
//             messages.append(responseMessage)
//         }
//     }
// }
//
// struct MessageBubble: View {
//     let message: CourtChatMessage
//    
//     var body: some View {
//         HStack {
//             if message.isCurrentUser { Spacer() }
//            
//             VStack(alignment: message.isCurrentUser ? .trailing : .leading, spacing: 2) {
//                 Text(message.username)
//                     .font(ModernFontScheme.caption)
//                     .foregroundColor(ModernColorScheme.textSecondary)
//                
//                 Text(message.message)
//                     .padding(10)
//                     .background(message.isCurrentUser ? ModernColorScheme.primary : ModernColorScheme.surface)
//                     .foregroundColor(message.isCurrentUser ? .white : ModernColorScheme.text)
//                     .cornerRadius(16)
//                
//                 Text(formatTimestamp(message.timestamp))
//                     .font(.system(size: 10))
//                     .foregroundColor(ModernColorScheme.textSecondary)
//             }
//            
//             if !message.isCurrentUser { Spacer() }
//         }
//     }
//    
//     private func formatTimestamp(_ date: Date) -> String {
//         let formatter = DateFormatter()
//         formatter.timeStyle = .short
//         return formatter.string(from: date)
//     }
// }
//
// struct CourtChatView_Previews: PreviewProvider {
//     static var previews: some View {
//         CourtChatView(courtName: "Central Park Court")
//     }
// }
