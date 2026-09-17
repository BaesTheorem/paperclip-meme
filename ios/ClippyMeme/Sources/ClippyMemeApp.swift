import SwiftUI

@main
struct ClippyMemeApp: App {
    var body: some Scene {
        WindowGroup {
            MemeWebView()
                .ignoresSafeArea(edges: .bottom)
                .background(Color.white)
        }
    }
}
