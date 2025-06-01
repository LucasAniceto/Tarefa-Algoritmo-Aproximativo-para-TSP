#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include <time.h>

#define MAX_CITIES 50

// Declaração antecipada da função factorial
long long factorial(int n);

typedef struct {
    int **matrix;
    int n_cities;
    int *best_path;
    int best_cost;
    double execution_time;
    long long permutations_tested;
} TSPData;

// Função para ler a matriz de adjacência do arquivo
TSPData* read_tsp_file(const char* filename) {
    FILE *file = fopen(filename, "r");
    if (!file) {
        printf("Erro ao abrir arquivo %s\n", filename);
        return NULL;
    }
    
    TSPData *data = malloc(sizeof(TSPData));
    
    // Primeiro, contamos o número de cidades lendo a primeira linha
    char line[10000];
    if (fgets(line, sizeof(line), file) == NULL) {
        printf("Erro ao ler primeira linha\n");
        fclose(file);
        free(data);
        return NULL;
    }
    int count = 0;
    char *token = strtok(line, " \t\n");
    while (token != NULL) {
        count++;
        token = strtok(NULL, " \t\n");
    }
    
    data->n_cities = count;
    data->best_cost = INT_MAX;
    data->permutations_tested = 0;
    
    // Aloca memória para a matriz
    data->matrix = malloc(data->n_cities * sizeof(int*));
    for (int i = 0; i < data->n_cities; i++) {
        data->matrix[i] = malloc(data->n_cities * sizeof(int));
    }
    
    data->best_path = malloc(data->n_cities * sizeof(int));
    
    // Volta ao início do arquivo
    rewind(file);
    
    // Lê a matriz
    for (int i = 0; i < data->n_cities; i++) {
        for (int j = 0; j < data->n_cities; j++) {
            if (fscanf(file, "%d", &data->matrix[i][j]) != 1) {
                printf("Erro ao ler matriz na posição [%d][%d]\n", i, j);
                fclose(file);
                // Libera memória alocada
                for (int k = 0; k <= i; k++) {
                    free(data->matrix[k]);
                }
                free(data->matrix);
                free(data->best_path);
                free(data);
                return NULL;
            }
        }
    }
    
    fclose(file);
    return data;
}

// Função para calcular o custo de um caminho
int calculate_path_cost(TSPData *data, int *path) {
    int total_cost = 0;
    for (int i = 0; i < data->n_cities - 1; i++) {
        total_cost += data->matrix[path[i]][path[i + 1]];
    }
    // Volta ao início
    total_cost += data->matrix[path[data->n_cities - 1]][path[0]];
    return total_cost;
}

// Função para trocar dois elementos
void swap(int *a, int *b) {
    int temp = *a;
    *a = *b;
    *b = temp;
}

// *** MODIFICAÇÃO PRINCIPAL: Gera TODAS as permutações (15!) ***
void generate_all_permutations(TSPData *data, int *path, int size, int start_index) {
    if (start_index == size) {
        data->permutations_tested++;
        
        // Testa TODAS as permutações (incluindo as que não começam com 0)
        int cost = calculate_path_cost(data, path);
        if (cost < data->best_cost) {
            data->best_cost = cost;
            memcpy(data->best_path, path, data->n_cities * sizeof(int));
            printf("Nova melhor solução encontrada: %d (permutação %lld)\n", 
                   cost, data->permutations_tested);
        }
        
        // Mostra progresso a cada 10 milhões de permutações
        if (data->permutations_tested % 10000000 == 0) {
            printf("Progresso: %lld permutações testadas...\n", data->permutations_tested);
        }
        
        return;
    }
    
    for (int i = start_index; i < size; i++) {
        swap(&path[start_index], &path[i]);
        generate_all_permutations(data, path, size, start_index + 1);
        swap(&path[start_index], &path[i]); // backtrack
    }
}

