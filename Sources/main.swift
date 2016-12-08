import PerfectLib
import PerfectHTTP
import PerfectHTTPServer

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

routes.add(method: .post, uri: "/fan/", handler: {
    request, response in
    if let bodyStr = request.postBodyString {
        if let json = (try? bodyStr.jsonDecode()) as? [String: Any] {
            print("Post json correct! ^_^")
            if let text = json["text"] as? String, let userName = json["user_name"] as? String {
                let responseString = FanWaiter.handleFanPlanWith(commandStr: text, userName: userName)
                response.appendBody(string: "{\"text\": \"\(responseString)\"}")
            } else {
                print("Data paramaters invaild!")
                response.appendBody(string: "Data invaild!")
            }
        } else {
            print("Post json invaild!")
            response.appendBody(string: "post params invaild!")
        }
    } else {
        print("No post body...")
    }
    response.completed()
})

// Add the routes to the server.
server.addRoutes(routes)

// Set a listen port of 8181
server.serverPort = 8181

do {
    // Launch the HTTP server.
    try server.start()
} catch PerfectError.networkError(let err, let msg) {
    print("Network error thrown: \(err) \(msg)")
}
