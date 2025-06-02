import time
import sys
import os
from typing import List, Tuple, Optional
import heapq
from collections import defaultdict

class TSPMSTApproximation:
    
    def __init__(self, filename: str):
        self.filename = filename
        self.matrix = []
        self.n_cities = 0
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
            print(f"Erro: Arquivo {self.filename} não encontrado")
            sys.exit(1)
        except Exception as e:
            print(f"Erro ao carregar arquivo: {e}")
            sys.exit(1)
    
    # Encontra MST usando algoritmo de Prim
    def find_mst_prim(self) -> List[Tuple[int, int, int]]:
        mst_edges = []
        visited = [False] * self.n_cities
        
        min_heap = [(0, 0, -1)]
        
        total_weight = 0
        
        while min_heap and len(mst_edges) < self.n_cities - 1:
            weight, v, u = heapq.heappop(min_heap)
            
            if visited[v]:
                continue
                
            visited[v] = True
            total_weight += weight
            
            if u != -1:
                mst_edges.append((u, v, weight))
            
            for next_v in range(self.n_cities):
                if not visited[next_v]:
                    heapq.heappush(min_heap, (self.matrix[v][next_v], next_v, v))
        
        print(f"MST construída com peso total: {total_weight}")
        return mst_edges
    
    def build_adjacency_list(self, mst_edges: List[Tuple[int, int, int]]) -> defaultdict:
        adj_list = defaultdict(list)
        
        for u, v, weight in mst_edges:
            adj_list[u].append(v)
            adj_list[v].append(u)
            
        return adj_list
    
    def dfs_preorder(self, adj_list: defaultdict, start: int = 0) -> List[int]:
        visited = [False] * self.n_cities
        tour = []
        
        def dfs(vertex):
            visited[vertex] = True
            tour.append(vertex)
            
            for neighbor in adj_list[vertex]:
                if not visited[neighbor]:
                    dfs(neighbor)
        
        dfs(start)
        return tour
    
    def calculate_tour_cost(self, tour: List[int]) -> int:
        if len(tour) != self.n_cities:
            raise ValueError(f"Tour incompleto: {len(tour)} != {self.n_cities}")
            
        total_cost = 0
        for i in range(len(tour) - 1):
            total_cost += self.matrix[tour[i]][tour[i + 1]]
        
        total_cost += self.matrix[tour[-1]][tour[0]]
        
        return total_cost
    
    # Algoritmo MST - Aproximação com garantia de 2x o ótimo
    def solve(self) -> dict:
        print(f"\n=== Iniciando algoritmo MST para {self.n_cities} cidades ===")
        start_time = time.time()
        
        print("Passo 1: Construindo MST...")
        mst_edges = self.find_mst_prim()
        
        print("Passo 2: Construindo lista de adjacência...")
        adj_list = self.build_adjacency_list(mst_edges)
        
        print("Passo 3: Executando DFS preorder...")
        tour = self.dfs_preorder(adj_list)
        
        print("Passo 4: Calculando custo do tour...")
        tour_cost = self.calculate_tour_cost(tour)
        
        end_time = time.time()
        execution_time = end_time - start_time
        
        optimal_value = self.get_optimal_value()
        
        result = {
            'algorithm': 'MST_APPROXIMATION_PYTHON',
            'filename': self.filename,
            'n_cities': self.n_cities,
            'tour': tour,
            'cost': tour_cost,
            'execution_time': execution_time,
            'optimal_value': optimal_value,
            'approximation_ratio': tour_cost / optimal_value if optimal_value > 0 else None,
            'mst_edges': mst_edges
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
        print(f"\n=== RESULTADOS MST APROXIMATIVO ===")
        print(f"Arquivo: {result['filename']}")
        print(f"Número de cidades: {result['n_cities']}")
        print(f"Custo aproximado: {result['cost']}")
        print(f"Tempo de execução: {result['execution_time']:.6f} segundos")
        print(f"Tour: {' -> '.join(map(str, result['tour']))} -> {result['tour'][0]}")
        
        if result['optimal_value'] > 0:
            ratio = result['approximation_ratio']
            print(f"Valor ótimo esperado: {result['optimal_value']}")
            print(f"Razão de aproximação: {ratio:.3f}")
            print(f"Qualidade: {ratio * 100:.1f}% do ótimo")
            
            if ratio <= 2.0:
                print("✓ Garantia teórica respeitada (≤ 2x ótimo)")
            else:
                print("⚠ Razão acima da garantia teórica")
    
    def save_results(self, result: dict, output_file: str = "results/approximate_results.txt"):
        os.makedirs(os.path.dirname(output_file), exist_ok=True)
        
        try:
            with open(output_file, 'a') as f:
                f.write(f"{result['filename']},{result['n_cities']},{result['cost']},"
                       f"{result['execution_time']:.6f},{result['algorithm']},"
                       f"{result['optimal_value']},{result['approximation_ratio']:.3f}\n")
        except Exception as e:
            print(f"Erro ao salvar resultados: {e}")
            try:
                alt_path = "../../results/approximate_results.txt"
                os.makedirs(os.path.dirname(alt_path), exist_ok=True)
                with open(alt_path, 'a') as f:
                    f.write(f"{result['filename']},{result['n_cities']},{result['cost']},"
                           f"{result['execution_time']:.6f},{result['algorithm']},"
                           f"{result['optimal_value']},{result['approximation_ratio']:.3f}\n")
                print(f"Salvo em path alternativo: {alt_path}")
            except Exception as e2:
                print(f"Erro também no path alternativo: {e2}")

def main():
    if len(sys.argv) != 2:
        print("Uso: python mst_algorithm.py <arquivo_tsp>")
        sys.exit(1)
    
    filename = sys.argv[1]
    
    try:
        solver = TSPMSTApproximation(filename)
        result = solver.solve()
        solver.print_results(result)
        solver.save_results(result)
        
    except Exception as e:
        print(f"Erro durante execução: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()
    
    def build_adjacency_list(self, mst_edges: List[Tuple[int, int, int]]) -> defaultdict:
        adj_list = defaultdict(list)
        
        for u, v, weight in mst_edges:
            adj_list[u].append(v)
            adj_list[v].append(u)
            
        return adj_list
    
    def dfs_preorder(self, adj_list: defaultdict, start: int = 0) -> List[int]:
        visited = [False] * self.n_cities
        tour = []
        
        def dfs(vertex):
            visited[vertex] = True
            tour.append(vertex)
            
            for neighbor in adj_list[vertex]:
                if not visited[neighbor]:
                    dfs(neighbor)
        
        dfs(start)
        return tour
    
    def calculate_tour_cost(self, tour: List[int]) -> int:
        if len(tour) != self.n_cities:
            raise ValueError(f"Tour incompleto: {len(tour)} != {self.n_cities}")
            
        total_cost = 0
        for i in range(len(tour) - 1):
            total_cost += self.matrix[tour[i]][tour[i + 1]]
        
        total_cost += self.matrix[tour[-1]][tour[0]]
        
        return total_cost
    
    def solve(self) -> dict:
        print(f"\n=== Iniciando algoritmo MST para {self.n_cities} cidades ===")
        start_time = time.time()
        
        print("Passo 1: Construindo MST...")
        mst_edges = self.find_mst_prim()
        
        print("Passo 2: Construindo lista de adjacência...")
        adj_list = self.build_adjacency_list(mst_edges)
        
        print("Passo 3: Executando DFS preorder...")
        tour = self.dfs_preorder(adj_list)
        
        print("Passo 4: Calculando custo do tour...")
        tour_cost = self.calculate_tour_cost(tour)
        
        end_time = time.time()
        execution_time = end_time - start_time
        
        optimal_value = self.get_optimal_value()
        
        result = {
            'algorithm': 'MST_APPROXIMATION_PYTHON',
            'filename': self.filename,
            'n_cities': self.n_cities,
            'tour': tour,
            'cost': tour_cost,
            'execution_time': execution_time,
            'optimal_value': optimal_value,
            'approximation_ratio': tour_cost / optimal_value if optimal_value > 0 else None,
            'mst_edges': mst_edges
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
        print(f"\n=== RESULTADOS MST APROXIMATIVO ===")
        print(f"Arquivo: {result['filename']}")
        print(f"Número de cidades: {result['n_cities']}")
        print(f"Custo aproximado: {result['cost']}")
        print(f"Tempo de execução: {result['execution_time']:.6f} segundos")
        print(f"Tour: {' -> '.join(map(str, result['tour']))} -> {result['tour'][0]}")
        
        if result['optimal_value'] > 0:
            ratio = result['approximation_ratio']
            print(f"Valor ótimo esperado: {result['optimal_value']}")
            print(f"Razão de aproximação: {ratio:.3f}")
            print(f"Qualidade: {ratio * 100:.1f}% do ótimo")
            
            if ratio <= 2.0:
                print("✓ Garantia teórica respeitada (≤ 2x ótimo)")
            else:
                print("⚠ Razão acima da garantia teórica")
    
    def save_results(self, result: dict, output_file: str = "results/approximate_results.txt"):
        os.makedirs(os.path.dirname(output_file), exist_ok=True)
        
        try:
            with open(output_file, 'a') as f:
                f.write(f"{result['filename']},{result['n_cities']},{result['cost']},"
                       f"{result['execution_time']:.6f},{result['algorithm']},"
                       f"{result['optimal_value']},{result['approximation_ratio']:.3f}\n")
        except Exception as e:
            print(f"Erro ao salvar resultados: {e}")
            try:
                alt_path = "../../results/approximate_results.txt"
                os.makedirs(os.path.dirname(alt_path), exist_ok=True)
                with open(alt_path, 'a') as f:
                    f.write(f"{result['filename']},{result['n_cities']},{result['cost']},"
                           f"{result['execution_time']:.6f},{result['algorithm']},"
                           f"{result['optimal_value']},{result['approximation_ratio']:.3f}\n")
                print(f"Salvo em path alternativo: {alt_path}")
            except Exception as e2:
                print(f"Erro também no path alternativo: {e2}")

def main():
    if len(sys.argv) != 2:
        print("Uso: python mst_algorithm.py <arquivo_tsp>")
        sys.exit(1)
    
    filename = sys.argv[1]
    
    try:
        solver = TSPMSTApproximation(filename)
        result = solver.solve()
        solver.print_results(result)
        solver.save_results(result)
        
    except Exception as e:
        print(f"Erro durante execução: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()