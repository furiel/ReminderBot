(import [http.server [HTTPServer SimpleHTTPRequestHandler HTTPStatus]])
(import ssl collections threading)

; openssl req -new -x509 -keyout testpemfile.pem -out yourpemfile.pem -days 365 -nodes

(defclass HttpServerSimulator [object]
  (defn --init-- [self]
    (setv
      self.httpd (HTTPServer (, "localhost" 5555) HttpRequestHandlerSimulator)
      self.httpd.socket (ssl.wrap-socket self.httpd.socket :server-side True :certfile "tests/testdata/testpemfile.pem")
      self.httpd.testdata (collections.deque)
      self.httpserver (threading.Thread :target self.httpd.serve_forever)))

  (defn feed-data [self str]
    (self.httpd.testdata.append str))

  (defn start [self]
    (self.httpserver.start))

  (defn stop [self]
    (self.httpd.shutdown)
    (self.httpserver.join)))

(defclass HttpRequestHandlerSimulator [SimpleHTTPRequestHandler]
  (defn do_GET [self]
    (self.send_response 200)

    (self.send_header "Content-type" "application/json")
    (self.end_headers)

    (setv response (self.server.testdata.popleft))
    (self.wfile.write (bytes response "utf8"))))
