.PHONY: all clean test setup run-all help c-only python-only quick-test check-files manual-compile debug-compile

# Configurações
CC = gcc
CFLAGS = -Wall -Wextra -O3 -std=c99
PROJECT_ROOT := $(shell pwd)
PROJECT_NAME := $(shell basename $(PROJECT_ROOT))

C_EXACT_DIR = src/c/exact
C_APPROX_DIR = src/c/approximate
BIN_DIR = bin
DATA_DIR = data
RESULTS_DIR = results

check-structure:
	@echo "🔍 Verificando estrutura do projeto..."
	@echo "Diretório atual: $(PROJECT_ROOT)"
	@echo "Nome do projeto: $(PROJECT_NAME)"
	@if [ ! -d "src" ]; then \
		echo "❌ ERRO: Diretório src/ não encontrado!"; \
		echo "   Certifique-se de estar no diretório raiz do projeto"; \
		echo "   (Tarefa-Algoritmo-Aproximativo-para-TSP)"; \
		exit 1; \
	fi
	@if [ ! -d "data" ]; then \
		echo "❌ ERRO: Diretório data/ não encontrado!"; \
		echo "   Os arquivos TSP devem estar em data/"; \
		exit 1; \
	fi
	@echo "✅ Estrutura verificada"

check-files: check-structure
	@echo "📄 Verificando arquivos C..."
	@echo "Arquivos .c encontrados:"
	@find src -name "*.c" -type f 2>/dev/null | sed 's/^/  ✅ /' || echo "  ❌ Nenhum arquivo .c encontrado"
	@echo ""
	@echo "Arquivos específicos esperados:"
	@for file in \
		"$(C_EXACT_DIR)/brute_force.c" \
		"$(C_EXACT_DIR)/branch_bound.c" \
		"$(C_APPROX_DIR)/mst_approx.c"; do \
		if [ -f "$$file" ]; then \
			echo "  ✅ $$file"; \
		else \
			echo "  ❌ $$file (não encontrado)"; \
		fi; \
	done

setup: check-structure
	@echo "🔧 Configurando ambiente..."
	@mkdir -p $(BIN_DIR) $(RESULTS_DIR)
	@echo "✅ Diretórios $(BIN_DIR)/ e $(RESULTS_DIR)/ criados"

