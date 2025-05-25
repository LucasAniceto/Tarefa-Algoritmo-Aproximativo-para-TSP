# Makefile para algoritmos exatos TSP em C

CC = gcc
CFLAGS = -Wall -Wextra -O3 -std=c99
TARGET_DIR = ../../../bin
DATA_DIR = ../../../data
RESULTS_DIR = ../../../results

# Executáveis
BRUTE_FORCE = $(TARGET_DIR)/brute_force
BRANCH_BOUND = $(TARGET_DIR)/branch_bound

# Arquivos fonte
BRUTE_FORCE_SRC = brute_force.c
BRANCH_BOUND_SRC = branch_bound.c

.PHONY: all clean test directories

all: directories $(BRUTE_FORCE) $(BRANCH_BOUND)
	@echo "✅ Algoritmos exatos compilados com sucesso"

directories:
	@mkdir -p $(TARGET_DIR)
	@mkdir -p $(RESULTS_DIR)

$(BRUTE_FORCE): $(BRUTE_FORCE_SRC)
	@echo "Compilando $(BRUTE_FORCE_SRC)..."
	$(CC) $(CFLAGS) -o $@ $<
	@echo "✅ brute_force compilado"

$(BRANCH_BOUND): $(BRANCH_BOUND_SRC)
	@echo "Compilando $(BRANCH_BOUND_SRC)..."
	$(CC) $(CFLAGS) -o $@ $<
	@echo "✅ branch_bound compilado"

# Testes com arquivos pequenos
test-small: $(BRUTE_FORCE)
	@echo "=== Testando Força Bruta com arquivos pequenos ==="
	@if [ -f "$(DATA_DIR)/tsp2_1248.txt" ]; then \
		$(BRUTE_FORCE) $(DATA_DIR)/tsp2_1248.txt; \
	else \
		echo "Arquivo tsp2_1248.txt não encontrado"; \
	fi
	@if [ -f "$(DATA_DIR)/test.txt" ]; then \
		$(BRUTE_FORCE) $(DATA_DIR)/test.txt; \
	else \
		echo "Arquivo test.txt não encontrado"; \
	fi

# Teste completo (cuidado com arquivos grandes!)
test-all: $(BRUTE_FORCE) $(BRANCH_BOUND)
	@echo "=== Executando todos os testes ==="
	@echo "Força Bruta:"
	-timeout 300 $(BRUTE_FORCE) $(DATA_DIR)/tsp2_1248.txt 2>/dev/null || echo "Timeout ou erro"
	-timeout 300 $(BRUTE_FORCE) $(DATA_DIR)/tsp1_253.txt 2>/dev/null || echo "Timeout ou erro"
	@echo "Branch and Bound:"
	-timeout 300 $(BRANCH_BOUND) $(DATA_DIR)/tsp2_1248.txt 2>/dev/null || echo "Timeout ou erro"
	-timeout 300 $(BRANCH_BOUND) $(DATA_DIR)/tsp1_253.txt 2>/dev/null || echo "Timeout ou erro"

clean:
	@echo "Limpando executáveis..."
	@rm -f $(BRUTE_FORCE) $(BRANCH_BOUND)
	@rm -f *.o
	@echo "✅ Limpeza concluída"

help:
	@echo "Comandos disponíveis:"
	@echo "  make all        - Compila todos os executáveis"
	@echo "  make test-small - Testa apenas arquivos pequenos"
	@echo "  make test-all   - Executa todos os testes (pode demorar!)"
	@echo "  make clean      - Remove arquivos compilados"
	@echo "  make help       - Mostra esta ajuda"
