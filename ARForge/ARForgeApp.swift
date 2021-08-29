//
//  ARForgeApp.swift
//  ARForge
//
//  Created by ARForgeQA on 8/28/21.
//

import SwiftUI
import GoogleSignIn

@main
struct ARForgeApp: App {
   
    var body: some Scene {
        WindowGroup {
            Content()
                .onOpenURL(perform: { url in
                    GIDSignIn.sharedInstance.handle(url)
                })
                .onAppear(perform: {
                    AppState.shared.initialSetup()
                })
        }
    }
}

struct Content: View {
    @ObservedObject var appStore = AppState.shared
    let totalPages = WalkThroughModel.getWalkThroughModels().count
    
    var body: some View {
        if (appStore.appScreenValue == .login) {
            LoginScreen()
        } else if (appStore.appScreenValue == .onboarding) {
            WalkthroughScreen()
        } else if (appStore.appScreenValue == .mainLanding) {
            ModelsScreen()
        } else {
            LaunchScreen()
        }
    }
}