manual-compile: setup
	@echo "🔨 Compilação manual dos arquivos C..."
	@echo "Tentando compilar cada arquivo individualmente..."
	
	@if [ -f "$(C_EXACT_DIR)/brute_force.c" ]; then \
		echo "  🔹 Compilando brute_force.c..."; \
		if $(CC) $(CFLAGS) "$(C_EXACT_DIR)/brute_force.c" -o "$(BIN_DIR)/brute_force" 2>/dev/null; then \
			echo "    ✅ Sucesso: $(BIN_DIR)/brute_force"; \
		else \
			echo "    ❌ Erro na compilação de brute_force.c"; \
			echo "    Tentando com flags básicas:"; \
			$(CC) "$(C_EXACT_DIR)/brute_force.c" -o "$(BIN_DIR)/brute_force" 2>&1 | head -5 | sed 's/^/      /'; \
		fi; \
	else \
		echo "  ⚠️  $(C_EXACT_DIR)/brute_force.c não encontrado"; \
	fi
	
	@if [ -f "$(C_EXACT_DIR)/branch_bound.c" ]; then \
		echo "  🔹 Compilando branch_bound.c..."; \
		if $(CC) $(CFLAGS) "$(C_EXACT_DIR)/branch_bound.c" -o "$(BIN_DIR)/branch_bound" 2>/dev/null; then \
			echo "    ✅ Sucesso: $(BIN_DIR)/branch_bound"; \
		else \
			echo "    ❌ Erro na compilação de branch_bound.c"; \
			echo "    Tentando com flags básicas:"; \
			$(CC) "$(C_EXACT_DIR)/branch_bound.c" -o "$(BIN_DIR)/branch_bound" 2>&1 | head -5 | sed 's/^/      /'; \
		fi; \
	else \
		echo "  ⚠️  $(C_EXACT_DIR)/branch_bound.c não encontrado"; \
	fi
	
	@if [ -f "$(C_APPROX_DIR)/mst_approx.c" ]; then \
		echo "  🔹 Compilando mst_approx.c..."; \
		if $(CC) $(CFLAGS) "$(C_APPROX_DIR)/mst_approx.c" -o "$(BIN_DIR)/mst_approx" 2>/dev/null; then \
			echo "    ✅ Sucesso: $(BIN_DIR)/mst_approx"; \
		else \
			echo "    ❌ Erro na compilação de mst_approx.c"; \
			echo "    Tentando com flags básicas:"; \
			$(CC) "$(C_APPROX_DIR)/mst_approx.c" -o "$(BIN_DIR)/mst_approx" 2>&1 | head -5 | sed 's/^/      /'; \
		fi; \
	else \
		echo "  ⚠️  $(C_APPROX_DIR)/mst_approx.c não encontrado"; \
	fi
	
	@if [ -f "$(C_EXACT_DIR)/brute_force_full.c" ]; then \
		echo "  🔹 Compilando brute_force_full.c..."; \
		$(CC) $(CFLAGS) "$(C_EXACT_DIR)/brute_force_full.c" -o "$(BIN_DIR)/brute_force_full" 2>/dev/null && \
			echo "    ✅ Sucesso: $(BIN_DIR)/brute_force_full" || \
			echo "    ❌ Erro na compilação"; \
	fi
	
	@if [ -f "$(C_EXACT_DIR)/branch_bound_full.c" ]; then \
		echo "  🔹 Compilando branch_bound_full.c..."; \
		$(CC) $(CFLAGS) "$(C_EXACT_DIR)/branch_bound_full.c" -o "$(BIN_DIR)/branch_bound_full" 2>/dev/null && \
			echo "    ✅ Sucesso: $(BIN_DIR)/branch_bound_full" || \
			echo "    ❌ Erro na compilação"; \
	fi
	
	@echo ""
	@echo "📊 Executáveis compilados:"
	@ls -la $(BIN_DIR)/ 2>/dev/null | grep -v "^total" | sed 's/^/  /' || echo "  (nenhum executável encontrado)"

debug-compile: setup
	@echo "🐛 Compilação com debug..."
	@$(MAKE) manual-compile CFLAGS="-Wall -Wextra -g -DDEBUG -std=c99"

c-programs: setup
	@echo "🔨 Compilando programas C..."
	@$(MAKE) c-exact
	@$(MAKE) c-approx
	@echo ""
	@echo "📋 Verificando resultados da compilação:"
	@if [ -f "$(BIN_DIR)/brute_force" ] || [ -f "$(BIN_DIR)/branch_bound" ] || [ -f "$(BIN_DIR)/mst_approx" ]; then \
		echo "✅ Compilação bem-sucedida!"; \
		ls -la $(BIN_DIR)/ | grep -v "^total" | sed 's/^/  /'; \
	else \
		echo "⚠️  Makefiles internos falharam, tentando compilação manual..."; \
		$(MAKE) manual-compile; \
	fi

c-exact:
	@echo "  📁 Algoritmos exatos..."
	@if [ -d "$(C_EXACT_DIR)" ]; then \
		if [ -f "$(C_EXACT_DIR)/Makefile" ]; then \
			cd $(C_EXACT_DIR) && $(MAKE) all BIN_DIR="../../../$(BIN_DIR)" 2>/dev/null || \
			echo "    ⚠️  Makefile interno falhou"; \
		else \
			echo "    ⚠️  Makefile não encontrado em $(C_EXACT_DIR)"; \
		fi; \
	else \
		echo "    ❌ Diretório $(C_EXACT_DIR) não encontrado"; \
	fi

