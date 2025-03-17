import SwiftUI

struct DropInView: View {
    @Binding var showDropInView: Bool
    @Binding var showLogin: Bool
    @Binding var showCreateAccount: Bool

    var body: some View {
        VStack {
            Spacer()

            // Title "Drop In the 6ix" Left-aligned and adjusted for better fit
            VStack(alignment: .leading) {
                Text("Drop")
                    .font(Font.custom("Inter", size: 110))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .padding(.top, 20)

                Text("In The")
                    .font(Font.custom("Inter", size: 110))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .padding(.top, -20)

                HStack(spacing: 0) {
                    Text("6")
                        .font(Font.custom("Inter", size: 120))
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    ZStack {
                        Text("i")
                            .font(Font.custom("Inter", size: 120))
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Circle()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.black)
                            .offset(y: -35)

                        Image(systemName: "basketball.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 30, height: 30)
                            .offset(y: -45)
                            .foregroundColor(.white)
                            .zIndex(1)
                    }

                    Text("x")
                        .font(Font.custom("Inter", size: 120))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .padding(.top, -30)
            }
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)

            Spacer(minLength: 20)

            // Login and Create Account buttons
            VStack(spacing: 20) {
                Button(action: {
                    showLogin = true
                    showDropInView = false
                }) {
                    Text("Sign in via Email")
                        .font(Font.custom("Inter", size: 18))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }

                Text("OR")
                    .font(Font.custom("Inter", size: 18))
                    .foregroundColor(.white)
                    .padding(.top, 5)
                    .padding(.bottom, 5)

                Button(action: {
                    showCreateAccount = true
                    showDropInView = false
                }) {
                    Text("Create an Account")
                        .font(Font.custom("Inter", size: 18))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
            .frame(maxWidth: .infinity)

            Spacer(minLength: 10)

            // Footer with terms and conditions
            Text("By continuing, you agree to the Terms and Conditions")
                .font(Font.custom("Inter", size: 12))
                .foregroundColor(.gray)
                .padding(.bottom, 5)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding()
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}
