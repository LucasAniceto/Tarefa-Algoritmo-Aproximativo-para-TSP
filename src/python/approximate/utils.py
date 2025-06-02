import os
import time
import csv
import matplotlib.pyplot as plt
import pandas as pd
from typing import List, Dict, Tuple
import numpy as np

class TSPUtils:
    
    @staticmethod
    def create_results_directory(base_dir: str = "../../results"):
        os.makedirs(base_dir, exist_ok=True)
        return base_dir
    
    # Valida se arquivo TSP está no formato correto
    @staticmethod
    def validate_tsp_file(filename: str) -> bool:
        try:
            with open(filename, 'r') as file:
                lines = [line.strip() for line in file.readlines() if line.strip()]
            
            if not lines:
                return False
            
            first_row = lines[0].split()
            n_cities = len(first_row)
            
            for line in lines:
                if len(line.split()) != n_cities:
                    return False
            
            if len(lines) != n_cities:
                return False
            
            for line in lines:
                try:
                    list(map(int, line.split()))
                except ValueError:
                    return False
            
            return True
            
        except:
            return False
    
    # Obtém informações básicas do arquivo TSP
    @staticmethod
    def get_file_info(filename: str) -> Dict:
        info = {
            'filename': filename,
            'exists': os.path.exists(filename),
            'size_mb': 0,
            'n_cities': 0,
            'optimal_value': -1,
            'valid': False
        }
        
        if info['exists']:
            info['size_mb'] = os.path.getsize(filename) / (1024 * 1024)
            info['valid'] = TSPUtils.validate_tsp_file(filename)
            
            if info['valid']:
                with open(filename, 'r') as file:
                    first_line = file.readline().strip()
                    info['n_cities'] = len(first_line.split())
                
                basename = os.path.basename(filename)
                if '_' in basename and '.' in basename:
                    try:
                        underscore_pos = basename.rfind('_')
                        dot_pos = basename.rfind('.')
                        if underscore_pos < dot_pos:
                            info['optimal_value'] = int(basename[underscore_pos + 1:dot_pos])
                    except:
                        pass
        
        return info
    
    # Estima tempo de execução baseado no número de cidades
    @staticmethod
    def estimate_execution_time(n_cities: int, algorithm: str) -> str:
        if algorithm.upper() in ['BRUTE_FORCE', 'BRUTE-FORCE']:
            if n_cities <= 10:
                return "< 1 segundo"
            elif n_cities <= 12:
                return "alguns segundos"
            elif n_cities <= 15:
                return "alguns minutos"
            elif n_cities <= 18:
                return "algumas horas"
            else:
                return "impraticável (anos)"
        
        elif algorithm.upper() in ['BRANCH_BOUND', 'BRANCH-BOUND']:
            if n_cities <= 20:
                return "segundos a minutos"
            elif n_cities <= 30:
                return "minutos a horas"
            else:
                return "pode ser impraticável"
        
        elif algorithm.upper() in ['MST', 'APPROXIMATION']:
            return "milissegundos"
        
        return "desconhecido"
    
    @staticmethod
    def format_time(seconds: float) -> str:
        if seconds < 1:
            return f"{seconds * 1000:.2f} ms"
        elif seconds < 60:
            return f"{seconds:.2f} s"
        elif seconds < 3600:
            return f"{seconds / 60:.2f} min"
        else:
            return f"{seconds / 3600:.2f} h"
    
    @staticmethod
    def load_results_csv(filename: str) -> pd.DataFrame:
        try:
            return pd.read_csv(filename)
        except:
            return pd.DataFrame()
    
    # Analisa e compara resultados exatos vs aproximativos
    @staticmethod
    def analyze_results(exact_file: str, approx_file: str) -> Dict:
        exact_df = TSPUtils.load_results_csv(exact_file)
        approx_df = TSPUtils.load_results_csv(approx_file)
        
        analysis = {
            'exact_results': len(exact_df),
            'approx_results': len(approx_df),
            'comparison': []
        }
        
        for _, approx_row in approx_df.iterrows():
            filename = approx_row['filename']
            exact_matches = exact_df[exact_df['filename'] == filename]
            
            if not exact_matches.empty:
                exact_row = exact_matches.iloc[0]
                comparison = {
                    'filename': filename,
                    'n_cities': approx_row['n_cities'],
                    'exact_cost': exact_row['cost'],
                    'approx_cost': approx_row['cost'],
                    'exact_time': exact_row['execution_time'],
                    'approx_time': approx_row['execution_time'],
                    'approximation_ratio': approx_row['cost'] / exact_row['cost'],
                    'speedup': exact_row['execution_time'] / approx_row['execution_time']
                }
                analysis['comparison'].append(comparison)
        
        return analysis
    
    # Gera relatório detalhado da análise
    @staticmethod
    def generate_report(analysis: Dict, output_file: str = "../../results/analysis_report.txt"):
        with open(output_file, 'w') as f:
            f.write("=== RELATÓRIO DE ANÁLISE TSP ===\n\n")
            f.write(f"Resultados exatos encontrados: {analysis['exact_results']}\n")
            f.write(f"Resultados aproximativos encontrados: {analysis['approx_results']}\n")
            f.write(f"Comparações possíveis: {len(analysis['comparison'])}\n\n")
            
            if analysis['comparison']:
                f.write("COMPARAÇÃO DETALHADA:\n")
                f.write("-" * 80 + "\n")
                f.write(f"{'Arquivo':<20} {'Cidades':<8} {'Exato':<8} {'Aprox':<8} {'Razão':<8} {'Speedup':<10}\n")
                f.write("-" * 80 + "\n")
                
                total_ratio = 0
                total_speedup = 0
                
                for comp in analysis['comparison']:
                    f.write(f"{comp['filename']:<20} {comp['n_cities']:<8} "
                           f"{comp['exact_cost']:<8} {comp['approx_cost']:<8} "
                           f"{comp['approximation_ratio']:<8.3f} {comp['speedup']:<10.2f}\n")
                    total_ratio += comp['approximation_ratio']
                    total_speedup += comp['speedup']
                
                avg_ratio = total_ratio / len(analysis['comparison'])
                avg_speedup = total_speedup / len(analysis['comparison'])
                
                f.write("-" * 80 + "\n")
                f.write(f"Razão média de aproximação: {avg_ratio:.3f}\n")
                f.write(f"Speedup médio: {avg_speedup:.2f}x\n")
    
    # Gera gráficos dos resultados
    @staticmethod
    def plot_results(analysis: Dict, output_dir: str = "../../results"):
        if not analysis['comparison']:
            print("Não há dados suficientes para gerar gráficos")
            return
        
        data = analysis['comparison']
        cities = [d['n_cities'] for d in data]
        ratios = [d['approximation_ratio'] for d in data]
        speedups = [d['speedup'] for d in data]
        exact_times = [d['exact_time'] for d in data]
        approx_times = [d['approx_time'] for d in data]
        
        # Gráfico 1: Razão de aproximação vs número de cidades
        plt.figure(figsize=(10, 6))
        plt.scatter(cities, ratios, alpha=0.7, s=100)
        plt.axhline(y=2.0, color='r', linestyle='--', label='Garantia teórica (2x)')
        plt.xlabel('Número de Cidades')
        plt.ylabel('Razão de Aproximação')
        plt.title('Qualidade da Aproximação vs Tamanho da Instância')
        plt.legend()
        plt.grid(True, alpha=0.3)
        plt.savefig(f"{output_dir}/approximation_quality.png", dpi=300, bbox_inches='tight')
        plt.close()
        
        # Gráfico 2: Comparação de tempos
        plt.figure(figsize=(12, 6))
        x = np.arange(len(cities))
        width = 0.35
        
        plt.bar(x - width/2, exact_times, width, label='Algoritmo Exato', alpha=0.8)
        plt.bar(x + width/2, approx_times, width, label='Algoritmo Aproximativo', alpha=0.8)
        
        plt.xlabel('Instâncias TSP')
        plt.ylabel('Tempo de Execução (segundos)')
        plt.title('Comparação de Tempos de Execução')
        plt.xticks(x, [f"{c} cidades" for c in cities], rotation=45)
        plt.legend()
        plt.yscale('log')
        plt.grid(True, alpha=0.3)
        plt.tight_layout()
        plt.savefig(f"{output_dir}/execution_times.png", dpi=300, bbox_inches='tight')
        plt.close()
        
        print(f"Gráficos salvos em {output_dir}/")

