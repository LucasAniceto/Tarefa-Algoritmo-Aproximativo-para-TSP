import time
import sys
import os
import math
from typing import List, Optional

class TSPNodeUnoptimized:
    
    def __init__(self, n_cities: int):
        self.path = [0] * n_cities
        self.visited = [False] * n_cities
        self.current_cost = 0
        self.level = 0
        self.bound = 0

class TSPBranchBoundUnoptimized:
    
    def __init__(self, filename: str):
        self.filename = filename
        self.matrix = []
        self.n_cities = 0
        self.best_path = []
        self.best_cost = float('inf')
        self.execution_time = 0.0
        self.nodes_explored = 0
        self.nodes_pruned = 0
        self.load_tsp_file()
        
    def load_tsp_file(self):
        try:
            with open(self.filename, 'r') as file:
                lines = file.readlines()
                
            lines = [line.strip() for line in lines if line.strip()]
            first_row = list(map(int, lines[0].split()))
            self.n_cities = len(first_row)
            
            self.matrix = []
            for line in lines:
                row = list(map(int, line.split()))
                if len(row) == self.n_cities:
                    self.matrix.append(row)
                    
            if len(self.matrix) != self.n_cities:
                raise ValueError(f"Matriz inconsistente: esperado {self.n_cities}x{self.n_cities}")
                
            print(f"Arquivo carregado: {self.n_cities} cidades")
            
        except FileNotFoundError:
            print(f"Erro ao abrir arquivo {self.filename}")
            sys.exit(1)
        except Exception as e:
            print(f"Erro ao carregar arquivo: {e}")
            sys.exit(1)
    
    # Lower bound SEM OTIMIZAÇÕES SOFISTICADAS
    def calculate_bound_unoptimized(self, node: TSPNodeUnoptimized) -> float:
        bound = node.current_cost
        
        for i in range(self.n_cities):
            if not node.visited[i]:
                min_edge = float('inf')
                for j in range(self.n_cities):
                    if i != j and self.matrix[i][j] < min_edge:
                        min_edge = self.matrix[i][j]
                
                if min_edge != float('inf'):
                    bound += min_edge
        
        return bound
    
    # Função que explora TODAS as permutações (N!)
    def branch_and_bound_recursive_full(self, current_node: TSPNodeUnoptimized):
        self.nodes_explored += 1
        
        if self.nodes_explored % 100000 == 0:
            pruning_rate = (self.nodes_pruned / (self.nodes_explored + self.nodes_pruned)) * 100
            print(f"Progresso: {self.nodes_explored:,} nós explorados, "
                  f"{self.nodes_pruned:,} podados ({pruning_rate:.2f}% poda)")
        
        if current_node.level == self.n_cities:
            final_cost = current_node.current_cost + \
                        self.matrix[current_node.path[current_node.level - 1]][current_node.path[0]]
            
            if final_cost < self.best_cost:
                self.best_cost = final_cost
                self.best_path = current_node.path.copy()
                print(f"Nova melhor solução: {self.best_cost} (nó {self.nodes_explored:,})")
            return
        
        # SEM OTIMIZAÇÃO: explora TODAS as cidades (0 até n-1)
        for i in range(self.n_cities):
            if not current_node.visited[i]:
                next_node = TSPNodeUnoptimized(self.n_cities)
                
                next_node.path = current_node.path.copy()
                next_node.visited = current_node.visited.copy()
                
                next_node.path[current_node.level] = i
                next_node.visited[i] = True
                next_node.level = current_node.level + 1
                
                if current_node.level == 0:
                    next_node.current_cost = 0
                else:
                    next_node.current_cost = current_node.current_cost + \
                                           self.matrix[current_node.path[current_node.level - 1]][i]
                
                next_node.bound = self.calculate_bound_unoptimized(next_node)
                
                if next_node.bound < self.best_cost:
                    self.branch_and_bound_recursive_full(next_node)
                else:
                    self.nodes_pruned += 1
    
    # Algoritmo principal que usa N! permutações
    def solve(self) -> dict:
        print("=== INICIANDO BRANCH AND BOUND N! (SEM OTIMIZAÇÃO) ===")
        print(f"Número de cidades: {self.n_cities}")
        
        factorial_full = math.factorial(self.n_cities)
        factorial_optimized = math.factorial(self.n_cities - 1)
        
        print(f"Permutações teóricas a explorar: {factorial_full:,} ({self.n_cities}!)")
        print(f"Versão otimizada exploraria: {factorial_optimized:,} ({self.n_cities-1}!)")
        print(f"Esta versão explora {factorial_full / factorial_optimized:.1f}x mais possibilidades!")
        
        if self.n_cities > 10:
            print(f"\n⚠️  AVISO: {self.n_cities} cidades com {self.n_cities}! pode demorar MUITO!")
            print("⚠️  Recomenda-se usar timeout ou a versão otimizada.")
            response = input("Continuar mesmo assim? (s/n): ").lower()
            if response not in ['s', 'sim', 'y', 'yes']:
                print("Execução cancelada.")
                sys.exit(0)
        
        print("\nIniciando busca...")
        start_time = time.time()
        
        # Inicializa nó raiz VAZIO (sem fixar cidade)
        root = TSPNodeUnoptimized(self.n_cities)
        
        for i in range(self.n_cities):
            root.visited[i] = False
        
        root.current_cost = 0
        root.level = 0
        root.bound = self.calculate_bound_unoptimized(root)
        
        self.branch_and_bound_recursive_full(root)
        
        end_time = time.time()
        self.execution_time = end_time - start_time
        
        optimal_value = self.get_optimal_value()
        
        result = {
            'algorithm': 'BRANCH_BOUND_N_FACTORIAL_PYTHON',
            'filename': self.filename,
            'n_cities': self.n_cities,
            'best_path': self.best_path,
            'best_cost': self.best_cost,
            'execution_time': self.execution_time,
            'nodes_explored': self.nodes_explored,
            'nodes_pruned': self.nodes_pruned,
            'pruning_rate': (self.nodes_pruned / (self.nodes_explored + self.nodes_pruned)) * 100,
            'optimal_value': optimal_value,
            'is_optimal': self.best_cost == optimal_value if optimal_value > 0 else None,
            'factorial_full': math.factorial(self.n_cities),
            'factorial_optimized': math.factorial(self.n_cities - 1),
            'overhead_factor': math.factorial(self.n_cities) / math.factorial(self.n_cities - 1)
        }
        
        return result
    
    def get_optimal_value(self) -> int:
        try:
            filename = self.filename.split('/')[-1]
            if '_' in filename and '.' in filename:
                underscore_pos = filename.rfind('_')
                dot_pos = filename.rfind('.')
                if underscore_pos < dot_pos:
                    return int(filename[underscore_pos + 1:dot_pos])
        except:
            pass
        return -1
    
    def print_results(self, result: dict):
        print(f"\n=== RESULTADOS BRANCH AND BOUND N! (SEM OTIMIZAÇÃO) ===")
        print(f"Arquivo: {result['filename']}")
        print(f"Número de cidades: {result['n_cities']}")
        print(f"Melhor custo encontrado: {result['best_cost']}")
        print(f"Tempo de execução: {result['execution_time']:.6f} segundos")
        print(f"Nós explorados: {result['nodes_explored']:,}")
        print(f"Nós podados: {result['nodes_pruned']:,}")
        print(f"Taxa de poda: {result['pruning_rate']:.2f}%")
        print(f"Melhor caminho: {' -> '.join(map(str, result['best_path']))}")
        
        if result['optimal_value'] > 0:
            print(f"Valor ótimo esperado: {result['optimal_value']}")
            if result['is_optimal']:
                print("✅ Solução ótima encontrada!")
            else:
                ratio = result['best_cost'] / result['optimal_value']
                print(f"⚠️ Razão: {ratio:.3f}")
        
        print(f"\n=== COMPARAÇÃO COM VERSÃO OTIMIZADA ===")
        print(f"Nós explorados nesta versão (n!): {result['nodes_explored']:,}")
        print(f"Fatorial teórico completo ({result['n_cities']}!): {result['factorial_full']:,}")
        print(f"Fatorial otimizado ({result['n_cities']-1}!): {result['factorial_optimized']:,}")
        print(f"Overhead teórico: {result['overhead_factor']:.1f}x mais operações")
        print(f"Eficiência da poda: {100 - (result['nodes_explored'] / result['factorial_full']) * 100:.1f}%")
    
    def save_results(self, result: dict, output_file: str = "results/exact_results_n_factorial.txt"):
        os.makedirs(os.path.dirname(output_file), exist_ok=True)
        
        try:
            with open(output_file, 'a') as f:
                f.write(f"{result['filename']},{result['n_cities']},{result['best_cost']},"
                       f"{result['execution_time']:.6f},{result['algorithm']},"
                       f"{result['nodes_explored']},{result['nodes_pruned']},{result['overhead_factor']:.1f}\n")
        except Exception as e:
            print(f"Erro ao salvar resultados: {e}")

def main():
    if len(sys.argv) != 2:
        print("Uso: python branch_bound_unoptimized.py <arquivo_tsp>")
        print("AVISO: Esta versão usa n! permutações (sem otimização de cidade fixa)")
        sys.exit(1)
    
    filename = sys.argv[1]
    
    try:
        solver = TSPBranchBoundUnoptimized(filename)
        result = solver.solve()
        solver.print_results(result)
        solver.save_results(result)
        
    except KeyboardInterrupt:
        print("\n⚠️ Execução interrompida pelo usuário")
    except Exception as e:
        print(f"Erro durante execução: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()