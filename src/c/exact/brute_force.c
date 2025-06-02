#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include <time.h>

#define MAX_CITIES 50

// Declaração da função factorial
long long factorial(int n);

typedef struct {
    int **matrix;
    int n_cities;
    int *best_path;
    int best_cost;
    double execution_time;
} TSPData;

// Função para ler a matriz de adjacência do arquivo
TSPData* read_tsp_file(const char* filename) {
    FILE *file = fopen(filename, "r");
    if (!file) {
        printf("Erro ao abrir arquivo %s\n", filename);
        return NULL;
    }
    
    TSPData *data = malloc(sizeof(TSPData));
    
    // Conta o número de cidades lendo a primeira linha
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
                // Libera memória
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

int calculate_path_cost(TSPData *data, int *path) {
    int total_cost = 0;
    for (int i = 0; i < data->n_cities - 1; i++) {
        total_cost += data->matrix[path[i]][path[i + 1]];
    }
    total_cost += data->matrix[path[data->n_cities - 1]][path[0]];
    return total_cost;
}

void swap(int *a, int *b) {
    int temp = *a;
    *a = *b;
    *b = temp;
}

// Algoritmo de Heap para gerar permutações
void generate_permutations(TSPData *data, int *path, int size, int start_index) {
    if (start_index == size) {
        // Reconstrói caminho completo com cidade 0 no início
        int *full_path = malloc(data->n_cities * sizeof(int));
        full_path[0] = 0;
        memcpy(full_path + 1, path, size * sizeof(int));
        
        int cost = calculate_path_cost(data, full_path);
        if (cost < data->best_cost) {
            data->best_cost = cost;
            memcpy(data->best_path, full_path, data->n_cities * sizeof(int));
        }
        
        free(full_path);
        return;
    }
    
    for (int i = start_index; i < size; i++) {
        swap(&path[start_index], &path[i]);
        generate_permutations(data, path, size, start_index + 1);
        swap(&path[start_index], &path[i]); // backtrack
    }
}

// Algoritmo de Força Bruta principal
void solve_tsp_brute_force(TSPData *data) {
    clock_t start_time = clock();
    
    // Fixa a cidade 0 como início
    int *path = malloc(data->n_cities * sizeof(int));
    for (int i = 0; i < data->n_cities; i++) {
        path[i] = i;
    }
    
    printf("Iniciando força bruta para %d cidades...\n", data->n_cities);
    printf("Número de permutações a testar: %lld\n", factorial(data->n_cities - 1));
    
    // Inicializa melhor solução
    data->best_cost = calculate_path_cost(data, path);
    memcpy(data->best_path, path, data->n_cities * sizeof(int));
    
    // Gera permutações começando da cidade 1 (fixa 0)
    if (data->n_cities > 1) {
        generate_permutations(data, path + 1, data->n_cities - 1, 0);
    }
    
    clock_t end_time = clock();
    data->execution_time = ((double)(end_time - start_time)) / CLOCKS_PER_SEC;
    
    free(path);
}

long long factorial(int n) {
    if (n <= 1) return 1;
    long long result = 1;
    for (int i = 2; i <= n; i++) {
        result *= i;
    }
    return result;
}

void print_results(TSPData *data, const char* filename) {
    printf("\n=== RESULTADOS FORÇA BRUTA ===\n");
    printf("Arquivo: %s\n", filename);
    printf("Número de cidades: %d\n", data->n_cities);
    printf("Melhor custo encontrado: %d\n", data->best_cost);
    printf("Tempo de execução: %.6f segundos\n", data->execution_time);
    printf("Melhor caminho: ");
    for (int i = 0; i < data->n_cities; i++) {
        printf("%d ", data->best_path[i]);
    }
    printf("\n");
}

void save_results(TSPData *data, const char* filename, const char* output_file) {
    FILE *file = fopen(output_file, "a");
    if (file) {
        fprintf(file, "%s,%d,%d,%.6f,BRUTE_FORCE_C\n", 
                filename, data->n_cities, data->best_cost, data->execution_time);
        fclose(file);
    }
}

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
        return 1;
    }
    
    TSPData *data = read_tsp_file(argv[1]);
    if (!data) {
        return 1;
    }
    
    if (data->n_cities > 12) {
        printf("AVISO: %d cidades pode demorar muito! Continuar? (s/n): ", data->n_cities);
        char response;
        if (scanf(" %c", &response) != 1) {
            printf("Erro ao ler resposta\n");
            free_tsp_data(data);
            return 0;
        }
        if (response != 's' && response != 'S') {
            printf("Execução cancelada.\n");
            free_tsp_data(data);
            return 0;
        }
    }
    
    solve_tsp_brute_force(data);
    print_results(data, argv[1]);
    save_results(data, argv[1], "../../results/exact_results.txt");
    
    free_tsp_data(data);
    return 0;
}