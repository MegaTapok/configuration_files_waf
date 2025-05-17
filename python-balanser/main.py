import threading
from http.server import BaseHTTPRequestHandler, HTTPServer
import requests
from balancer_types.init import Init
from config import *

class LoadBalancer:
    def __init__(self):
        self.algorithm = Init.get_algorithm(ALGORITHM, SERVER_POOL)
        self.health_check_timer = threading.Timer(HEALTH_CHECK_INTERVAL, self.health_check)
        self.health_check_timer.daemon = True
        self.health_check_timer.start()

    def health_check(self):
        pass

    def process_request(self, handler):
        client_ip = handler.client_address[0]
        try:
            server = self.algorithm.get_server(client_ip)
            response = self.forward_request(handler, server)
            self.send_response(handler, response)
        except Exception as e:
            handler.send_error(502, f"Bad Gateway: {str(e)}")

    def forward_request(self, handler, server):
        url = f"http://{server['host']}:{server['port']}{handler.path}"
        
        headers = {k: v for k, v in handler.headers.items() 
                  if k.lower() not in ['host', 'content-length']}
        
        return requests.request(
            method=handler.command,
            url=url,
            headers=headers,
            data=handler.rfile.read(int(handler.headers.get('Content-Length', 0))),
            allow_redirects=False,
            timeout=5
        )

    def send_response(self, handler, response):
        handler.send_response(response.status_code)
        for key, value in response.headers.items():
            if key.lower() not in ['transfer-encoding', 'connection', 'content-encoding']:
                handler.send_header(key, value)
        handler.end_headers()
        handler.wfile.write(response.content)

class Handler(BaseHTTPRequestHandler):
    def __init__(self, lb, *args, **kwargs):
        self.lb = lb
        super().__init__(*args, **kwargs)

    def do_GET(self):
        self.lb.process_request(self)

    def do_POST(self):
        self.lb.process_request(self)

def run():
    lb = LoadBalancer()
    server = HTTPServer(('0.0.0.0', LISTEN_PORT), 
                       lambda *args, **kwargs: Handler(lb, *args, **kwargs))
    print(f"Load balancer running on port {LISTEN_PORT} with {ALGORITHM} algorithm")
    server.serve_forever()

if __name__ == "__main__":
    run()