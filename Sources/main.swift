import Foundation
import PerfectLib
import PerfectHTTP
import PerfectHTTPServer
import PerfectCURL

// Create HTTP server.
let server = HTTPServer()

// Register your own routes and handlers
var routes = Routes()
routes.add(method: .get, uri: "/", handler: {
    request, response in
    response.setHeader(.contentType, value: "text/html")
    response.appendBody(string: "<html><title>Hello, world!</title><body>Hello, world!</body></html>")
    response.completed()
}
)

routes.add(method: .get, uri: "/today/", handler: {
    request, response in
    //response.setHeader(.contentType, value: "text/html")
    if let planManager = PlanManager() {
        let eaters = planManager.getTodayEaters()
        response.appendBody(string: eaters.joined(separator: ","))
    } else {
        response.appendBody(string: "")
    }
    response.completed()
}
)

routes.add(method: .post, uri: "/fan/", handler: {
    request, response in
    if let bodyStr = request.postBodyString {
        print("body: \(bodyStr)")
        if let json = (try? bodyStr.jsonDecode()) as? [String: Any] {
            if let text = json["text"] as? String, let userName = json["user_name"] as? String {
                let responseString = FanWaiter.handleFanPlanWith(commandStr: text.trim(), userName: userName)
                response.appendBody(string: "{\"text\": \"\(responseString)\"}")
            } else {
                response.appendBody(string: "Data invaild!")
            }
        } else {
            response.appendBody(string: "post params invaild!")
        }
    } else {
        print("No post body...")
    }
    response.completed()
})

// Add the routes to the server.
server.addRoutes(routes)

// Set a listen port
server.serverPort = 12322

// Timer for dailyReport
//let timer = Timer.init(
//    fire: Date(),
//    interval: 3,
//    repeats: true,
//    block: {
//        timer in
//        let str = FanWaiter.dailyReport()
//        let curlObject = CURL(url: "127.0.0.1:12322")
//        curlObject.perform {
//            code, header, body in
//            print(code)
//            print(header)
//            print(body)
//        }
//})
//let timer = Timer.

do {
    // Launch the HTTP server.
    try server.start()
} catch PerfectError.networkError(let err, let msg) {
    print("Network error thrown: \(err) \(msg)")
}
