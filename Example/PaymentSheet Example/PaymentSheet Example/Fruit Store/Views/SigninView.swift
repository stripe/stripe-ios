//
//  SigninView.swift
//  FruitStore
// 

import AuthenticationServices
import Foundation
import SwiftUI

@available(iOS 14.0, *)
struct SigninView: View {
    @EnvironmentObject var model: FruitModel
    @State var errorAlertPresented = false
    @State var loginError: String?

    var body: some View {
        VStack {
            VStack {
                Spacer()
                Image("large_icon")
                    .resizable()
                    .frame(maxWidth: 176, maxHeight: 176)
                Spacer()
            }
            Spacer()
            SignInWithAppleButton { request in
                request.requestedScopes = [.email, .fullName]
            } onCompletion: { result in
                switch result {
                case .success(let authResults):
                    model.login(authResults)
                case .failure(let error):
                    loginError = error.localizedDescription
                    errorAlertPresented = true
                }
            }.alert(isPresented: $errorAlertPresented, content: {
                Alert(title: Text("Authorization failed: \(loginError ?? "Unknown Error")"))
            })
            .frame(maxHeight: 54)
            .cornerRadius(60)
            .padding(.horizontal, 46)
            .padding(.vertical, 12)
            Button(action: {
                model.loginGuest()
            }, label: {
                Text("or sign in as guest")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundColor(SecondaryButtonColor)
            })
            .padding(.bottom, 20)
        }
    }
}

@available(iOS 14.0, *)
struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ZStack {
                BackgroundColor.ignoresSafeArea()
                VStack {
                    SigninView()
                }
            }

        }
    }
}
