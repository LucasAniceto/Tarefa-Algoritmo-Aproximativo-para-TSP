import time
import sys
import os
from typing import List, Tuple, Optional
import heapq
from collections import defaultdict

class TSPMSTApproximation:
    """
    Implementação do algoritmo de aproximação MST para TSP
    Algoritmo da Árvore - garante solução no máximo 2x o ótimo
    """
    
    def __init__(self, filename: str):
        self.filename = filename
        self.matrix = []
        self.n_cities = 0
        self.load_tsp_file()
        
    def load_tsp_file(self):
        """Carrega arquivo TSP e constrói matriz de adjacência"""
        try:
            with open(self.filename, 'r') as file:
                lines = file.readlines()
                
            # Remove linhas vazias e espaços
            lines = [line.strip() for line in lines if line.strip()]
            
            # Primeira linha determina número de cidades
            first_row = list(map(int, lines[0].split()))
            self.n_cities = len(first_row)
            
            # Inicializa matriz
            self.matrix = []
            
            # Preenche matriz
            for line in lines:
                row = list(map(int, line.split()))
                if len(row) == self.n_cities:  # Verifica consistência
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
    
    def find_mst_prim(self) -> List[Tuple[int, int, int]]:
        """
        Encontra MST usando algoritmo de Prim
        Retorna lista de arestas (u, v, peso)
        """
        mst_edges = []
        visited = [False] * self.n_cities
        
        # Min-heap: (peso, vértice_destino, vértice_origem)
        min_heap = [(0, 0, -1)]  # Começa do vértice 0
        
        total_weight = 0
        
        while min_heap and len(mst_edges) < self.n_cities - 1:
            weight, v, u = heapq.heappop(min_heap)
            
            if visited[v]:
                continue
                
            visited[v] = True
            total_weight += weight
            
            if u != -1:  # Não é o vértice inicial
                mst_edges.append((u, v, weight))
            
            # Adiciona arestas adjacentes ao heap
            for next_v in range(self.n_cities):
                if not visited[next_v]:
                    heapq.heappush(min_heap, (self.matrix[v][next_v], next_v, v))
        
        print(f"MST construída com peso total: {total_weight}")
        return mst_edges
    
    def build_adjacency_list(self, mst_edges: List[Tuple[int, int, int]]) -> defaultdict:
        """Constrói lista de adjacência da MST"""
        adj_list = defaultdict(list)
        
        for u, v, weight in mst_edges:
            adj_list[u].append(v)
            adj_list[v].append(u)
            
        return adj_list
    
    def dfs_preorder(self, adj_list: defaultdict, start: int = 0) -> List[int]:
        """
        Faz DFS preorder na MST para obter tour aproximado
        """
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
        """Calcula custo total do tour"""
        if len(tour) != self.n_cities:
            raise ValueError(f"Tour incompleto: {len(tour)} != {self.n_cities}")
            
        total_cost = 0
        for i in range(len(tour) - 1):
            total_cost += self.matrix[tour[i]][tour[i + 1]]
        
        # Retorna ao início
        total_cost += self.matrix[tour[-1]][tour[0]]
        
        return total_cost
    
    def solve(self) -> dict:
        """
        Resolve TSP usando algoritmo MST
        Retorna dicionário com resultados
        """
        print(f"\n=== Iniciando algoritmo MST para {self.n_cities} cidades ===")
        start_time = time.time()
        
        # 1. Encontra MST
        print("Passo 1: Construindo MST...")
        mst_edges = self.find_mst_prim()
        
        # 2. Constrói lista de adjacência
        print("Passo 2: Construindo lista de adjacência...")
        adj_list = self.build_adjacency_list(mst_edges)
        
        # 3. Faz DFS preorder
        print("Passo 3: Executando DFS preorder...")
        tour = self.dfs_preorder(adj_list)
        
        # 4. Calcula custo
        print("Passo 4: Calculando custo do tour...")
        tour_cost = self.calculate_tour_cost(tour)
        
        end_time = time.time()
        execution_time = end_time - start_time
        
        # Extrai valor ótimo do nome do arquivo
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
        """Extrai valor ótimo do nome do arquivo"""
        try:
            filename = self.filename.split('/')[-1]  # Pega apenas o nome do arquivo
            if '_' in filename and '.' in filename:
                underscore_pos = filename.rfind('_')
                dot_pos = filename.rfind('.')
                if underscore_pos < dot_pos:
                    return int(filename[underscore_pos + 1:dot_pos])
        except:
            pass
        return -1
    
    def print_results(self, result: dict):
        """Imprime resultados formatados"""
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
        """Salva resultados em arquivo CSV"""
        # Garantir que diretório existe
        os.makedirs(os.path.dirname(output_file), exist_ok=True)
        
        try:
            with open(output_file, 'a') as f:
                f.write(f"{result['filename']},{result['n_cities']},{result['cost']},"
                       f"{result['execution_time']:.6f},{result['algorithm']},"
                       f"{result['optimal_value']},{result['approximation_ratio']:.3f}\n")
        except Exception as e:
            print(f"Erro ao salvar resultados: {e}")
            # Tentar path alternativo
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
    """Função principal para teste isolado"""
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
