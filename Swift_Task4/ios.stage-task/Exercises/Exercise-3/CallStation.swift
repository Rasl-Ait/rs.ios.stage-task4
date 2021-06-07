import Foundation

final class CallStation {
	private(set) var usersAll: [User] = []
	private(set) var callAll: [Call] = []
	private var status = CallStatus.calling
}

extension CallStation: Station {
	func users() -> [User] {
		return usersAll
	}
	
	func add(user: User) {
		guard let index = usersAll.firstIndex(of: user) else {
			usersAll.append(user)
			return
		}
		
		usersAll[index] = user
	}
	
	func remove(user: User) {
		usersAll.removeAll() { $0 == user }
	}
	
	func execute(action: CallAction) -> CallID? {
		
		switch action {
		case .start(from: let incomingUser, to: let outgoingUser):
			guard usersAll.contains(incomingUser) || usersAll.contains(outgoingUser) else {
				return nil
			}
		
			if currentCall(user: incomingUser) != nil || currentCall(user: outgoingUser) != nil {
				status = .ended(reason: .userBusy)
			} else {
				status = usersAll.count < 2 ? .ended(reason: .error) : .calling
			}
			
			let call = Call(id: incomingUser.id,
											incomingUser: incomingUser,
											outgoingUser: outgoingUser,
											status: status)
			callAll.append(call)
			return call.id
		case .answer(from: let incomingUser):
			let index = callAll.firstIndex {
				$0.incomingUser == incomingUser ||
					$0.outgoingUser == incomingUser
			}

			status  = usersAll.count < 2 ? .ended(reason: .error) : .talk
			callAll[index ?? 0].status = status
			
			if status != .ended(reason: .error) {
				return callAll.first?.id
			} else {
				return nil
			}
		case .end(from: let user):
			let index = callAll.firstIndex {
				$0.incomingUser == user ||
					$0.outgoingUser == user
			}
			guard let callIndex = index else {
				return nil
			}
			
			let callStatus = callAll[callIndex].status
			
			switch callStatus {
			case .talk:
				status = .ended(reason: .end)
			case .calling:
				status = .ended(reason: .cancel)
			default:
				break
			}
			callAll[callIndex].status = status
		}
		
		return callAll.first?.id
	}
	
	func calls() -> [Call] {
		return callAll
	}
	
	func calls(user: User) -> [Call] {
		return calls().filter {
			$0.incomingUser == user || $0.outgoingUser == user
		}
	}
	
	func call(id: CallID) -> Call? {
		return callAll.first { $0.id == id }
	}
	
	func currentCall(user: User) -> Call? {
		let calls = callAll.filter {
			($0.incomingUser == user ||
				$0.outgoingUser == user) &&
				($0.status == .talk ||
					$0.status == .calling) }
		return calls.first
	}
}