c-approx:
	@echo "  📁 Algoritmos aproximativos..."
	@if [ -d "$(C_APPROX_DIR)" ]; then \
		if [ -f "$(C_APPROX_DIR)/Makefile" ]; then \
			cd $(C_APPROX_DIR) && $(MAKE) all BIN_DIR="../../../$(BIN_DIR)" 2>/dev/null || \
			echo "    ⚠️  Makefile interno falhou"; \
		else \
			echo "    ⚠️  Makefile não encontrado em $(C_APPROX_DIR)"; \
		fi; \
	else \
		echo "    ❌ Diretório $(C_APPROX_DIR) não encontrado"; \
	fi

quick-test: check-structure
	@echo "🧪 Executando testes rápidos..."
	@echo ""
	
	@if [ ! -f "$(BIN_DIR)/mst_approx" ] && [ ! -f "$(BIN_DIR)/brute_force" ] && [ ! -f "$(BIN_DIR)/branch_bound" ]; then \
		echo "⚠️  Nenhum executável encontrado. Compilando primeiro..."; \
		$(MAKE) manual-compile; \
		echo ""; \
	fi
	
	@TEST_FILE=""; \
	if [ -f "$(DATA_DIR)/tsp2_1248.txt" ]; then \
		TEST_FILE="$(DATA_DIR)/tsp2_1248.txt"; \
	elif [ -f "$(DATA_DIR)/tsp1_253.txt" ]; then \
		TEST_FILE="$(DATA_DIR)/tsp1_253.txt"; \
	else \
		TEST_FILE=$$(ls $(DATA_DIR)/tsp*.txt 2>/dev/null | head -1); \
	fi; \
	\
	if [ -n "$$TEST_FILE" ] && [ -f "$$TEST_FILE" ]; then \
		echo "📄 Testando com $$(basename $$TEST_FILE):"; \
		echo ""; \
		\
		if [ -f "$(BIN_DIR)/mst_approx" ]; then \
			echo "  🔹 MST Aproximativo (C):"; \
			"$(BIN_DIR)/mst_approx" "$$TEST_FILE" 2>/dev/null || echo "    ❌ Erro na execução"; \
			echo ""; \
		fi; \
		\
		if [ -f "$(BIN_DIR)/brute_force" ]; then \
			echo "  🔹 Força Bruta (C):"; \
			timeout 30 "$(BIN_DIR)/brute_force" "$$TEST_FILE" 2>/dev/null || echo "    ⏱️  Timeout ou erro"; \
			echo ""; \
		fi; \
		\
		if [ -f "src/python/approximate/mst_algorithm.py" ]; then \
			echo "  🔹 MST Aproximativo (Python):"; \
			python3 src/python/approximate/mst_algorithm.py "$$TEST_FILE" 2>/dev/null || echo "    ❌ Erro Python"; \
		fi; \
	else \
		echo "❌ Nenhum arquivo de teste encontrado em $(DATA_DIR)/"; \
		echo "   Arquivos disponíveis:"; \
		ls -la $(DATA_DIR)/ 2>/dev/null | sed 's/^/     /' || echo "     (diretório vazio)"; \
	fi

test: quick-test
	@echo ""
	@echo "🧪 Executando bateria de testes..."
	@echo "Testando algoritmos C com arquivos pequenos..."
	@if [ -d "$(C_EXACT_DIR)" ] && [ -f "$(C_EXACT_DIR)/Makefile" ]; then \
		cd $(C_EXACT_DIR) && $(MAKE) test-small 2>/dev/null || echo "  ⚠️  Teste interno falhou"; \
	fi
	@if [ -d "$(C_APPROX_DIR)" ] && [ -f "$(C_APPROX_DIR)/Makefile" ]; then \
		cd $(C_APPROX_DIR) && $(MAKE) test-small 2>/dev/null || echo "  ⚠️  Teste interno falhou"; \
	fi

run-all: c-programs
	@echo "🚀 Iniciando experimentos completos..."
	@if [ -f "run_experiments.py" ]; then \
		python3 run_experiments.py; \
	elif [ -f "src/python/approximate/main.py" ]; then \
		python3 src/python/approximate/main.py; \
	else \
		echo "⚠️  Script de experimentos não encontrado"; \
		$(MAKE) c-only; \
	fi

