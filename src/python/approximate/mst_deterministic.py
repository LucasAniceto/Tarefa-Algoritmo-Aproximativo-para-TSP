import time
import sys
import os

class TSPMSTFixed:
    """Versão super simples e corrigida do MST para TSP"""
    
    def __init__(self, filename: str):
        self.filename = filename
        self.matrix = []
        self.n_cities = 0
        self.load_tsp_file()
        
    def load_tsp_file(self):
        with open(self.filename, 'r') as file:
            lines = [line.strip() for line in file.readlines() if line.strip()]
        
        # Primeira linha determina número de cidades
        first_row = list(map(int, lines[0].split()))
        self.n_cities = len(first_row)
        
        # Preenche matriz
        self.matrix = []
        for line in lines:
            row = list(map(int, line.split()))
            if len(row) == self.n_cities:
                self.matrix.append(row)
        
        print(f"Arquivo carregado: {self.n_cities} cidades")
    
    def find_mst_simple(self):
        """MST usando Prim - versão super simples"""
        print("=== MST SIMPLES ===")
        
        # Inicialização
        in_mst = [False] * self.n_cities
        key = [float('inf')] * self.n_cities
        parent = [-1] * self.n_cities
        
        # Começa do vértice 0
        key[0] = 0
        mst_edges = []
        
        # DEVE rodar EXATAMENTE n iterações para incluir todos os vértices
        for iteration in range(self.n_cities):
            print(f"\n--- Iteração {iteration + 1} ---")
            
            # Encontra vértice com menor key que não está na MST
            min_key = float('inf')
            min_vertex = -1
            
            for v in range(self.n_cities):
                if not in_mst[v] and key[v] < min_key:
                    min_key = key[v]
                    min_vertex = v
            
            if min_vertex == -1:
                print("❌ ERRO: Não encontrou vértice válido!")
                break
            
            print(f"Vértices disponíveis: {[v for v in range(self.n_cities) if not in_mst[v]]}")
            print(f"Escolhido: vértice {min_vertex} com key {min_key}")
            
            # Adiciona à MST
            in_mst[min_vertex] = True
            
            # Adiciona aresta (exceto primeira iteração)
            if parent[min_vertex] != -1:
                mst_edges.append((parent[min_vertex], min_vertex, int(min_key)))
                print(f"  ✅ Aresta: {parent[min_vertex]} -> {min_vertex} (peso: {int(min_key)})")
            else:
                print(f"  🏁 Vértice inicial: {min_vertex}")
            
            # Atualiza keys dos vizinhos
            updates = 0
            for v in range(self.n_cities):
                if not in_mst[v] and self.matrix[min_vertex][v] < key[v]:
                    old_key = key[v]
                    key[v] = self.matrix[min_vertex][v]
                    parent[v] = min_vertex
                    print(f"    Atualiza {v}: {old_key} -> {key[v]}")
                    updates += 1
            
            if updates == 0:
                print("    Nenhuma key atualizada")
            
            # Estado atual
            mst_vertices = [v for v in range(self.n_cities) if in_mst[v]]
            remaining = [v for v in range(self.n_cities) if not in_mst[v]]
            print(f"  Na MST: {mst_vertices} ({len(mst_vertices)}/{self.n_cities})")
            print(f"  Restam: {remaining}")
            
        print(f"\n✅ MST concluída: {len(mst_edges)} arestas")
        return mst_edges
    
    def build_adjacency_from_mst(self, mst_edges):
        """Constrói lista de adjacência da MST"""
        adj_list = [[] for _ in range(self.n_cities)]
        
        for u, v, weight in mst_edges:
            adj_list[u].append(v)
            adj_list[v].append(u)
        
        # Ordena para determinismo
        for i in range(self.n_cities):
            adj_list[i].sort()
        
        return adj_list
    
    def dfs_tour(self, adj_list, start=0):
        """DFS para gerar tour"""
        visited = [False] * self.n_cities
        tour = []
        
        def dfs(v):
            visited[v] = True
            tour.append(v)
            for neighbor in adj_list[v]:
                if not visited[neighbor]:
                    dfs(neighbor)
        
        dfs(start)
        return tour
    
    def calculate_tour_cost(self, tour):
        """Calcula custo do tour"""
        if len(tour) != self.n_cities:
            print(f"❌ ERRO: Tour tem {len(tour)} cidades, deveria ter {self.n_cities}")
            print(f"Tour: {tour}")
            return -1
        
        cost = 0
        for i in range(len(tour) - 1):
            cost += self.matrix[tour[i]][tour[i + 1]]
        cost += self.matrix[tour[-1]][tour[0]]  # Volta ao início
        
        return cost
    
    def solve(self):
        """Resolve TSP usando MST"""
        print(f"\n🚀 Resolvendo TSP com {self.n_cities} cidades")
        start_time = time.time()
        
        # 1. Constrói MST
        mst_edges = self.find_mst_simple()
        
        if len(mst_edges) != self.n_cities - 1:
            print(f"❌ ERRO: MST deveria ter {self.n_cities - 1} arestas, mas tem {len(mst_edges)}")
            return None
        
        # 2. Constrói adjacência
        adj_list = self.build_adjacency_from_mst(mst_edges)
        
        # 3. Faz DFS
        tour = self.dfs_tour(adj_list)
        
        # 4. Calcula custo
        cost = self.calculate_tour_cost(tour)
        
        end_time = time.time()
        
        print(f"\n=== RESULTADO ===")
        print(f"MST arestas: {len(mst_edges)}")
        print(f"Tour: {' -> '.join(map(str, tour))} -> {tour[0]}")
        print(f"Custo: {cost}")
        print(f"Tempo: {end_time - start_time:.6f}s")
        
        return {
            'cost': cost,
            'tour': tour,
            'time': end_time - start_time,
            'mst_edges': mst_edges
        }

def main():
    if len(sys.argv) != 2:
        print("Uso: python mst_fixed.py <arquivo_tsp>")
        sys.exit(1)
    
    solver = TSPMSTFixed(sys.argv[1])
    result = solver.solve()

if __name__ == "__main__":
    main()
