//
//  AuthViewModelTests.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

import XCTest
@testable import TodoList

final class MockAuthAPIClient: AuthAPIClient {
    var registerResult: Result<MessageResponse, Error> = .success(MessageResponse(message: "usuário criado com sucesso"))
    var loginResult: Result<LoginResponse, Error> = .success(LoginResponse(token: "fake-token"))
    private(set) var registerCallCount = 0
    private(set) var loginCallCount = 0
    private(set) var restoredToken: String?
    private(set) var logoutCallCount = 0

    func restoreToken(_ token: String) {
        restoredToken = token
    }

    func logout() {
        logoutCallCount += 1
    }

    func register(username: String, password: String) async throws -> MessageResponse {
        registerCallCount += 1
        return try registerResult.get()
    }

    func login(username: String, password: String) async throws -> LoginResponse {
        loginCallCount += 1
        return try loginResult.get()
    }
}

@MainActor
final class AuthViewModelTests: XCTestCase {

    func testLoginSuccessUpdatesStateToSignedIn() async {
        let mock = MockAuthAPIClient()
        let viewModel = AuthViewModel(apiClient: mock)

        await viewModel.login(username: "renan", password: "senha123")

        XCTAssertEqual(viewModel.state, .signedIn)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(mock.loginCallCount, 1)
    }

    func testLoginFailureSetsErrorMessageAndKeepsSignedOut() async {
        let mock = MockAuthAPIClient()
        mock.loginResult = .failure(APIError.server(message: "usuário ou senha incorretos"))
        let viewModel = AuthViewModel(apiClient: mock)

        await viewModel.login(username: "renan", password: "errada")

        XCTAssertEqual(viewModel.state, .signedOut)
        XCTAssertEqual(viewModel.errorMessage, "usuário ou senha incorretos")
    }

    func testLoginWithEmptyFieldsDoesNotCallAPI() async {
        let mock = MockAuthAPIClient()
        let viewModel = AuthViewModel(apiClient: mock)

        await viewModel.login(username: "", password: "")

        XCTAssertEqual(mock.loginCallCount, 0)
        XCTAssertEqual(viewModel.errorMessage, "Preencha usuário e senha")
    }

    func testRegisterSuccessCallsAPIWithoutChangingAuthState() async {
        let mock = MockAuthAPIClient()
        let viewModel = AuthViewModel(apiClient: mock)

        await viewModel.register(username: "renan", password: "senha123")

        XCTAssertEqual(mock.registerCallCount, 1)
        XCTAssertEqual(viewModel.state, .signedOut)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testLogoutResetsStateToSignedOut() async {
        let mock = MockAuthAPIClient()
        let viewModel = AuthViewModel(apiClient: mock)
        await viewModel.login(username: "renan", password: "senha123")

        viewModel.logout()

        XCTAssertEqual(viewModel.state, .signedOut)
    }
    
    func testRegisterAndLoginCallsBothAndSignsInOnSuccess() async {
        let mock = MockAuthAPIClient()
        let viewModel = AuthViewModel(apiClient: mock)

        await viewModel.registerAndLogin(username: "renan", password: "senha123")

        XCTAssertEqual(mock.registerCallCount, 1)
        XCTAssertEqual(mock.loginCallCount, 1)
        XCTAssertEqual(viewModel.state, .signedIn)
    }

    func testRegisterAndLoginStopsIfRegisterFails() async {
        let mock = MockAuthAPIClient()
        mock.registerResult = .failure(APIError.server(message: "usuário já existe"))
        let viewModel = AuthViewModel(apiClient: mock)

        await viewModel.registerAndLogin(username: "renan", password: "senha123")

        XCTAssertEqual(mock.registerCallCount, 1)
        XCTAssertEqual(mock.loginCallCount, 0)
        XCTAssertEqual(viewModel.errorMessage, "usuário já existe")
        XCTAssertEqual(viewModel.state, .signedOut)
    }
    
    func testAttemptBiometricLoginRestoresTokenAndSignsIn() async {
        let mockAPI = MockAuthAPIClient()
        let mockKeychain = MockKeychainService()
        mockKeychain.savedToken = "saved-token"
        let mockBiometric = MockBiometricService()

        let viewModel = AuthViewModel(
            apiClient: mockAPI,
            keychainService: mockKeychain,
            biometricService: mockBiometric
        )

        await viewModel.attemptBiometricLogin()

        XCTAssertEqual(viewModel.state, .signedIn)
        XCTAssertEqual(mockAPI.restoredToken, "saved-token")
    }

    func testAttemptBiometricLoginDoesNothingWhenNoTokenSaved() async {
        let mockAPI = MockAuthAPIClient()
        let mockKeychain = MockKeychainService()
        let mockBiometric = MockBiometricService()

        let viewModel = AuthViewModel(
            apiClient: mockAPI,
            keychainService: mockKeychain,
            biometricService: mockBiometric
        )

        await viewModel.attemptBiometricLogin()

        XCTAssertEqual(viewModel.state, .signedOut)
        XCTAssertNil(mockAPI.restoredToken)
    }

    func testAttemptBiometricLoginKeepsSignedOutWhenBiometricFails() async {
        let mockAPI = MockAuthAPIClient()
        let mockKeychain = MockKeychainService()
        mockKeychain.savedToken = "saved-token"
        let mockBiometric = MockBiometricService()
        mockBiometric.authenticationResult = .success(false)

        let viewModel = AuthViewModel(
            apiClient: mockAPI,
            keychainService: mockKeychain,
            biometricService: mockBiometric
        )

        await viewModel.attemptBiometricLogin()

        XCTAssertEqual(viewModel.state, .signedOut)
    }

    func testLoginSavesTokenToKeychain() async {
        let mockAPI = MockAuthAPIClient()
        let mockKeychain = MockKeychainService()
        let mockBiometric = MockBiometricService()

        let viewModel = AuthViewModel(
            apiClient: mockAPI,
            keychainService: mockKeychain,
            biometricService: mockBiometric
        )

        await viewModel.login(username: "renan", password: "senha123")

        XCTAssertEqual(mockKeychain.savedToken, "eyJhbGciOiJIUzI1NiIs...")
    }

    func testLogoutClearsKeychainAndSignsOut() async {
        let mockAPI = MockAuthAPIClient()
        let mockKeychain = MockKeychainService()
        mockKeychain.savedToken = "token-salvo"
        let mockBiometric = MockBiometricService()

        let viewModel = AuthViewModel(
            apiClient: mockAPI,
            keychainService: mockKeychain,
            biometricService: mockBiometric
        )
        await viewModel.login(username: "renan", password: "senha123")

        viewModel.logout()

        XCTAssertEqual(viewModel.state, .signedOut)
        XCTAssertNil(mockKeychain.savedToken)
        XCTAssertEqual(mockAPI.logoutCallCount, 1)
    }
}
