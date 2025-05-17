import threading

class RoundRobin:
    def __init__(self, servers):
        self.servers = servers
        self.index = 0
        self.lock = threading.Lock()

    def get_server(self, client_ip=None):
        with self.lock:
            server = self.servers[self.index]
            self.index = (self.index + 1) % len(self.servers)
            return server