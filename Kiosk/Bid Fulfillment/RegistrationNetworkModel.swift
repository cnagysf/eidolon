import UIKit

class RegistrationNetworkModel: NSObject {
    
    dynamic var createNewUser = false
    dynamic var details:BidDetails!

    var fulfilmentNav:FulfillmentNavigationController!

    let completedSignal = RACSubject()
    
    func start() {
        var signal = RACSignal.empty()
        signal = signal.then { [weak self] (_) in
            
            self?.createOrUpdateUser()
            
        }.then { [weak self] (_) in
            self?.updateProviderIfNewUser()

        }.then{ [weak self] (_) in
            self?.addCardToUser()

        }.then{ [weak self] (_) in
            self?.registerToAuction()
        }

        signal.catchTo(RACSignal.empty()).subscribeCompleted { [weak self] (_) in

        }

        signal.subscribeCompleted { [weak self] (_) in
            self?.completedSignal.sendNext(nil)
            self?.completedSignal.sendCompleted()
        }
    }

    func provider() -> ReactiveMoyaProvider<ArtsyAPI>  {
        if let provider = fulfilmentNav.loggedInProvider {
            return provider
        }
        return Provider.DefaultProvider()
    }

    func createOrUpdateUser() -> RACSignal {
        let newUser = details.newUser
        if createNewUser {
            
            let endpoint: ArtsyAPI = ArtsyAPI.CreateUser(email: newUser.email!, password: newUser.email!, phone: newUser.phoneNumber!, postCode: newUser.zipCode!)
            return XAppRequest(endpoint, provider: provider(), method: .POST, parameters: Moya.DefaultParameters(), defaults: NSUserDefaults.standardUserDefaults()).doError() { (error) -> Void in
                println("Error creating user: \(error.localizedDescription)")
            }
            
        } else {

            let endpoint: ArtsyAPI = ArtsyAPI.UpdateMe(email: newUser.email!, phone: newUser.email!, postCode: newUser.zipCode!)

            return provider().request(endpoint, method: .PUT).doError() { (error) -> Void in
                println("Error logging in: \(error.localizedDescription)")
            }
        }
    }

    func addCardToUser() -> RACSignal {
        let endpoint: ArtsyAPI = ArtsyAPI.RegisterCard(balancedToken: details.newUser.creditCardToken!)

        return provider().request(endpoint, method: .POST).doError() { (error) -> Void in
            println("Error ading card: \(error.localizedDescription)")
        }
    }

    func registerToAuction() -> RACSignal {
        let endpoint: ArtsyAPI = ArtsyAPI.RegisterToBid(auctionID: fulfilmentNav.auctionID)
        return provider().request(endpoint, method: .POST).doError() { (error) -> Void in
            println("Error registring for auction: \(error.localizedDescription)")
        }
    }

    func updateProviderIfNewUser() -> RACSignal {
        if self.createNewUser == true {

            let endpoint: ArtsyAPI = ArtsyAPI.XAuth(email: details.newUser.email!, password: details.newUser.password!)

            return provider().request(endpoint, method:.GET, parameters: endpoint.defaultParameters).filterSuccessfulStatusCodes().mapJSON().doNext({ [weak self] (accessTokenDict) -> Void in

                if let accessToken = accessTokenDict["access_token"] as? String {
                    self?.fulfilmentNav.loggedInProvider = self?.createEndpointWithAccessToken(accessToken)
                }

            }).doError() { (error) -> Void in
                println("Error logging in: \(error.localizedDescription)")
            }

        } else {
            return RACSignal.empty()
        }
    }

    func createEndpointWithAccessToken(token: NSString) -> ReactiveMoyaProvider<ArtsyAPI> {

        let newEndpointsClosure = { (target: ArtsyAPI, method: Moya.Method, parameters: [String: AnyObject]) -> Endpoint<ArtsyAPI> in
            var endpoint: Endpoint<ArtsyAPI> = Endpoint<ArtsyAPI>(URL: url(target), sampleResponse: .Success(200, target.sampleData), method: method, parameters: parameters)

            return endpoint.endpointByAddingHTTPHeaderFields(["X-Access-Token": token])
        }

        return ReactiveMoyaProvider(endpointsClosure: newEndpointsClosure, stubResponses: APIKeys.sharedKeys.stubResponses)
    }

}
