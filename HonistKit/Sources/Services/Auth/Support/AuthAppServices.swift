import HonistFoundation
import HonistCore
import HonistNetworking

public final class AuthAppServices {

    public static let shared = AuthAppServices()
    
    public let authAPI: AuthenticationAPI
    public let authLogic: AuthLogic
    
    private init() {
        // Build API on top of shared registry client
        self.authAPI = AuthenticationAPI(
            client: HonistRegistry.shared.apiClient,
            config: .init(hmacSecret: AppEnvironment.hmacSecret)
        )

        // Build AuthLogic using the shared store from registry
        self.authLogic = AuthLogic(store: HonistRegistry.shared.tokenStore, api: authAPI)

        // Register refresher globally so all services auto-refresh tokens
        HonistRegistry.shared.registerTokenRefresher(self.authLogic)
    }
}

/*
 import HonistKit

 Task {
     let me = try await AuthAppServices.shared.authLogic.meWithAutoRefresh()
     print("Current user:", me.username ?? "—")
 }
 */


/*
 import HonistKit
 import HonistNetworking
 import HonistFoundation

 final class AuthBootstrapper {
     // 1) Token store + provider
     private let tokenStore = TokenStore()
     private lazy var tokenProvider = AuthTokenProviderAdapter(store: tokenStore)

     private lazy var apiClient = HonistApiClient(
         tokenProvider: tokenProvider,
         options: .init(debugLogging: true) // enable to see body/log
     )

     // 3) Auth API with HMAC secret
     private lazy var authAPI = AuthenticationAPI(
         client: apiClient,
         config: .init(hmacSecret: "sk-9f7a2xBtL8wZp3Qy") // ← your HMAC secret
     )

     // 4) Logic
     lazy var authLogic = AuthLogic(store: tokenStore, api: authAPI)

     // Example flow
     func firstLoginExample() {
         Task {
             do {
                 // Build login request (fill in values from Telegram SDK/session)
                 let req = LoginRequest(
                     telegramId: "987654321012345678",
                     verificationCode: "134781", // optional. set only if needed
                     accessHash: "123450987654321",
                     phoneNumber: "09125933044",
                     firstName: "Test",
                     lastName: "Bot",
                     username: "test_bot",
                     languageCode: "en",
                     isPremium: false,
                     isBot: false,
                     status: .init(lastSeen: ISO8601DateFormatter().date(from: "2025-09-06T14:20:00.000Z"), online: true),
                     verified: false,
                     restricted: false,
                     restrictionReason: nil,
                     twoStepEnabled: false,
                     deviceLabel: "iPhone 15 Pro"
                 )

                 // 1) Login (stores tokens automatically)
                 let user = try await authLogic.login(request: req)
                 print("✅ Logged in as:", user.username ?? "—")

                 // 2) Authorized call (fetch me), with auto-refresh if needed
                 let me = try await authLogic.meWithAutoRefresh()
                 print("👤 Me:", me.id)

                 // 3) Optional: logout current session
                 // try await authLogic.logoutCurrentSession()

                 // 4) Optional: logout all sessions
                 // try await authLogic.logoutAllSessions()

             } catch {
                 print("❌ Auth error:", error.localizedDescription)
             }
         }
     }
 }
 */
