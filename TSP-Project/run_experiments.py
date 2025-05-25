#!/usr/bin/env python3
"""
Script principal para executar todos os experimentos TSP
Compila códigos, executa algoritmos e gera análises
"""

import os
import sys
import subprocess
import time
import shutil
from pathlib import Path

def print_header(title):
    """Imprime cabeçalho formatado"""
    print("\n" + "=" * 60)
    print(f" {title}")
    print("=" * 60)

def print_step(step, description):
    """Imprime passo da execução"""
    print(f"\n[{step}] {description}")
    print("-" * 40)

def check_requirements():
    """Verifica se todos os requisitos estão instalados"""
    print_step("1", "Verificando Requisitos")
    
    requirements = {
        'gcc': 'Compilador C',
        'java': 'Java Runtime',
        'javac': 'Java Compiler',
        'python3': 'Python 3',
        'make': 'Make (build tool)'
    }
    
    missing = []
    for cmd, desc in requirements.items():
        try:
            result = subprocess.run([cmd, '--version'], capture_output=True)
            if result.returncode == 0:
                print(f"✓ {desc}")
            else:
                missing.append(desc)
        except FileNotFoundError:
            missing.append(desc)
            print(f"✗ {desc} - NÃO ENCONTRADO")
    
    # Verifica bibliotecas Python
    python_libs = ['matplotlib', 'pandas', 'numpy']
    for lib in python_libs:
        try:
            __import__(lib)
            print(f"✓ Python {lib}")
        except ImportError:
            missing.append(f"Python {lib}")
            print(f"✗ Python {lib} - NÃO ENCONTRADO")
    
    if missing:
        print(f"\n❌ Requisitos faltantes: {', '.join(missing)}")
        print("\nPara instalar:")
        print("  - Ubuntu/Debian: sudo apt install gcc openjdk-11-jdk make")
        print("  - Python libs: pip install matplotlib pandas numpy")
        return False
    else:
        print("\n✅ Todos os requisitos estão instalados")
        return True

def setup_directories():
    """Cria estrutura de diretórios"""
    print_step("2", "Configurando Diretórios")
    
    directories = [
        'bin',
        'results',
        'data'
    ]
    
    for dir_name in directories:
        Path(dir_name).mkdir(exist_ok=True)
        print(f"✓ {dir_name}/")
    
    # Verifica se arquivos de dados existem
    data_files = [
        'data/tsp1_253.txt',
        'data/tsp2_1248.txt',
        'data/tsp3_1194.txt',
        'data/tsp4_7013.txt',
        'data/tsp5_27603.txt'
    ]
    
    missing_data = []
    for file_path in data_files:
        if os.path.exists(file_path):
            print(f"✓ {file_path}")
        else:
            missing_data.append(file_path)
            print(f"✗ {file_path} - NÃO ENCONTRADO")
    
    if missing_data:
        print(f"\n⚠ Arquivos de dados faltantes: {len(missing_data)}")
        print("Coloque os arquivos TSP no diretório 'data/'")
        return False
    
    return True

def compile_c_code():
    """Compila código C"""
    print_step("3", "Compilando Código C")
    
    c_projects = [
        ('src/c/exact', ['brute_force', 'branch_bound']),
        ('src/c/approximate', ['mst_approx'])
    ]
    
    success = True
    
    for project_dir, targets in c_projects:
        if os.path.exists(project_dir):
            print(f"\nCompilando em {project_dir}:")
            
            original_dir = os.getcwd()
            os.chdir(project_dir)
            
            try:
                # Tenta usar Makefile
                if os.path.exists('Makefile'):
                    result = subprocess.run(['make', 'all'], capture_output=True, text=True)
                    if result.returncode == 0:
                        print("✓ Makefile executado com sucesso")
                    else:
                        print(f"✗ Erro no Makefile: {result.stderr}")
                        success = False
                else:
                    # Compila manualmente
                    for target in targets:
                        source_file = f"{target}.c"
                        if os.path.exists(source_file):
                            cmd = ['gcc', '-Wall', '-O3', '-o', f"../../../bin/{target}", source_file]
                            result = subprocess.run(cmd, capture_output=True, text=True)
                            if result.returncode == 0:
                                print(f"✓ {target}.c -> bin/{target}")
                            else:
                                print(f"✗ Erro compilando {target}: {result.stderr}")
                                success = False
                        else:
                            print(f"✗ Arquivo fonte não encontrado: {source_file}")
                            success = False
            
            finally:
                os.chdir(original_dir)
        else:
            print(f"⚠ Diretório não encontrado: {project_dir}")
    
    return success

