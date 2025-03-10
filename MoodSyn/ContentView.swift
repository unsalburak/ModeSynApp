import SwiftUI
import FirebaseFirestore

struct ContentView: View {
    @State private var myMood: String = ""  // Kullanıcının ruh hali
    @State private var otherMood: String = "" // Karşı tarafın ruh hali
    @State private var myUserID: String?
    @State private var otherUserID: String?
    @State private var myMessage: String?
    @State private var otherMessage: String?

    let db = Firestore.firestore()

    var body: some View {
        VStack {
            if let myUserID = myUserID, let otherUserID = otherUserID {
                MoodSyncView(
                    myMood: $myMood,
                    otherMood: $otherMood,
                    myMessage: $myMessage,
                    otherMessage: $otherMessage,
                    db: db,
                    myUserID: myUserID,
                    otherUserID: otherUserID
                )
            } else {
                UserSelectionView(myUserID: $myUserID, otherUserID: $otherUserID)
            }
        }
    }
}

// 📌 Kullanıcı Seçim Ekranı
struct UserSelectionView: View {
    @Binding var myUserID: String?
    @Binding var otherUserID: String?

    var body: some View {
        VStack {
            Text("Hangi kullanıcı olduğunu seç:")
                .font(.title)
                .padding()

            HStack {
                Button("Ben Burak'ım") {
                    myUserID = "user1"
                    otherUserID = "user2"
                }
                .padding()
                .background(Color.blue.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                Button("Ben Sude'yim") {
                    myUserID = "user2"
                    otherUserID = "user1"
                }
                .padding()
                .background(Color.pink.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}

// 📌 Firestore Bağlantılı Ana Ekran
struct MoodSyncView: View {
    @Binding var myMood: String
    @Binding var otherMood: String
    @Binding var myMessage: String?
    @Binding var otherMessage: String?
    let db: Firestore
    let myUserID: String
    let otherUserID: String

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                
                // 📌 Üst Kısım: Kullanıcının Ruh Hali ve Mesajı
                VStack {
                    Text(myUserID == "user1" ? "Burak" : "Sude")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(myMood)
                        .font(.system(size: 100))
                        .frame(height: 120) // 📌 Sabit yükseklik vererek kaymayı engelle
                        .padding()

                    // 📌 Mesaj Giriş Alanı + Gönder Butonu
                    HStack {
                        TextField("Bir mesaj yaz...", text: Binding(
                            get: { myMessage ?? "" },
                            set: { myMessage = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(25)
                        .shadow(color: Color.gray.opacity(0.2), radius: 5, x: 0, y: 2)

                        Button(action: sendMessageToFirestore) {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(myMessage?.isEmpty ?? true ? Color.gray : Color.blue)
                                .padding()
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 2)
                        }
                        .disabled(myMessage?.isEmpty ?? true)
                    }
                    .padding()

                    // 📌 Emoji Seçme Butonları (Sabit Hizalama ile)
                    VStack {
                        HStack {
                            MoodButton(emoji: "😊", selectedMood: $myMood, db: db, userID: myUserID)
                            MoodButton(emoji: "😢", selectedMood: $myMood, db: db, userID: myUserID)
                            MoodButton(emoji: "😡", selectedMood: $myMood, db: db, userID: myUserID)
                            MoodButton(emoji: "😴", selectedMood: $myMood, db: db, userID: myUserID)
                        }
                        HStack {
                            MoodButton(emoji: "📺", selectedMood: $myMood, db: db, userID: myUserID)
                            MoodButton(emoji: "🎮", selectedMood: $myMood, db: db, userID: myUserID)
                            MoodButton(emoji: "😈", selectedMood: $myMood, db: db, userID: myUserID)
                            MoodButton(emoji: "❤️", selectedMood: $myMood, db: db, userID: myUserID)
                        }
                    }
                    .frame(height: 80) // 📌 Sabit yükseklik vererek kaymayı önle
                    .padding()
                }
                .frame(width: geometry.size.width, height: geometry.size.height * 0.5)
                .background(Color.blue.opacity(0.1))

                Divider()
                
                // 📌 Alt Kısım: Karşı Tarafın Ruh Hali ve Mesajı
                VStack {
                    Text(otherUserID == "user2" ? "Sude" : "Burak")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(otherMood)
                        .font(.system(size: 100))
                        .frame(height: 120) // 📌 Sabit yükseklik
                        .padding()
                    
                    Text("Mesaj: \(otherMessage ?? "Henüz mesaj yok.")")
                        .font(.subheadline)
                        .padding()
                }
                .frame(width: geometry.size.width, height: geometry.size.height * 0.5)
                .background(Color.pink.opacity(0.1))
            }
            .onAppear {
                listenForUpdates()
            }
        }
    }

    // 📌 Firestore'dan Gerçek Zamanlı Ruh Hali ve Mesaj Güncelleme
    func listenForUpdates() {
        db.collection("moods").document(otherUserID).addSnapshotListener { snapshot, error in
            if let document = snapshot, document.exists {
                self.otherMood = document.get("mood") as? String ?? "❤️"
                self.otherMessage = document.get("message") as? String
            }
        }
    }

    // 📌 Firestore’a Mesaj ve Emoji Gönderme
    func sendMessageToFirestore() {
        guard let myMessage = myMessage, !myMessage.isEmpty else { return }
        db.collection("moods").document(myUserID).setData([
            "mood": myMood,
            "message": myMessage
        ], merge: true)
        self.myMessage = nil // Mesajı gönderdikten sonra sıfırla
    }
}

// 📌 Emoji Seçme Butonu (Firestore’a Veri Kaydeden)
struct MoodButton: View {
    let emoji: String
    @Binding var selectedMood: String
    let db: Firestore
    let userID: String

    var body: some View {
        Button(action: {
            selectedMood = emoji
            updateMoodOnFirebase()
        }) {
            Text(emoji)
                .font(.largeTitle)
                .padding()
                .background(Color.gray.opacity(0.2))
                .clipShape(Circle())
                .frame(width: 70, height: 70) // 📌 Sabit buton boyutu
        }
    }

    func updateMoodOnFirebase() {
        db.collection("moods").document(userID).setData([
            "mood": selectedMood
        ], merge: true)
    }
}