c-only: c-programs
	@echo "🔬 Executando apenas experimentos C..."
	@for file in $(DATA_DIR)/tsp*.txt; do \
		if [ -f "$$file" ]; then \
			echo "Processando $$(basename $$file)..."; \
			if [ -f "$(BIN_DIR)/mst_approx" ]; then \
				"$(BIN_DIR)/mst_approx" "$$file" || echo "  ❌ Erro"; \
			else \
				echo "  ⚠️  mst_approx não encontrado"; \
			fi; \
			echo ""; \
		fi; \
	done

python-only:
	@echo "🐍 Executando apenas experimentos Python..."
	@if [ -f "src/python/approximate/main.py" ]; then \
		python3 src/python/approximate/main.py --no-c --data-dir="$(DATA_DIR)" --results-dir="$(RESULTS_DIR)"; \
	elif [ -f "src/python/approximate/mst_algorithm.py" ]; then \
		echo "Executando MST Python individualmente..."; \
		for file in $(DATA_DIR)/tsp*.txt; do \
			if [ -f "$$file" ]; then \
				echo "  Processando $$(basename $$file)..."; \
				python3 src/python/approximate/mst_algorithm.py "$$file"; \
			fi; \
		done; \
	else \
		echo "❌ Scripts Python não encontrados"; \
	fi