def compile_java_code():
    """Compila código Java"""
    print_step("4", "Compilando Código Java")
    
    java_dir = 'src/java/exact'
    
    if not os.path.exists(java_dir):
        print(f"⚠ Diretório Java não encontrado: {java_dir}")
        return False
    
    # Verificar se os arquivos existem
    java_files = ['TSPInstance.java', 'TSPResult.java', 'BruteForce.java', 'BranchBound.java', 'TSPSolver.java']
    
    missing_files = []
    for java_file in java_files:
        filepath = os.path.join(java_dir, java_file)
        if not os.path.exists(filepath):
            missing_files.append(java_file)
    
    if missing_files:
        print(f"✗ Arquivos não encontrados: {', '.join(missing_files)}")
        return False
    
    # Compilar todos os arquivos Java de uma vez (solução principal)
    try:
        original_dir = os.getcwd()
        os.chdir(java_dir)
        
        # Remover .class antigos
        for class_file in os.listdir('.'):
            if class_file.endswith('.class'):
                os.remove(class_file)
        
        # Compilar na ordem de dependências
        compile_order = ['TSPInstance.java', 'TSPResult.java', 'BruteForce.java', 'BranchBound.java', 'TSPSolver.java']
        
        print("Compilando Java na ordem correta...")
        for java_file in compile_order:
            result = subprocess.run(['javac', java_file], capture_output=True, text=True)
            if result.returncode == 0:
                print(f"✓ {java_file}")
            else:
                print(f"✗ Erro compilando {java_file}: {result.stderr[:200]}...")
                os.chdir(original_dir)
                return False
        
        # Verificar se todos os .class foram criados
        expected_classes = ['TSPInstance.class', 'TSPResult.class', 'BruteForce.class', 'BranchBound.class', 'TSPSolver.class']
        for class_file in expected_classes:
            if not os.path.exists(class_file):
                print(f"✗ Arquivo .class não gerado: {class_file}")
                os.chdir(original_dir)
                return False
        
        print("✅ Todos os arquivos Java compilados com sucesso")
        os.chdir(original_dir)
        return True
        
    except Exception as e:
        print(f"✗ Erro durante compilação Java: {e}")
        if 'original_dir' in locals():
            os.chdir(original_dir)
        return False

def run_quick_test():
    """Executa teste rápido com arquivo pequeno"""
    print_step("5", "Executando Teste Rápido")
    
    test_file = "data/tsp2_1248.txt"
    if not os.path.exists(test_file):
        print(f"✗ Arquivo de teste não encontrado: {test_file}")
        return False
    
    tests = [
        ('bin/mst_approx', 'MST Aproximativo (C)'),
        ('python3 src/python/approximate/mst_algorithm.py', 'MST Aproximativo (Python)'),
        ('bin/brute_force', 'Força Bruta (C)'),
    ]
    
    success_count = 0
    for cmd, description in tests:
        try:
            print(f"\nTestando {description}:")
            
            if cmd.startswith('python3'):
                # Comando Python
                full_cmd = cmd.split() + [test_file]
            else:
                # Executável
                if os.path.exists(cmd):
                    full_cmd = [cmd, test_file]
                else:
                    print(f"  ✗ Executável não encontrado: {cmd}")
                    continue
            
            result = subprocess.run(full_cmd, capture_output=True, text=True, timeout=30)
            
            if result.returncode == 0:
                print(f"  ✓ {description} - OK")
                success_count += 1
            else:
                print(f"  ✗ {description} - Erro: {result.stderr[:100]}...")
                
        except subprocess.TimeoutExpired:
            print(f"  ⏱ {description} - Timeout")
        except Exception as e:
            print(f"  ✗ {description} - Exceção: {e}")
    
    print(f"\nTestes rápidos: {success_count}/{len(tests)} passaram")
    return success_count > 0

