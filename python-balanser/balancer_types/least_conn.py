import threading


class LeastConnections:
    def __init__(self, servers):
        self.servers = servers
        self.connection_counts = {server['host']: 0 for server in servers}
        self.lock = threading.Lock()

    def get_server(self, client_ip=None):
        with self.lock:
            server = min(self.servers, key=lambda s: self.connection_counts[s['host']])
            self.connection_counts[server['host']] += 1
            return server

    def release_server(self, server_host):
        with self.lock:
            self.connection_counts[server_host] -= 1