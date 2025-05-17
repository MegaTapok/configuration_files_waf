SERVER_POOL = [
    {"host": "192.168.31.139", "port": 80, "weight": 1},
    {"host": "192.168.31.202", "port": 80, "weight": 2}
]

HEALTH_CHECK_INTERVAL = 30  # seconds
LISTEN_PORT = 8080
ALGORITHM = "least_connections"  # or "round_robin", "weighted"