def run_full_experiments():
    """Executa experimentos completos"""
    print_step("6", "Executando Experimentos Completos")
    
    # Executa coordenador Python
    python_script = "src/python/approximate/main.py"
    
    if os.path.exists(python_script):
        try:
            print("Iniciando experimentos completos...")
            result = subprocess.run(['python3', python_script], timeout=7200)  # 2 horas
            
            if result.returncode == 0:
                print("✅ Experimentos concluídos com sucesso!")
                return True
            else:
                print("❌ Experimentos falharam")
                return False
                
        except subprocess.TimeoutExpired:
            print("⏱ Experimentos interrompidos por timeout (2h)")
            return False
        except Exception as e:
            print(f"❌ Erro durante experimentos: {e}")
            return False
    else:
        print(f"✗ Script principal não encontrado: {python_script}")
        return False

def show_results():
    """Mostra resumo dos resultados"""
    print_step("7", "Resultados")
    
    results_files = [
        'results/exact_results.txt',
        'results/approximate_results.txt',
        'results/analysis_report.txt',
        'results/experiment_summary.json'
    ]
    
    print("Arquivos de resultado gerados:")
    for file_path in results_files:
        if os.path.exists(file_path):
            size = os.path.getsize(file_path)
            print(f"✓ {file_path} ({size} bytes)")
        else:
            print(f"✗ {file_path} - não encontrado")
    
    # Mostra gráficos se existirem
    plot_files = [
        'results/approximation_quality.png',
        'results/execution_times.png'
    ]
    
    plots_found = []
    for plot_file in plot_files:
        if os.path.exists(plot_file):
            plots_found.append(plot_file)
    
    if plots_found:
        print(f"\nGráficos gerados: {len(plots_found)}")
        for plot in plots_found:
            print(f"  ✓ {plot}")
    
    # Mostra estatísticas básicas se possível
    if os.path.exists('results/analysis_report.txt'):
        print("\nResumo da análise:")
        try:
            with open('results/analysis_report.txt', 'r') as f:
                lines = f.readlines()[:10]  # Primeiras 10 linhas
                for line in lines:
                    if line.strip():
                        print(f"  {line.strip()}")
        except:
            pass

def main():
    """Função principal"""
    print_header("EXPERIMENTOS TSP - SETUP E EXECUÇÃO")
    print("Este script irá:")
    print("1. Verificar requisitos")
    print("2. Configurar diretórios")
    print("3. Compilar código C")
    print("4. Compilar código Java")
    print("5. Executar teste rápido")
    print("6. Executar experimentos completos")
    print("7. Mostrar resultados")
    
    # Pergunta se deve continuar
    if len(sys.argv) == 1:  # Sem argumentos
        response = input("\nContinuar? (s/n): ").lower()
        if response not in ['s', 'sim', 'y', 'yes']:
            print("Cancelado pelo usuário")
            return
    
    start_time = time.time()
    
    # Executa passos
    steps = [
        ("Requisitos", check_requirements),
        ("Diretórios", setup_directories),
        ("Compilação C", compile_c_code),
        ("Compilação Java", compile_java_code),
        ("Teste Rápido", run_quick_test),
        ("Experimentos", run_full_experiments),
        ("Resultados", lambda: (show_results(), True)[1])
    ]
    
    for step_name, step_func in steps:
        try:
            success = step_func()
            if not success:
                print(f"\n❌ Falha em: {step_name}")
                if input("\nContinuar mesmo assim? (s/n): ").lower() not in ['s', 'sim']:
                    break
        except KeyboardInterrupt:
            print(f"\n⚠ Interrompido pelo usuário em: {step_name}")
            break
        except Exception as e:
            print(f"\n❌ Erro em {step_name}: {e}")
            if input("\nContinuar mesmo assim? (s/n): ").lower() not in ['s', 'sim']:
                break
    
    total_time = time.time() - start_time
    print(f"\n⏱ Tempo total: {total_time/60:.1f} minutos")
    print_header("CONCLUÍDO")

if __name__ == "__main__":
    main()
