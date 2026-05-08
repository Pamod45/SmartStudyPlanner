import XCTest
@testable import SmartStudyPlanner

final class UserTests: XCTestCase {

    func testAppUserFirestoreDataMapping() {
        let date = Date()
        let user = AppUser(
            id: "u123",
            email: "test@example.com",
            displayName: "Test User",
            domain: "Science",
            institute: "MIT",
            username: "tester",
            createdAt: date,
            lastLoginAt: date,
            isEmailVerified: true,
            authProvider: .google,
            updatedAt: date
        )
        
        let data = user.firestoreData
        
        XCTAssertEqual(data["id"] as? String, "u123")
        XCTAssertEqual(data["email"] as? String, "test@example.com")
        XCTAssertEqual(data["displayName"] as? String, "Test User")
        XCTAssertEqual(data["domain"] as? String, "Science")
        XCTAssertEqual(data["institute"] as? String, "MIT")
        XCTAssertEqual(data["isEmailVerified"] as? Bool, true)
        XCTAssertEqual(data["authProvider"] as? String, "google")
    }

    func testAppUserInitFromDictionary() {
        let data: [String: Any] = [
            "email": "dict@example.com",
            "displayName": "Dict User",
            "authProvider": "apple",
            "isEmailVerified": false
        ]
        
        let user = AppUser(from: data, uid: "uid_456")
        
        XCTAssertNotNil(user)
        XCTAssertEqual(user?.id, "uid_456")
        XCTAssertEqual(user?.email, "dict@example.com")
        XCTAssertEqual(user?.displayName, "Dict User")
        XCTAssertEqual(user?.authProvider, .apple)
        XCTAssertFalse(user?.isEmailVerified ?? true)
    }

    func testAppUserInitFailsWithoutRequiredFields() {
        let data: [String: Any] = [
            "displayName": "No Email User"
        ]
        let user = AppUser(from: data, uid: "uid_789")
        XCTAssertNil(user, "Init should fail if email is missing")
    }
}