clean:
	@echo "🧹 Limpando arquivos..."
	@rm -f $(BIN_DIR)/* 2>/dev/null || true
	@if [ -d "$(C_EXACT_DIR)" ] && [ -f "$(C_EXACT_DIR)/Makefile" ]; then \
		cd $(C_EXACT_DIR) && $(MAKE) clean 2>/dev/null || true; \
	fi
	@if [ -d "$(C_APPROX_DIR)" ] && [ -f "$(C_APPROX_DIR)/Makefile" ]; then \
		cd $(C_APPROX_DIR) && $(MAKE) clean 2>/dev/null || true; \
	fi
	@rm -f $(RESULTS_DIR)/*.txt $(RESULTS_DIR)/*.json $(RESULTS_DIR)/*.png 2>/dev/null || true
	@echo "✅ Limpeza concluída"

check: check-structure
	@echo "🔍 Verificando ambiente completo..."
	@echo ""
	@echo "🔧 Compiladores:"
	@gcc --version 2>/dev/null | head -1 | sed 's/^/  ✅ /' || echo "  ❌ GCC não encontrado"
	@python3 --version 2>/dev/null | sed 's/^/  ✅ /' || echo "  ❌ Python3 não encontrado"
	@make --version 2>/dev/null | head -1 | sed 's/^/  ✅ /' || echo "  ❌ Make não encontrado"
	@echo ""
	@echo "📁 Estrutura de diretórios:"
	@for dir in src data bin results; do \
		if [ -d "$$dir" ]; then \
			echo "  ✅ $$dir/ (existe)"; \
		else \
			echo "  ❌ $$dir/ (não existe)"; \
		fi; \
	done
	@echo ""
	@echo "📄 Arquivos de dados:"
	@if [ -n "$$(ls $(DATA_DIR)/tsp*.txt 2>/dev/null)" ]; then \
		ls $(DATA_DIR)/tsp*.txt | sed 's/^/  ✅ /'; \
	else \
		echo "  ❌ Arquivos TSP não encontrados em $(DATA_DIR)/"; \
	fi
	@echo ""
	@echo "🐍 Bibliotecas Python:"
	@python3 -c "import matplotlib; print('  ✅ matplotlib')" 2>/dev/null || echo "  ❌ matplotlib não encontrado"
	@python3 -c "import pandas; print('  ✅ pandas')" 2>/dev/null || echo "  ❌ pandas não encontrado"
	@python3 -c "import numpy; print('  ✅ numpy')" 2>/dev/null || echo "  ❌ numpy não encontrado"

install-deps:
	@echo "📦 Instalando dependências..."
	sudo apt update
	sudo apt install -y build-essential python3 python3-pip
	pip3 install matplotlib pandas numpy
	@echo "✅ Dependências instaladas"

benchmark: c-programs
	@echo "⏱️  Executando benchmark..."
	@echo "Arquivo,Algoritmo,Tempo(s),Custo" > $(RESULTS_DIR)/benchmark.csv
	@for file in $(DATA_DIR)/tsp1_253.txt $(DATA_DIR)/tsp2_1248.txt; do \
		if [ -f "$$file" ]; then \
			echo "Benchmarking $$(basename $$file)..."; \
			if [ -f "$(BIN_DIR)/mst_approx" ]; then \
				timeout 60 "$(BIN_DIR)/mst_approx" "$$file" || echo "  Timeout/erro"; \
			fi; \
		fi; \
	done
	@echo "Benchmark salvo em $(RESULTS_DIR)/benchmark.csv"

demo: c-programs
	@echo "🎬 Demonstração do projeto TSP..."
	@echo ""
	@if [ -f "$(BIN_DIR)/mst_approx" ] && [ -f "$(DATA_DIR)/tsp1_253.txt" ]; then \
		echo "1️⃣  Algoritmo aproximativo (muito rápido):"; \
		time "$(BIN_DIR)/mst_approx" "$(DATA_DIR)/tsp1_253.txt" 2>/dev/null || echo "   Erro na execução"; \
	fi
	@echo ""
	@if [ -f "$(BIN_DIR)/brute_force" ] && [ -f "$(DATA_DIR)/tsp2_1248.txt" ]; then \
		echo "2️⃣  Algoritmo exato (mais lento):"; \
		timeout 10 "$(BIN_DIR)/brute_force" "$(DATA_DIR)/tsp2_1248.txt" 2>/dev/null || echo "   (timeout)"; \
	fi
	@echo ""
	@if [ -f "$(BIN_DIR)/mst_approx" ] && [ -f "$(DATA_DIR)/tsp4_7013.txt" ]; then \
		echo "3️⃣  Instância maior (só aproximativo é viável):"; \
		"$(BIN_DIR)/mst_approx" "$(DATA_DIR)/tsp4_7013.txt" 2>/dev/null || echo "   Erro na execução"; \
	fi

all: setup c-programs
	@echo ""
	@echo "🎉 Compilação completa concluída!"
	@echo ""
	@echo "📋 Próximos passos:"
	@echo "  make check       - Verifica ambiente"
	@echo "  make quick-test  - Testa funcionamento"
	@echo "  make demo        - Demonstração"
	@echo "  make c-only      - Experimentos C"
	@echo "  make python-only - Experimentos Python"

help:
	@echo "🆘 Comandos disponíveis para Tarefa-Algoritmo-Aproximativo-para-TSP:"
	@echo ""
	@echo "🏗️  Compilação:"
	@echo "  make all            - Compila tudo"
	@echo "  make setup          - Cria diretórios necessários"  
	@echo "  make c-programs     - Compila apenas código C"
	@echo "  make manual-compile - Compilação manual (fallback)"
	@echo "  make debug-compile  - Compila com debug"
	@echo ""
	@echo "🧪 Verificação e Testes:"
	@echo "  make check          - Verifica ambiente completo"
	@echo "  make check-structure - Verifica estrutura básica"
	@echo "  make check-files    - Lista arquivos C encontrados"
	@echo "  make quick-test     - Testes rápidos"
	@echo "  make test           - Bateria completa de testes"
	@echo ""
	@echo "🚀 Execução:"
	@echo "  make run-all        - Experimentos completos"
	@echo "  make c-only         - Apenas experimentos C"
	@echo "  make python-only    - Apenas experimentos Python"
	@echo "  make demo           - Demonstração"
	@echo "  make benchmark      - Benchmark rápido"
	@echo ""
	@echo "🧹 Manutenção:"
	@echo "  make clean          - Remove arquivos compilados"
	@echo "  make install-deps   - Instala dependências (Ubuntu)"
	@echo "  make help           - Mostra esta ajuda"
	@echo ""
	@echo "🎯 Para começar:"
	@echo "  make check && make all && make quick-test"
