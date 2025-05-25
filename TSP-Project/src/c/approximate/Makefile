# Makefile para algoritmo aproximativo TSP em C

CC = gcc
CFLAGS = -Wall -Wextra -O3 -std=c99
TARGET_DIR = ../../../bin
DATA_DIR = ../../../data
RESULTS_DIR = ../../../results

# Executável
MST_APPROX = $(TARGET_DIR)/mst_approx

# Arquivo fonte
MST_APPROX_SRC = mst_approx.c

.PHONY: all clean test directories

all: directories $(MST_APPROX)
	@echo "✅ Algoritmo aproximativo compilado com sucesso"

directories:
	@mkdir -p $(TARGET_DIR)
	@mkdir -p $(RESULTS_DIR)

$(MST_APPROX): $(MST_APPROX_SRC)
	@echo "Compilando $(MST_APPROX_SRC)..."
	$(CC) $(CFLAGS) -o $@ $<
	@echo "✅ mst_approx compilado"

# Teste com todos os arquivos
test: $(MST_APPROX)
	@echo "=== Testando MST Aproximativo ==="
	@if [ -f "$(DATA_DIR)/tsp1_253.txt" ]; then \
		$(MST_APPROX) $(DATA_DIR)/tsp1_253.txt; \
	else \
		echo "tsp1_253.txt não encontrado"; \
	fi
	@if [ -f "$(DATA_DIR)/tsp2_1248.txt" ]; then \
		$(MST_APPROX) $(DATA_DIR)/tsp2_1248.txt; \
	else \
		echo "tsp2_1248.txt não encontrado"; \
	fi

# Teste rápido apenas com arquivos pequenos
test-small: $(MST_APPROX)
	@echo "=== Teste rápido MST ==="
	@if [ -f "$(DATA_DIR)/test.txt" ]; then \
		$(MST_APPROX) $(DATA_DIR)/test.txt; \
	else \
		echo "test.txt não encontrado"; \
	fi

clean:
	@echo "Limpando executáveis..."
	@rm -f $(MST_APPROX)
	@rm -f *.o
	@echo "✅ Limpeza concluída"

help:
	@echo "Comandos disponíveis:"
	@echo "  make all        - Compila o executável"
	@echo "  make test       - Testa com vários arquivos"
	@echo "  make test-small - Testa apenas arquivos pequenos"
	@echo "  make clean      - Remove arquivos compilados"
