#!/usr/bin/env python3
"""
Coordenador principal dos experimentos TSP
Executa todos os algoritmos e gera análises comparativas
"""

import os
import sys
import subprocess
import time
import argparse
from typing import List, Dict
import json

# Adiciona o diretório atual ao path para imports
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from mst_algorithm import TSPMSTApproximation
from utils import TSPUtils, ProgressTracker

class TSPExperimentCoordinator:
    """Coordena a execução de todos os experimentos TSP"""
    
    def __init__(self, data_dir: str = "../../data", results_dir: str = "../../results"):
        # Converter para caminhos absolutos baseados no diretório atual
        current_dir = os.path.dirname(os.path.abspath(__file__))
        project_root = os.path.join(current_dir, "../../../")
        
        self.data_dir = os.path.abspath(os.path.join(project_root, "data"))
        self.results_dir = os.path.abspath(os.path.join(project_root, "results"))
        self.bin_dir = os.path.abspath(os.path.join(project_root, "bin"))
        
        # Garante que diretórios existem
        os.makedirs(self.results_dir, exist_ok=True)
        os.makedirs(self.bin_dir, exist_ok=True)
        
        # Lista de arquivos TSP
        self.tsp_files = [
            "tsp1_253.txt",
            "tsp2_1248.txt",
            "tsp3_1194.txt",
            "tsp4_7013.txt",
            "tsp5_27603.txt"
        ]
        
        # Configurações de timeout (em segundos)
        self.timeouts = {
            'brute_force': {
                6: 30,      # 6 cidades: 30 segundos
                11: 300,    # 11 cidades: 5 minutos
                15: 1800,   # 15 cidades: 30 minutos
                29: None,   # 29 cidades: sem timeout (impraticável)
                44: None    # 44 cidades: sem timeout (impraticável)
            },
            'branch_bound': {
                6: 60,      # 6 cidades: 1 minuto
                11: 600,    # 11 cidades: 10 minutos
                15: 3600,   # 15 cidades: 1 hora
                29: 7200,   # 29 cidades: 2 horas
                44: 7200    # 44 cidades: 2 horas
            }
        }
    
    def validate_environment(self) -> bool:
        """Valida se ambiente está configurado corretamente"""
        print("=== Validando Ambiente ===")
        
        issues = []
        
        # Verifica arquivos de dados
        for filename in self.tsp_files:
            filepath = os.path.join(self.data_dir, filename)
            if not os.path.exists(filepath):
                issues.append(f"Arquivo não encontrado: {filepath}")
            elif not TSPUtils.validate_tsp_file(filepath):
                issues.append(f"Arquivo inválido: {filepath}")
        
        # Verifica executáveis C
        c_executables = [
            os.path.join(self.bin_dir, "brute_force"),
            os.path.join(self.bin_dir, "branch_bound"),
            os.path.join(self.bin_dir, "mst_approx")
        ]
        
        for executable in c_executables:
            if not os.path.exists(executable):
                issues.append(f"Executável C não encontrado: {executable}")
        
        # Verifica classes Java - CORRIGIDO
        java_dir = "src/java/exact"
        java_files = ["TSPSolver.class", "BruteForce.class", "BranchBound.class"]
        
        for java_file in java_files:
            filepath = os.path.join(java_dir, java_file)
            if not os.path.exists(filepath):
                issues.append(f"Classe Java não encontrada: {filepath}")
        
        if issues:
            print("⚠ Problemas encontrados:")
            for issue in issues:
                print(f"  - {issue}")
            return False
        else:
            print("✓ Ambiente validado com sucesso")
            return True
    
    def run_c_experiments(self) -> Dict:
        """Executa experimentos em C"""
        print("\n=== Executando Experimentos em C ===")
        results = {'exact': [], 'approximate': []}
        
        # Algoritmos aproximativos (rápidos)
        print("\nExecutando algoritmo MST (C)...")
        for filename in self.tsp_files:
            filepath = os.path.join(self.data_dir, filename)
            executable = os.path.join(self.bin_dir, "mst_approx")
            
            if os.path.exists(executable):
                try:
                    print(f"  Processando {filename}...")
                    result = subprocess.run([executable, filepath], 
                                          capture_output=True, text=True, timeout=60)
                    if result.returncode == 0:
                        results['approximate'].append({
                            'file': filename,
                            'algorithm': 'MST_C',
                            'success': True,
                            'output': result.stdout
                        })
                    else:
                        print(f"    Erro: {result.stderr}")
                except subprocess.TimeoutExpired:
                    print(f"    Timeout para {filename}")
        
        # Algoritmos exatos (podem demorar)
        exact_algorithms = ['brute_force', 'branch_bound']
        
        for algorithm in exact_algorithms:
            print(f"\nExecutando {algorithm} (C)...")
            executable = os.path.join(self.bin_dir, algorithm)
            
            if not os.path.exists(executable):
                print(f"  Executável não encontrado: {executable}")
                continue
            
            for filename in self.tsp_files:
                filepath = os.path.join(self.data_dir, filename)
                info = TSPUtils.get_file_info(filepath)
                n_cities = info['n_cities']
                
                # Verifica timeout
                timeout = self.timeouts[algorithm].get(n_cities)
                if timeout is None:
                    print(f"  Pulando {filename} ({n_cities} cidades - impraticável)")
                    continue
                
                try:
                    print(f"  Processando {filename} (timeout: {timeout}s)...")
                    start_time = time.time()
                    
                    result = subprocess.run([executable, filepath], 
                                          capture_output=True, text=True, timeout=timeout)
                    
                    execution_time = time.time() - start_time
                    
                    if result.returncode == 0:
                        results['exact'].append({
                            'file': filename,
                            'algorithm': f'{algorithm.upper()}_C',
                            'success': True,
                            'execution_time': execution_time,
                            'output': result.stdout
                        })
                        print(f"    ✓ Concluído em {execution_time:.2f}s")
                    else:
                        print(f"    ✗ Erro: {result.stderr}")
                        
                except subprocess.TimeoutExpired:
                    print(f"    ⏱ Timeout após {timeout}s")
                    results['exact'].append({
                        'file': filename,
                        'algorithm': f'{algorithm.upper()}_C',
                        'success': False,
                        'reason': 'timeout',
                        'timeout': timeout
                    })
                except Exception as e:
                    print(f"    ✗ Erro: {e}")
        
        return results
    
    def run_java_experiments(self) -> Dict:
        """Executa experimentos em Java"""
        print("\n=== Executando Experimentos em Java ===")
        results = {'exact': []}
        
        # Compila arquivos Java se necessário
        java_dir = "src/java/exact"
        if not self.compile_java(java_dir):
            print("Erro na compilação Java")
            return results
        
        algorithms = ['brute-force', 'branch-bound']
        
        for algorithm in algorithms:
            print(f"\nExecutando {algorithm} (Java)...")
            
            for filename in self.tsp_files:
                filepath = os.path.join(self.data_dir, filename)
                info = TSPUtils.get_file_info(filepath)
                n_cities = info['n_cities']
                
                # Usa mesmo timeout que C
                timeout_key = 'brute_force' if 'brute' in algorithm else 'branch_bound'
                timeout = self.timeouts[timeout_key].get(n_cities)
                
                if timeout is None:
                    print(f"  Pulando {filename} ({n_cities} cidades - impraticável)")
                    continue
                
                try:
                    print(f"  Processando {filename} (timeout: {timeout}s)...")
                    start_time = time.time()
                    
                    # Executa Java - CORRIGIDO
                    cmd = ['java', '-cp', java_dir, 'TSPSolver', algorithm, filepath]
                    result = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
                    
                    execution_time = time.time() - start_time
                    
                    if result.returncode == 0:
                        results['exact'].append({
                            'file': filename,
                            'algorithm': f'{algorithm.upper().replace("-", "_")}_JAVA',
                            'success': True,
                            'execution_time': execution_time,
                            'output': result.stdout
                        })
                        print(f"    ✓ Concluído em {execution_time:.2f}s")
                    else:
                        print(f"    ✗ Erro: {result.stderr}")
                        
                except subprocess.TimeoutExpired:
                    print(f"    ⏱ Timeout após {timeout}s")
                    results['exact'].append({
                        'file': filename,
                        'algorithm': f'{algorithm.upper().replace("-", "_")}_JAVA',
                        'success': False,
                        'reason': 'timeout',
                        'timeout': timeout
                    })
                except Exception as e:
                    print(f"    ✗ Erro: {e}")
        
        return results
    
    def compile_java(self, java_dir: str) -> bool:
        """Compila arquivos Java"""
        try:
            print("Compilando arquivos Java...")
            
            # Verificar se diretório existe
            if not os.path.exists(java_dir):
                print(f"Diretório Java não encontrado: {java_dir}")
                return False
            
            # Verificar se arquivos .class já existem (já compilados)
            class_files = ['TSPInstance.class', 'TSPResult.class', 'BruteForce.class', 'BranchBound.class', 'TSPSolver.class']
            all_exist = all(os.path.exists(os.path.join(java_dir, cf)) for cf in class_files)
            
            if all_exist:
                print("✓ Arquivos Java já compilados")
                return True
            
            # Compilar se necessário
            java_files = ['TSPInstance.java', 'TSPResult.java', 'BruteForce.java', 'BranchBound.java', 'TSPSolver.java']
            
            original_dir = os.getcwd()
            os.chdir(java_dir)
            
            try:
                for java_file in java_files:
                    if os.path.exists(java_file):
                        result = subprocess.run(['javac', java_file], capture_output=True, text=True)
                        if result.returncode != 0:
                            print(f"Erro compilando {java_file}: {result.stderr}")
                            return False
                    else:
                        print(f"Arquivo Java não encontrado: {java_file}")
                        return False
                
                print("✓ Compilação Java concluída")
                return True
                
            finally:
                os.chdir(original_dir)
            
        except Exception as e:
            print(f"Erro durante compilação: {e}")
            return False
    
    def run_python_experiments(self) -> Dict:
        """Executa experimentos em Python"""
        print("\n=== Executando Experimentos em Python ===")
        results = {'approximate': []}
        
        print("Executando algoritmo MST (Python)...")
        
        for filename in self.tsp_files:
            filepath = os.path.join(self.data_dir, filename)
            
            try:
                print(f"  Processando {filename}...")
                
                solver = TSPMSTApproximation(filepath)
                result = solver.solve()
                
                results['approximate'].append({
                    'file': filename,
                    'algorithm': 'MST_PYTHON',
                    'success': True,
                    'result': result
                })
                
                print(f"    ✓ Custo: {result['cost']}, Tempo: {result['execution_time']:.6f}s")
                
                # Salva resultado individual
                solver.save_results(result)
                
            except Exception as e:
                print(f"    ✗ Erro: {e}")
                results['approximate'].append({
                    'file': filename,
                    'algorithm': 'MST_PYTHON',
                    'success': False,
                    'error': str(e)
                })
        
        return results
    
    def generate_comparative_analysis(self):
        """Gera análise comparativa dos resultados"""
        print("\n=== Gerando Análise Comparativa ===")
        
        exact_file = os.path.join(self.results_dir, "exact_results.txt")
        approx_file = os.path.join(self.results_dir, "approximate_results.txt")
        
        if os.path.exists(exact_file) and os.path.exists(approx_file):
            analysis = TSPUtils.analyze_results(exact_file, approx_file)
            
            # Gera relatório
            report_file = os.path.join(self.results_dir, "analysis_report.txt")
            TSPUtils.generate_report(analysis, report_file)
            print(f"✓ Relatório salvo em: {report_file}")
            
            # Gera gráficos
            try:
                TSPUtils.plot_results(analysis, self.results_dir)
                print("✓ Gráficos gerados")
            except Exception as e:
                print(f"⚠ Erro ao gerar gráficos: {e}")
        else:
            print("⚠ Arquivos de resultados não encontrados")
    
    def run_all_experiments(self, include_c=True, include_java=True, include_python=True):
        """Executa todos os experimentos"""
        print("=== INICIANDO EXPERIMENTOS TSP ===")
        print(f"Diretório de dados: {self.data_dir}")
        print(f"Diretório de resultados: {self.results_dir}")
        
        if not self.validate_environment():
            print("❌ Ambiente não está configurado corretamente")
            return False
        
        all_results = {
            'c_results': {},
            'java_results': {},
            'python_results': {},
            'start_time': time.time()
        }
        
        # Limpa arquivos de resultado anteriores
        for result_file in ['exact_results.txt', 'approximate_results.txt']:
            filepath = os.path.join(self.results_dir, result_file)
            if os.path.exists(filepath):
                os.remove(filepath)
        
        # Executa experimentos
        if include_c:
            all_results['c_results'] = self.run_c_experiments()
        
        if include_java:
            all_results['java_results'] = self.run_java_experiments()
        
        if include_python:
            all_results['python_results'] = self.run_python_experiments()
        
        # Salva resumo dos experimentos
        all_results['end_time'] = time.time()
        all_results['total_time'] = all_results['end_time'] - all_results['start_time']
        
        summary_file = os.path.join(self.results_dir, "experiment_summary.json")
        with open(summary_file, 'w') as f:
            # Remove objetos não serializáveis
            clean_results = self._clean_results_for_json(all_results)
            json.dump(clean_results, f, indent=2)
        
        print(f"\n✓ Experimentos concluídos em {TSPUtils.format_time(all_results['total_time'])}")
        print(f"✓ Resumo salvo em: {summary_file}")
        
        # Gera análise comparativa
        self.generate_comparative_analysis()
        
        return True
    
    def _clean_results_for_json(self, results):
        """Remove objetos não serializáveis para JSON"""
        clean = {}
        for key, value in results.items():
            if isinstance(value, dict):
                clean[key] = self._clean_results_for_json(value)
            elif isinstance(value, list):
                clean[key] = [self._clean_results_for_json(item) if isinstance(item, dict) else item 
                             for item in value]
            elif key == 'result' and hasattr(value, '__dict__'):
                # Pula objetos complexos
                continue
            else:
                clean[key] = value
        return clean

def main():
    """Função principal"""
    parser = argparse.ArgumentParser(description='Coordenador de Experimentos TSP')
    parser.add_argument('--no-c', action='store_true', help='Pula experimentos em C')
    parser.add_argument('--no-java', action='store_true', help='Pula experimentos em Java')
    parser.add_argument('--no-python', action='store_true', help='Pula experimentos em Python')
    parser.add_argument('--data-dir', default='../../data', help='Diretório dos dados')
    parser.add_argument('--results-dir', default='../../results', help='Diretório dos resultados')
    parser.add_argument('--only-analysis', action='store_true', help='Apenas gera análise dos resultados existentes')
    
    args = parser.parse_args()
    
    coordinator = TSPExperimentCoordinator(args.data_dir, args.results_dir)
    
    if args.only_analysis:
        coordinator.generate_comparative_analysis()
    else:
        coordinator.run_all_experiments(
            include_c=not args.no_c,
            include_java=not args.no_java,
            include_python=not args.no_python
        )

if __name__ == "__main__":
    main()
