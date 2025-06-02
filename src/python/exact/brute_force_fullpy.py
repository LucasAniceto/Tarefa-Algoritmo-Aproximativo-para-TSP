import time
import sys
import os
from itertools import permutations
from typing import List, Tuple

class TSPBruteForceNFactorial:
    
    def __init__(self, filename: str):
        self.filename = filename
        self.matrix = []
        self.n_cities = 0
        self.best_cost = float('inf')
        self.best_path = []
        self.permutations_tested = 0
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
    
    def calculate_path_cost(self, path: List[int]) -> int:
        total_cost = 0
        for i in range(len(path) - 1):
            total_cost += self.matrix[path[i]][path[i + 1]]
        total_cost += self.matrix[path[-1]][path[0]]
        return total_cost
    
    def factorial(self, n: int) -> int:
        if n <= 1:
            return 1
        result = 1
        for i in range(2, n + 1):
            result *= i
        return result
    
    # Resolve TSP usando força bruta SEM OTIMIZAÇÃO - usa n! permutações
    def solve(self) -> dict:
        print(f"\n=== Iniciando Força Bruta n! Python para {self.n_cities} cidades ===")
        
        if self.n_cities > 10:
            response = input(f"AVISO: {self.n_cities} cidades = {self.factorial(self.n_cities):,} permutações! Continuar? (s/n): ")
            if response.lower() not in ['s', 'sim', 'y', 'yes']:
                print("Execução cancelada.")
                sys.exit(0)
        
        expected_permutations = self.factorial(self.n_cities)
        optimized_permutations = self.factorial(self.n_cities - 1)
        
        print(f"🔥 Versão n! (não otimizada): {expected_permutations:,} permutações")
        print(f"⚡ Versão (n-1)! (otimizada): {optimized_permutations:,} permutações")
        print(f"📊 Diferença: {self.n_cities}x mais permutações ({expected_permutations / optimized_permutations:.1f}x)")
        print(f"⚠️  Esta versão é {self.n_cities}x mais lenta que a otimizada!")
        print("")
        
        start_time = time.time()
        
        # SEM OTIMIZAÇÃO: usa TODAS as cidades, não fixa a primeira
        all_cities = list(range(self.n_cities))
        
        for perm in permutations(all_cities):
            self.permutations_tested += 1
            
            path = list(perm)
            
            cost = self.calculate_path_cost(path)
            
            if cost < self.best_cost:
                self.best_cost = cost
                self.best_path = path.copy()
                print(f"Nova melhor solução encontrada: {cost} (permutação {self.permutations_tested:,})")
            
            if self.permutations_tested % 100_000 == 0:
                elapsed = time.time() - start_time
                rate = self.permutations_tested / elapsed if elapsed > 0 else 0
                eta = (expected_permutations - self.permutations_tested) / rate if rate > 0 else 0
                print(f"Progresso: {self.permutations_tested:,}/{expected_permutations:,} "
                      f"({100*self.permutations_tested/expected_permutations:.1f}%) "
                      f"ETA: {eta/60:.1f}min")
        
        end_time = time.time()
        execution_time = end_time - start_time
        
        print(f"Permutações testadas: {self.permutations_tested:,}")
        print(f"Permutações esperadas: {expected_permutations:,}")
        
        if self.permutations_tested != expected_permutations:
            print(f"⚠️  AVISO: Número de permutações não confere!")
        
        optimal_value = self.get_optimal_value()
        
        result = {
            'algorithm': 'BRUTE_FORCE_N_FACTORIAL_PYTHON',
            'filename': self.filename,
            'n_cities': self.n_cities,
            'best_path': self.best_path,
            'best_cost': self.best_cost,
            'execution_time': execution_time,
            'permutations_tested': self.permutations_tested,
            'permutations_expected': expected_permutations,
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
        print(f"\n=== RESULTADOS FORÇA BRUTA n! PYTHON ===")
        print(f"Arquivo: {result['filename']}")
        print(f"Número de cidades: {result['n_cities']}")
        print(f"Melhor custo encontrado: {result['best_cost']}")
        print(f"Tempo de execução: {result['execution_time']:.6f} segundos")
        print(f"Permutações testadas: {result['permutations_tested']:,}")
        print(f"Melhor caminho: {' -> '.join(map(str, result['best_path']))}")
        
        if result['optimal_value'] > 0:
            print(f"Valor ótimo esperado: {result['optimal_value']}")
            if result['is_optimal']:
                print("✅ Solução ótima encontrada!")
            else:
                ratio = result['best_cost'] / result['optimal_value']
                print(f"⚠️ Razão: {ratio:.3f}")
        
        # Comparação com versão otimizada
        optimized_perms = self.factorial(result['n_cities'] - 1)
        slowdown_factor = result['n_cities']
        estimated_optimized_time = result['execution_time'] / slowdown_factor
        
        print(f"\n=== COMPARAÇÃO COM VERSÃO OTIMIZADA ===")
        print(f"Esta versão (n!): {result['permutations_tested']:,} permutações")
        print(f"Versão otimizada ((n-1)!): {optimized_perms:,} permutações")
        print(f"Diferença: {slowdown_factor}x mais permutações")
        print(f"Tempo desta versão: {result['execution_time']:.6f}s")
        print(f"Tempo estimado versão otimizada: {estimated_optimized_time:.6f}s")
        print(f"Speedup da otimização: {slowdown_factor:.1f}x")
        print(f"Ambas encontram o mesmo resultado ótimo: {result['best_cost']}")
    
    def save_results(self, result: dict, output_file: str = "results/exact_results_n_factorial.txt"):
        os.makedirs(os.path.dirname(output_file), exist_ok=True)
        
        try:
            with open(output_file, 'a') as f:
                f.write(f"{result['filename']},{result['n_cities']},{result['best_cost']},"
                       f"{result['execution_time']:.6f},{result['algorithm']},"
                       f"{result['optimal_value']},{result['permutations_tested']}\n")
        except Exception as e:
            print(f"Erro ao salvar resultados: {e}")

def main():
    if len(sys.argv) != 2:
        print("Uso: python brute_force_n_factorial.py <arquivo_tsp>")
        print("")
        print("Esta versão usa n! permutações (SEM otimização)")
        print("Para comparar com a versão otimizada que usa (n-1)!")
        print("")
        print("Exemplo:")
        print("  python brute_force_n_factorial.py data/tsp2_1248.txt")
        print("  python brute_force_n_factorial.py data/tsp1_253.txt")
        sys.exit(1)
    
    filename = sys.argv[1]
    
    try:
        solver = TSPBruteForceNFactorial(filename)
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