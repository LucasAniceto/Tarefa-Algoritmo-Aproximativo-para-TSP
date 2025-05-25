# Makefile principal do projeto TSP
# Compila todos os componentes e executa testes

.PHONY: all clean test setup run-all help c-only java-only python-only quick-test

# Configurações
CC = gcc
CFLAGS = -Wall -Wextra -O3 -std=c99
JAVA_SRC_DIR = src/java/exact
C_EXACT_DIR = src/c/exact
C_APPROX_DIR = src/c/approximate
BIN_DIR = bin
DATA_DIR = data
RESULTS_DIR = results

# Alvos principais
all: setup c-programs java-programs
	@echo "✅ Compilação completa concluída"
	@echo "Execute 'make test' para testar ou 'make run-all' para experimentos completos"

# Configuração inicial
setup:
	@echo "🔧 Configurando ambiente..."
	@mkdir -p $(BIN_DIR) $(RESULTS_DIR)
	@echo "✅ Diretórios criados"

# Compilação de programas C
c-programs: c-exact c-approx

c-exact:
	@echo "🔨 Compilando algoritmos exatos (C)..."
	@if [ -d "$(C_EXACT_DIR)" ]; then \
		cd $(C_EXACT_DIR) && $(MAKE) all; \
	else \
		echo "⚠️  Diretório $(C_EXACT_DIR) não encontrado"; \
	fi

c-approx:
	@echo "🔨 Compilando algoritmos aproximativos (C)..."
	@if [ -d "$(C_APPROX_DIR)" ]; then \
		cd $(C_APPROX_DIR) && $(MAKE) all; \
	else \
		echo "⚠️  Diretório $(C_APPROX_DIR) não encontrado"; \
	fi

# Compilação Java
java-programs:
	@echo "☕ Compilando programas Java..."
	@if [ -d "$(JAVA_SRC_DIR)" ]; then \
		cd $(JAVA_SRC_DIR) && \
		rm -f *.class && \
		echo "Compilando na ordem de dependências..." && \
		javac TSPInstance.java && \
		javac TSPResult.java && \
		javac BruteForce.java && \
		javac BranchBound.java && \
		javac TSPSolver.java && \
		echo "✅ Java compilado com sucesso"; \
	else \
		echo "⚠️  Diretório $(JAVA_SRC_DIR) não encontrado"; \
	fi

# Testes rápidos
quick-test: all
	@echo "🧪 Executando testes rápidos..."
	@echo "Testando com tsp2_1248.txt (6 cidades):"
	@if [ -f "$(BIN_DIR)/mst_approx" ] && [ -f "$(DATA_DIR)/tsp2_1248.txt" ]; then \
		echo "  MST Aproximativo (C):"; \
		$(BIN_DIR)/mst_approx $(DATA_DIR)/tsp2_1248.txt; \
	fi
	@if [ -f "$(BIN_DIR)/brute_force" ] && [ -f "$(DATA_DIR)/tsp2_1248.txt" ]; then \
		echo "  Força Bruta (C):"; \
		timeout 30 $(BIN_DIR)/brute_force $(DATA_DIR)/tsp2_1248.txt || echo "  (timeout ou erro)"; \
	fi
	@if [ -f "src/python/approximate/mst_algorithm.py" ] && [ -f "$(DATA_DIR)/tsp2_1248.txt" ]; then \
		echo "  MST Aproximativo (Python):"; \
		python3 src/python/approximate/mst_algorithm.py $(DATA_DIR)/tsp2_1248.txt; \
	fi

# Teste completo
test: quick-test
	@echo "🧪 Executando bateria de testes..."
	@echo "Testando algoritmos C com arquivos pequenos..."
	@if [ -d "$(C_EXACT_DIR)" ]; then \
		cd $(C_EXACT_DIR) && $(MAKE) test-small; \
	fi
	@if [ -d "$(C_APPROX_DIR)" ]; then \
		cd $(C_APPROX_DIR) && $(MAKE) test-small; \
	fi

# Execução completa dos experimentos
run-all: all
	@echo "🚀 Iniciando experimentos completos..."
	@python3 run_experiments.py

# Apenas experimentos C
c-only: c-programs
	@echo "🔬 Executando apenas experimentos C..."
	@for file in $(DATA_DIR)/tsp*.txt; do \
		if [ -f "$$file" ]; then \
			echo "Processando $$file..."; \
			if [ -f "$(BIN_DIR)/mst_approx" ]; then \
				$(BIN_DIR)/mst_approx "$$file"; \
			fi; \
		fi; \
	done

# Apenas experimentos Java
java-only: java-programs
	@echo "☕ Executando apenas experimentos Java..."
	@cd $(JAVA_SRC_DIR) && \
	for file in ../../../$(DATA_DIR)/tsp1_253.txt ../../../$(DATA_DIR)/tsp2_1248.txt; do \
		if [ -f "$$file" ]; then \
			echo "Testando $$file com Java..."; \
			timeout 300 java TSPSolver brute-force "$$file" || echo "Timeout ou erro"; \
		fi; \
	done

