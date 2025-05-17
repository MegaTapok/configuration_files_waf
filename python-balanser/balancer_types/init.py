from .round import RoundRobin
from .least_conn import LeastConnections
from .weight import WeightedRoundRobin

ALGORITHMS = {
        "round_robin": RoundRobin,
        "least_connections": LeastConnections,
        "weighted": WeightedRoundRobin
    }

class Init:

    def get_algorithm(algorithm_name, servers):
        if algorithm_name not in ALGORITHMS:
            raise ValueError(f"Unknown algorithm: {algorithm_name}")
        return ALGORITHMS[algorithm_name](servers)