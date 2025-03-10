import SwiftUI
import Firebase  // Firebase modülünü ekledik

@main
struct MoodSyncApp: App {
    init() {
        FirebaseApp.configure()  // 📌 Firebase başlatılıyor!
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
