import ComposableArchitecture

@Reducer
public struct BinTextFieldReducer {
    @ObservableState
    public struct State: Equatable {
        var value: Int = 0
        var bitWidth: Bits = ._32
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { _, action in
            switch action {
            case .binding:
                return .none
            }
        }
    }
}
