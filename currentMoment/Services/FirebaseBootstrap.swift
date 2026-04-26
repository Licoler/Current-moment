import Foundation

#if canImport(FirebaseCore)
import FirebaseCore
#endif

enum FirebaseBootstrap {
    static func configureIfAvailable() {
        #if canImport(FirebaseCore)
        guard FirebaseApp.app() == nil else {
            return
        }

        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
        }
        #endif
    }
}
