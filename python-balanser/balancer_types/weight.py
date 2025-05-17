import threading


class WeightedRoundRobin:
    def __init__(self, servers):
        self.servers = []
        self.current_weight = 0
        self.max_weight = max(s.get('weight', 1) for s in servers)
        self.lock = threading.Lock()
        
        for server in servers:
            self.servers.append({
                'server': server,
                'weight': server.get('weight', 1),
                'current_weight': 0
            })

    def get_server(self, client_ip=None):
        with self.lock:
            total = 0
            best = None
            
            for server in self.servers:
                server['current_weight'] += server['weight']
                total += server['weight']
                
                if best is None or server['current_weight'] > best['current_weight']:
                    best = server
            
            best['current_weight'] -= total
            return best['server']