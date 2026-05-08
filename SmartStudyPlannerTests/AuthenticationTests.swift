import XCTest
import FirebaseAuth
import FirebaseCore
@testable import SmartStudyPlanner

final class AuthenticationTests: XCTestCase {

    override func setUp() {
        super.setUp()
        configureFirebaseIfNeeded()
        UserDefaults.standard.removeObject(forKey: "faceId_email")
        UserDefaults.standard.removeObject(forKey: "faceId_password")
    }

    override func tearDown() {
        try? AuthService.shared.signOut()
        UserDefaults.standard.removeObject(forKey: "faceId_email")
        UserDefaults.standard.removeObject(forKey: "faceId_password")
        super.tearDown()
    }

    func testEmailPasswordSignInSucceeds() async throws {
        let credentials = try testCredentials()

        let user = try await AuthService.shared.signIn(
            email: credentials.email,
            password: credentials.password
        )

        XCTAssertFalse(user.id.isEmpty)
        XCTAssertEqual(user.email.lowercased(), credentials.email.lowercased())
    }

    func testEmailPasswordSignInFailsWithWrongPassword() async throws {
        let credentials = try testCredentials()

        do {
            _ = try await AuthService.shared.signIn(
                email: credentials.email,
                password: "__wrong_password_for_auth_test__"
            )
            XCTFail("Sign in should fail when the password is incorrect.")
        } catch {
            XCTAssertFalse(error.localizedDescription.isEmpty)
        }
    }

    func testCurrentUserCanBeRestoredAfterSignIn() async throws {
        let credentials = try testCredentials()
        let signedInUser = try await AuthService.shared.signIn(
            email: credentials.email,
            password: credentials.password
        )

        let restoredUser = await AuthService.shared.getCurrentUser()

        XCTAssertEqual(restoredUser?.id, signedInUser.id)
        XCTAssertEqual(restoredUser?.email.lowercased(), credentials.email.lowercased())
    }

    func testSignOutClearsAuthenticatedUser() async throws {
        let credentials = try testCredentials()
        _ = try await AuthService.shared.signIn(
            email: credentials.email,
            password: credentials.password
        )

        try AuthService.shared.signOut()

        XCTAssertNil(Auth.auth().currentUser)
        let restoredUser = await AuthService.shared.getCurrentUser()
        XCTAssertNil(restoredUser)
    }

    func testProfileIsCachedAfterSignIn() async throws {
        let credentials = try testCredentials()
        let signedInUser = try await AuthService.shared.signIn(
            email: credentials.email,
            password: credentials.password
        )

        let cachedUser = CoreDataService.shared.getCachedProfile()

        XCTAssertEqual(cachedUser?.id, signedInUser.id)
        XCTAssertEqual(cachedUser?.email.lowercased(), credentials.email.lowercased())
    }

    @MainActor
    func testFaceIDSignInFailsWithoutSavedCredentials() async {
        let viewModel = AuthViewModel()
        var receivedUser: AppUser?

        await viewModel.signInWithFaceID { user in
            receivedUser = user
        }

        XCTAssertNil(receivedUser)
        XCTAssertEqual(viewModel.errorMessage, "No saved credentials for Face ID.")
    }

    private func configureFirebaseIfNeeded() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }

    private func testCredentials() throws -> (email: String, password: String) {
        let environment = ProcessInfo.processInfo.environment
        guard let email = environment["AUTH_TEST_EMAIL"], !email.isEmpty,
              let password = environment["AUTH_TEST_PASSWORD"], !password.isEmpty else {
            throw XCTSkip("Set AUTH_TEST_EMAIL and AUTH_TEST_PASSWORD to run authentication tests.")
        }
        return (email, password)
    }
}