# Apenas experimentos Python
python-only:
	@echo "🐍 Executando apenas experimentos Python..."
	@if [ -f "src/python/approximate/main.py" ]; then \
		python3 src/python/approximate/main.py --no-c --no-java; \
	else \
		echo "Script Python não encontrado"; \
	fi

# Limpeza
clean:
	@echo "🧹 Limpando arquivos..."
	@rm -f $(BIN_DIR)/*
	@if [ -d "$(C_EXACT_DIR)" ]; then cd $(C_EXACT_DIR) && $(MAKE) clean; fi
	@if [ -d "$(C_APPROX_DIR)" ]; then cd $(C_APPROX_DIR) && $(MAKE) clean; fi
	@if [ -d "$(JAVA_SRC_DIR)" ]; then rm -f $(JAVA_SRC_DIR)/*.class; fi
	@rm -f $(RESULTS_DIR)/*.txt $(RESULTS_DIR)/*.json $(RESULTS_DIR)/*.png
	@echo "✅ Limpeza concluída"

# Verificação do ambiente
check:
	@echo "🔍 Verificando ambiente..."
	@echo "Compiladores:"
	@gcc --version | head -1 || echo "❌ GCC não encontrado"
	@javac -version 2>&1 || echo "❌ Java compiler não encontrado"
	@java -version 2>&1 | head -1 || echo "❌ Java runtime não encontrado"
	@python3 --version || echo "❌ Python3 não encontrado"
	@make --version | head -1 || echo "❌ Make não encontrado"
	@echo ""
	@echo "Estrutura de diretórios:"
	@ls -la src/ 2>/dev/null || echo "❌ src/ não encontrado"
	@ls -la data/ 2>/dev/null || echo "❌ data/ não encontrado"
	@echo ""
	@echo "Arquivos de dados:"
	@ls -la data/tsp*.txt 2>/dev/null || echo "❌ Arquivos TSP não encontrados em data/"
	@echo ""
	@echo "Bibliotecas Python:"
	@python3 -c "import matplotlib; print('✅ matplotlib')" 2>/dev/null || echo "❌ matplotlib não encontrado"
	@python3 -c "import pandas; print('✅ pandas')" 2>/dev/null || echo "❌ pandas não encontrado"
	@python3 -c "import numpy; print('✅ numpy')" 2>/dev/null || echo "❌ numpy não encontrado"

# Instalação de dependências (Ubuntu/Debian)
install-deps:
	@echo "📦 Instalando dependências..."
	sudo apt update
	sudo apt install -y gcc openjdk-11-jdk make python3 python3-pip
	pip3 install matplotlib pandas numpy
	@echo "✅ Dependências instaladas"

# Benchmark rápido
benchmark: all
	@echo "⏱️  Executando benchmark..."
	@echo "Arquivo,Algoritmo,Tempo(s),Custo" > $(RESULTS_DIR)/benchmark.csv
	@for file in $(DATA_DIR)/tsp1_253.txt $(DATA_DIR)/tsp2_1248.txt; do \
		if [ -f "$$file" ]; then \
			echo "Benchmarking $$file..."; \
			if [ -f "$(BIN_DIR)/mst_approx" ]; then \
				timeout 60 $(BIN_DIR)/mst_approx "$$file"; \
			fi; \
		fi; \
	done
	@echo "Benchmark salvo em $(RESULTS_DIR)/benchmark.csv"

# Demonstração
demo: quick-test
	@echo "🎬 Demonstração do projeto..."
	@echo ""
	@echo "1. Algoritmo aproximativo é muito rápido:"
	@time $(BIN_DIR)/mst_approx $(DATA_DIR)/tsp1_253.txt 2>/dev/null || true
	@echo ""
	@echo "2. Algoritmo exato é mais lento mas encontra solução ótima:"
	@timeout 10 $(BIN_DIR)/brute_force $(DATA_DIR)/tsp2_1248.txt 2>/dev/null || echo "   (interrompido por timeout)"
	@echo ""
	@echo "3. Para instâncias maiores, apenas aproximativo é viável:"
	@$(BIN_DIR)/mst_approx $(DATA_DIR)/tsp4_7013.txt 2>/dev/null || true

# Ajuda
help:
	@echo "🆘 Comandos disponíveis:"
	@echo ""
	@echo "  make all         - Compila tudo"
	@echo "  make setup       - Cria diretórios necessários"
	@echo "  make c-programs  - Compila apenas código C"
	@echo "  make java-programs - Compila apenas código Java"
	@echo "  make quick-test  - Executa testes rápidos"
	@echo "  make test        - Executa bateria de testes"
	@echo "  make run-all     - Executa experimentos completos"
	@echo "  make c-only      - Apenas experimentos C"
	@echo "  make java-only   - Apenas experimentos Java"
	@echo "  make python-only - Apenas experimentos Python"
	@echo "  make benchmark   - Benchmark rápido"
	@echo "  make demo        - Demonstração"
	@echo "  make check       - Verifica ambiente"
	@echo "  make install-deps - Instala dependências (Ubuntu)"
	@echo "  make clean       - Remove arquivos compilados"
	@echo "  make help        - Mostra esta ajuda"
	@echo ""
	@echo "🚀 Para começar rapidamente:"
	@echo "  make all && make quick-test"
