import time
import sys
import os
from typing import List, Optional, Tuple
import copy

class TSPNode:
    
    def __init__(self, n_cities: int):
        self.path = [0] * n_cities
        self.visited = [False] * n_cities
        self.current_cost = 0
        self.level = 0
        self.bound = 0

class TSPBranchBound:
    
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
    
    # Calcula lower bound usando redução de matriz
    def calculate_bound(self, node: TSPNode) -> int:
        bound = node.current_cost
        
        for i in range(self.n_cities):
            if not node.visited[i] or (node.level > 0 and i == node.path[node.level - 1]):
                min_edge = float('inf')
                for j in range(self.n_cities):
                    if i != j and (not node.visited[j] or j == 0):
                        if self.matrix[i][j] < min_edge:
                            min_edge = self.matrix[i][j]
                
                if min_edge != float('inf'):
                    bound += min_edge
        
        return bound
    
    # Função recursiva do Branch and Bound
    def branch_and_bound_recursive(self, current_node: TSPNode):
        self.nodes_explored += 1
        
        if current_node.level == self.n_cities:
            final_cost = current_node.current_cost + \
                        self.matrix[current_node.path[current_node.level - 1]][0]
            
            if final_cost < self.best_cost:
                self.best_cost = final_cost
                self.best_path = current_node.path.copy()
            return
        
        # Otimização: explora apenas cidades não visitadas (exceto cidade 0 já fixada)
        for i in range(1, self.n_cities):
            if not current_node.visited[i]:
                next_node = TSPNode(self.n_cities)
                
                next_node.path = current_node.path.copy()
                next_node.visited = current_node.visited.copy()
                
                next_node.path[current_node.level] = i
                next_node.visited[i] = True
                next_node.level = current_node.level + 1
                next_node.current_cost = current_node.current_cost + \
                                       self.matrix[current_node.path[current_node.level - 1]][i]
                
                next_node.bound = self.calculate_bound(next_node)
                
                # Poda: se bound >= melhor solução atual, não explora
                if next_node.bound < self.best_cost:
                    self.branch_and_bound_recursive(next_node)
                else:
                    self.nodes_pruned += 1
    
    # Algoritmo Branch and Bound - Otimização: fixa cidade 0 como inicial
    def solve(self) -> dict:
        print(f"Iniciando Branch and Bound para {self.n_cities} cidades...")
        start_time = time.time()
        
        root = TSPNode(self.n_cities)
        
        # Fixa cidade 0 como inicial
        root.path[0] = 0
        root.visited[0] = True
        root.current_cost = 0
        root.level = 1
        root.bound = self.calculate_bound(root)
        
        self.branch_and_bound_recursive(root)
        
        end_time = time.time()
        self.execution_time = end_time - start_time
        
        optimal_value = self.get_optimal_value()
        
        result = {
            'algorithm': 'BRANCH_BOUND_PYTHON',
            'filename': self.filename,
            'n_cities': self.n_cities,
            'best_path': self.best_path,
            'best_cost': self.best_cost,
            'execution_time': self.execution_time,
            'nodes_explored': self.nodes_explored,
            'nodes_pruned': self.nodes_pruned,
            'pruning_rate': (self.nodes_pruned / (self.nodes_explored + self.nodes_pruned)) * 100,
            'optimal_value': optimal_value,
            'is_optimal': self.best_cost == optimal_value if optimal_value > 0 else None
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
        print(f"\n=== RESULTADOS BRANCH AND BOUND ===")
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
    
    def save_results(self, result: dict, output_file: str = "results/exact_results.txt"):
        os.makedirs(os.path.dirname(output_file), exist_ok=True)
        
        try:
            with open(output_file, 'a') as f:
                f.write(f"{result['filename']},{result['n_cities']},{result['best_cost']},"
                       f"{result['execution_time']:.6f},{result['algorithm']},"
                       f"{result['nodes_explored']},{result['nodes_pruned']}\n")
        except Exception as e:
            print(f"Erro ao salvar resultados: {e}")

def main():
    if len(sys.argv) != 2:
        print("Uso: python branch_bound_python.py <arquivo_tsp>")
        sys.exit(1)
    
    filename = sys.argv[1]
    
    try:
        solver = TSPBranchBound(filename)
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