class ProgressTracker:
    
    def __init__(self, total_tasks: int, description: str = "Progresso"):
        self.total_tasks = total_tasks
        self.completed_tasks = 0
        self.description = description
        self.start_time = time.time()
        
    def update(self, increment: int = 1):
        self.completed_tasks += increment
        self._print_progress()
        
    def _print_progress(self):
        percentage = (self.completed_tasks / self.total_tasks) * 100
        elapsed_time = time.time() - self.start_time
        
        if self.completed_tasks > 0:
            estimated_total = elapsed_time * (self.total_tasks / self.completed_tasks)
            remaining_time = estimated_total - elapsed_time
        else:
            remaining_time = 0
        
        bar_length = 50
        filled_length = int(bar_length * self.completed_tasks / self.total_tasks)
        bar = '█' * filled_length + '-' * (bar_length - filled_length)
        
        print(f'\r{self.description}: |{bar}| {percentage:.1f}% '
              f'({self.completed_tasks}/{self.total_tasks}) '
              f'ETA: {TSPUtils.format_time(remaining_time)}', end='')
        
        if self.completed_tasks >= self.total_tasks:
            print(f'\n{self.description} concluído em {TSPUtils.format_time(elapsed_time)}')

if __name__ == "__main__":
    test_files = [
        "../../data/tsp1_253.txt",
        "../../data/tsp2_1248.txt"
    ]
    
    for file in test_files:
        info = TSPUtils.get_file_info(file)
        print(f"Arquivo: {info['filename']}")
        print(f"  Existe: {info['exists']}")
        print(f"  Válido: {info['valid']}")
        print(f"  Cidades: {info['n_cities']}")
        print(f"  Valor ótimo: {info['optimal_value']}")
        print(f"  Tempo estimado (força bruta): {TSPUtils.estimate_execution_time(info['n_cities'], 'brute_force')}")
        print()