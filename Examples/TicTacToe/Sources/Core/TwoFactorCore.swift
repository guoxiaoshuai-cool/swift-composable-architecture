import AuthenticationClient
import Combine
import ComposableArchitecture
import Dispatch
import TicTacToeCommon

public struct TwoFactorState: Equatable {
  public var alertData: AlertData? = nil
  public var code = ""
  public var isFormValid = false
  public var isTwoFactorRequestInFlight = false
  public let token: String

  public init(token: String) {
    self.token = token
  }
}

public enum TwoFactorAction: Equatable {
  case alertDismissed
  case codeChanged(String)
  case submitButtonTapped
  case twoFactorResponse(Result<AuthenticationResponse, AuthenticationError>)
}

public struct TwoFactorEnvironment {
  public var authenticationClient: AuthenticationClient
  public var mainQueue: AnySchedulerOf<DispatchQueue>

  public init(
    authenticationClient: AuthenticationClient,
    mainQueue: AnySchedulerOf<DispatchQueue>
  ) {
    self.authenticationClient = authenticationClient
    self.mainQueue = mainQueue
  }
}

public let twoFactorReducer = Reducer<TwoFactorState, TwoFactorAction, TwoFactorEnvironment> {
  state, action, environment in

  switch action {
  case .alertDismissed:
    state.alertData = nil
    return .none

  case let .codeChanged(code):
    state.code = code
    state.isFormValid = code.count >= 4
    return .none

  case .submitButtonTapped:
    state.isTwoFactorRequestInFlight = true
    return environment.authenticationClient
      .twoFactor(TwoFactorRequest(code: state.code, token: state.token))
      .receive(on: environment.mainQueue)
      .catchToEffect()
      .map(TwoFactorAction.twoFactorResponse)

  case let .twoFactorResponse(.failure(error)):
    state.alertData = AlertData(title: error.localizedDescription)
    state.isTwoFactorRequestInFlight = false
    return .none

  case let .twoFactorResponse(.success(response)):
    state.isTwoFactorRequestInFlight = false
    return .none
  }
}