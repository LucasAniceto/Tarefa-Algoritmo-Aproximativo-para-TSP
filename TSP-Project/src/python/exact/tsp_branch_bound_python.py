import time
import sys
import os
from typing import List, Tuple, Optional
import heapq
from dataclasses import dataclass
import copy

@dataclass
class Node:
    """Nó da árvore de busca Branch and Bound"""
    level: int              # Nível atual (número de cidades visitadas)
    path: List[int]         # Caminho atual
    visited: List[bool]     # Cidades visitadas
    cost: int              # Custo atual do caminho
    bound: float           # Lower bound (limite inferior)
    
    def __lt__(self, other):
        """Para ordenação no heap (prioridade)"""
        return self.bound < other.bound

class TSPBranchBound:
    """
    Implementação do algoritmo Branch and Bound para TSP
    Usa redução de matriz para calcular bounds eficientemente
    """
    
    def __init__(self, filename: str):
        self.filename = filename
        self.matrix = []
        self.n_cities = 0
        self.best_cost = float('inf')
        self.best_path = []
        self.nodes_explored = 0
        self.nodes_pruned = 0
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
    
    def calculate_bound(self, node: Node) -> float:
        """
        Calcula lower bound para um nó usando redução de matriz
        Baseado no algoritmo clássico de Branch and Bound para TSP
        """
        # Cria matriz reduzida baseada no estado atual
        temp_matrix = [row[:] for row in self.matrix]  # Copia matriz original
        
        # Marca arestas impossíveis baseadas no caminho atual
        for i in range(len(node.path) - 1):
            from_city = node.path[i]
            to_city = node.path[i + 1]
            
            # Remove linha from_city e coluna to_city
            for j in range(self.n_cities):
                temp_matrix[from_city][j] = float('inf')
                temp_matrix[j][to_city] = float('inf')
            
            # Evita subtours prematuros
            temp_matrix[to_city][from_city] = float('inf')
        
        # Se estamos quase no final, conecta de volta ao início
        if len(node.path) > 1:
            last_city = node.path[-1]
            first_city = node.path[0]
            
            # Para todas as cidades não visitadas, remove conexão de volta ao início
            for i in range(self.n_cities):
                if not node.visited[i] and i != last_city:
                    temp_matrix[i][first_city] = float('inf')
        
        # Calcula bound usando redução de matriz
        bound = node.cost
        
        # Redução por linhas
        for i in range(self.n_cities):
            if not node.visited[i] or i == node.path[-1]:
                min_row = min(temp_matrix[i])
                if min_row != float('inf'):
                    bound += min_row
                    for j in range(self.n_cities):
                        if temp_matrix[i][j] != float('inf'):
                            temp_matrix[i][j] -= min_row
        
        # Redução por colunas
        for j in range(self.n_cities):
            if not node.visited[j] or j == node.path[0]:
                min_col = min(temp_matrix[i][j] for i in range(self.n_cities))
                if min_col != float('inf'):
                    bound += min_col
        
        return bound
    
    def calculate_simple_bound(self, node: Node) -> float:
        """
        Calcula bound simples: custo atual + estimativa das arestas restantes
        Mais rápido mas menos preciso que a redução de matriz
        """
        bound = node.cost
        
        # Para cada cidade não visitada, adiciona menor aresta saindo dela
        for i in range(self.n_cities):
            if not node.visited[i]:
                min_edge = float('inf')
                for j in range(self.n_cities):
                    if i != j and self.matrix[i][j] < min_edge:
                        min_edge = self.matrix[i][j]
                
                if min_edge != float('inf'):
                    bound += min_edge
        
        # Adiciona custo de volta ao início (estimativa)
        if len(node.path) > 0:
            last_city = node.path[-1]
            first_city = node.path[0]
            
            # Se não estamos no final, estimamos volta ao início
            if len(node.path) < self.n_cities:
                min_return = float('inf')
                for i in range(self.n_cities):
                    if not node.visited[i] and self.matrix[i][first_city] < min_return:
                        min_return = self.matrix[i][first_city]
                
                if min_return != float('inf'):
                    bound += min_return
        
        return bound
    
    def is_complete_tour(self, node: Node) -> bool:
        """Verifica se o nó representa um tour completo"""
        return len(node.path) == self.n_cities
    
    def get_complete_tour_cost(self, node: Node) -> int:
        """Calcula custo de um tour completo (adiciona volta ao início)"""
        if not self.is_complete_tour(node):
            return float('inf')
        
        # Adiciona custo de volta ao início
        last_city = node.path[-1]
        first_city = node.path[0]
        return node.cost + self.matrix[last_city][first_city]
    
    def generate_children(self, node: Node) -> List[Node]:
        """Gera nós filhos para o nó atual"""
        children = []
        
        if len(node.path) >= self.n_cities:
            return children
        
        current_city = node.path[-1] if node.path else 0
        
        # Para cada cidade não visitada
        for next_city in range(self.n_cities):
            if not node.visited[next_city]:
                # Cria novo nó filho
                child = Node(
                    level=node.level + 1,
                    path=node.path + [next_city],
                    visited=node.visited[:],  # Copia lista
                    cost=node.cost + self.matrix[current_city][next_city],
                    bound=0  # Será calculado depois
                )
                child.visited[next_city] = True
                
                children.append(child)
        
        return children
    
    def solve(self, use_simple_bound: bool = True) -> dict:
        """
        Resolve TSP usando Branch and Bound
        
        Args:
            use_simple_bound: Se True, usa bound simples (mais rápido)
                             Se False, usa redução de matriz (mais preciso)
        """
        print(f"\n🌳 === INICIANDO BRANCH AND BOUND PYTHON ===")
        print(f"📊 Cidades: {self.n_cities}")
        print(f"🎯 Valor ótimo esperado: {self.get_optimal_value()}")
        print(f"⚡ Método de bound: {'Simples' if use_simple_bound else 'Redução de Matriz'}")
        print(f"🔍 Estratégia: Busca pelo menor bound primeiro")
        print("")
        
        start_time = time.time()
        
        # Nó raiz: começa da cidade 0
        root = Node(
            level=1,
            path=[0],
            visited=[False] * self.n_cities,
            cost=0,
            bound=0
        )
        root.visited[0] = True
        
        # Calcula bound inicial
        if use_simple_bound:
            root.bound = self.calculate_simple_bound(root)
        else:
            root.bound = self.calculate_bound(root)
        
        # Priority queue (min-heap) baseada no bound
        pq = [root]
        heapq.heapify(pq)
        
        print(f"🚀 Bound inicial: {root.bound:.2f}")
        print(f"💡 Explorando árvore de busca...")
        print("")
        
        while pq:
            # Pega nó com menor bound
            current = heapq.heappop(pq)
            self.nodes_explored += 1
            
            # Mostra progresso a cada 1000 nós
            if self.nodes_explored % 1000 == 0:
                print(f"📊 Nós explorados: {self.nodes_explored:,}, "
                      f"Podados: {self.nodes_pruned:,}, "
                      f"Melhor: {self.best_cost}, "
                      f"Bound atual: {current.bound:.1f}")
            
            # Se bound >= melhor solução, poda
            if current.bound >= self.best_cost:
                self.nodes_pruned += 1
                continue
            
            # Se chegou ao tour completo
            if self.is_complete_tour(current):
                total_cost = self.get_complete_tour_cost(current)
                
                if total_cost < self.best_cost:
                    self.best_cost = total_cost
                    self.best_path = current.path[:]
                    
                    print(f"🎯 NOVA MELHOR SOLUÇÃO: {self.best_cost} "
                          f"(nó {self.nodes_explored:,})")
                
                continue
            
            # Gera filhos
            children = self.generate_children(current)
            
            for child in children:
                # Calcula bound do filho
                if use_simple_bound:
                    child.bound = self.calculate_simple_bound(child)
                else:
                    child.bound = self.calculate_bound(child)
                
                # Se bound é promissor, adiciona à fila
                if child.bound < self.best_cost:
                    heapq.heappush(pq, child)
                else:
                    self.nodes_pruned += 1
        
        end_time = time.time()
        execution_time = end_time - start_time
        
        # Extrai valor ótimo do nome do arquivo
        optimal_value = self.get_optimal_value()
        
        result = {
            'algorithm': 'BRANCH_BOUND_PYTHON',
            'filename': self.filename,
            'n_cities': self.n_cities,
            'best_path': self.best_path,
            'best_cost': self.best_cost,
            'execution_time': execution_time,
            'nodes_explored': self.nodes_explored,
            'nodes_pruned': self.nodes_pruned,
            'total_nodes': self.nodes_explored + self.nodes_pruned,
            'pruning_rate': (self.nodes_pruned / (self.nodes_explored + self.nodes_pruned)) * 100,
            'optimal_value': optimal_value,
            'is_optimal': self.best_cost == optimal_value if optimal_value > 0 else None,
            'bound_method': 'simple' if use_simple_bound else 'matrix_reduction'
        }
        
        return result
    
    def get_optimal_value(self) -> int:
        """Extrai valor ótimo do nome do arquivo"""
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
        """Imprime resultados formatados"""
        print(f"\n🏆 === RESULTADOS BRANCH AND BOUND PYTHON ===")
        print(f"📁 Arquivo: {result['filename']}")
        print(f"🌆 Número de cidades: {result['n_cities']}")
        print(f"💰 Melhor custo encontrado: {result['best_cost']}")
        print(f"⏱️  Tempo de execução: {result['execution_time']:.6f} segundos")
        print(f"🔍 Nós explorados: {result['nodes_explored']:,}")
        print(f"✂️  Nós podados: {result['nodes_pruned']:,}")
        print(f"📊 Total de nós: {result['total_nodes']:,}")
        print(f"📈 Taxa de poda: {result['pruning_rate']:.1f}%")
        print(f"⚡ Método bound: {result['bound_method']}")
        
        if result['best_path']:
            path_str = ' → '.join(map(str, result['best_path']))
            print(f"🛤️  Melhor caminho: {path_str} → {result['best_path'][0]}")
        
        if result['optimal_value'] > 0:
            print(f"🎯 Valor ótimo esperado: {result['optimal_value']}")
            if result['is_optimal']:
                print("✅ PERFEITO! Solução ótima encontrada!")
            else:
                ratio = result['best_cost'] / result['optimal_value']
                print(f"📈 Razão: {ratio:.6f}")
        
        # Comparação com força bruta
        import math
        factorial_ops = math.factorial(result['n_cities'] - 1)
        speedup = factorial_ops / result['total_nodes']
        print(f"🚀 Speedup vs Força Bruta: {speedup:.1f}x menos nós")
    
    def save_results(self, result: dict, output_file: str = "results/branch_bound_results.txt"):
        """Salva resultados em arquivo CSV"""
        os.makedirs(os.path.dirname(output_file), exist_ok=True)
        
        try:
            with open(output_file, 'a') as f:
                f.write(f"{result['filename']},{result['n_cities']},{result['best_cost']},"
                       f"{result['execution_time']:.6f},{result['algorithm']},"
                       f"{result['optimal_value']},{result['nodes_explored']},"
                       f"{result['nodes_pruned']},{result['pruning_rate']:.1f}\n")
        except Exception as e:
            print(f"Erro ao salvar resultados: {e}")

def main():
    """Função principal para teste isolado"""
    if len(sys.argv) < 2:
        print("Uso: python branch_bound_python.py <arquivo_tsp> [bound_method]")
        print("bound_method: 'simple' (padrão) ou 'matrix' para redução de matriz")
        sys.exit(1)
    
    filename = sys.argv[1]
    bound_method = sys.argv[2] if len(sys.argv) > 2 else 'simple'
    use_simple_bound = bound_method.lower() != 'matrix'
    
    try:
        solver = TSPBranchBound(filename)
        result = solver.solve(use_simple_bound=use_simple_bound)
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