// *** Algoritmo de Força Bruta usando TODAS as permutações (15!) ***
void solve_tsp_brute_force_15_factorial(TSPData *data) {
    clock_t start_time = clock();
    
    // Cria array com TODAS as cidades (0, 1, 2, ..., n-1)
    int *path = malloc(data->n_cities * sizeof(int));
    for (int i = 0; i < data->n_cities; i++) {
        path[i] = i;
    }
    
    printf("Iniciando força bruta COMPLETA para %d cidades...\n", data->n_cities);
    printf("Número de permutações a testar: %lld\n", factorial(data->n_cities));
    printf("⚠️  AVISO: Esta versão testa TODAS as permutações (%d!)\n", data->n_cities);
    printf("⚠️  A versão otimizada testaria apenas %lld permutações\n", factorial(data->n_cities - 1));
    printf("⚠️  Esta versão é %dx mais lenta!\n", data->n_cities);
    
    // Inicializa melhor solução com primeira permutação
    data->best_cost = calculate_path_cost(data, path);
    memcpy(data->best_path, path, data->n_cities * sizeof(int));
    
    // *** MUDANÇA PRINCIPAL: Gera TODAS as permutações (não só as que começam com 0) ***
    generate_all_permutations(data, path, data->n_cities, 0);
    
    clock_t end_time = clock();
    data->execution_time = ((double)(end_time - start_time)) / CLOCKS_PER_SEC;
    
    free(path);
}

// Função auxiliar para calcular fatorial (para estatísticas)
long long factorial(int n) {
    if (n <= 1) return 1;
    long long result = 1;
    for (int i = 2; i <= n; i++) {
        result *= i;
    }
    return result;
}

// Função para imprimir resultados
void print_results(TSPData *data, const char* filename) {
    printf("\n=== RESULTADOS FORÇA BRUTA COMPLETA (15!) ===\n");
    printf("Arquivo: %s\n", filename);
    printf("Número de cidades: %d\n", data->n_cities);
    printf("Melhor custo encontrado: %d\n", data->best_cost);
    printf("Tempo de execução: %.6f segundos\n", data->execution_time);
    printf("Permutações testadas: %lld\n", data->permutations_tested);
    printf("Melhor caminho: ");
    for (int i = 0; i < data->n_cities; i++) {
        printf("%d ", data->best_path[i]);
    }
    printf("\n");
    
    // Comparação com versão otimizada
    long long optimized_perms = factorial(data->n_cities - 1);
    printf("\n=== COMPARAÇÃO ===\n");
    printf("Permutações desta versão (15!): %lld\n", data->permutations_tested);
    printf("Permutações da versão otimizada (14!): %lld\n", optimized_perms);
    printf("Esta versão testou %.1fx mais permutações\n", 
           (double)data->permutations_tested / optimized_perms);
    printf("Ambas encontram o mesmo resultado ótimo!\n");
}

// Função para salvar resultados em arquivo
void save_results(TSPData *data, const char* filename, const char* output_file) {
    FILE *file = fopen(output_file, "a");
    if (file) {
        fprintf(file, "%s,%d,%d,%.6f,BRUTE_FORCE_15_FACTORIAL,%lld\n", 
                filename, data->n_cities, data->best_cost, 
                data->execution_time, data->permutations_tested);
        fclose(file);
    }
}

// Função para liberar memória
void free_tsp_data(TSPData *data) {
    for (int i = 0; i < data->n_cities; i++) {
        free(data->matrix[i]);
    }
    free(data->matrix);
    free(data->best_path);
    free(data);
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        printf("Uso: %s <arquivo_tsp>\n", argv[0]);
        printf("AVISO: Esta versão usa 15! permutações (muito mais lenta)\n");
        return 1;
    }
    
    TSPData *data = read_tsp_file(argv[1]);
    if (!data) {
        return 1;
    }
    
    // Verifica se é viável executar (limite ainda mais restrito)
    if (data->n_cities > 10) {
        printf("⚠️  AVISO CRÍTICO: %d cidades com %d! permutações!\n", 
               data->n_cities, data->n_cities);
        printf("⚠️  Para 15 cidades = 1.307.674.368.000 permutações!\n");
        printf("⚠️  Tempo estimado: 15-18 horas (vs 1h11min da versão otimizada)\n");
        printf("Continuar mesmo assim? (s/n): ");
        char response;
        if (scanf(" %c", &response) != 1) {
            printf("Erro ao ler resposta\n");
            free_tsp_data(data);
            return 0;
        }
        if (response != 's' && response != 'S') {
            printf("Execução cancelada (recomendado!).\n");
            printf("Use a versão otimizada que demora apenas 1h11min!\n");
            free_tsp_data(data);
            return 0;
        }
    }
    
    solve_tsp_brute_force_15_factorial(data);
    print_results(data, argv[1]);
    save_results(data, argv[1], "results/exact_results_15factorial.txt");
    
    free_tsp_data(data);
    return 0;
}