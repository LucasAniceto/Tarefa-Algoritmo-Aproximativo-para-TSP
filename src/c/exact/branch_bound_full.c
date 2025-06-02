#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include <time.h>
#include <stdbool.h>

#define MAX_CITIES 50
#define INF INT_MAX

typedef struct {
    int **matrix;
    int n_cities;
    int *best_path;
    int best_cost;
    double execution_time;
    long long nodes_explored;
    long long nodes_pruned;
} TSPData;

typedef struct {
    int *path;
    bool *visited;
    int current_cost;
    int level;
    int bound;
} Node;

// Função para ler a matriz de adjacência do arquivo
TSPData* read_tsp_file(const char* filename) {
    FILE *file = fopen(filename, "r");
    if (!file) {
        printf("Erro ao abrir arquivo %s\n", filename);
        return NULL;
    }
    
    TSPData *data = malloc(sizeof(TSPData));
    
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
    data->nodes_explored = 0;
    data->nodes_pruned = 0;
    
    data->matrix = malloc(data->n_cities * sizeof(int*));
    for (int i = 0; i < data->n_cities; i++) {
        data->matrix[i] = malloc(data->n_cities * sizeof(int));
    }
    data->best_path = malloc(data->n_cities * sizeof(int));
    
    rewind(file);
    for (int i = 0; i < data->n_cities; i++) {
        for (int j = 0; j < data->n_cities; j++) {
            if (fscanf(file, "%d", &data->matrix[i][j]) != 1) {
                printf("Erro ao ler matriz na posição [%d][%d]\n", i, j);
                fclose(file);
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

// Função de bound SEM OTIMIZAÇÃO
int calculate_bound_unoptimized(TSPData *data, Node *node) {
    int bound = node->current_cost;
    
    for (int i = 0; i < data->n_cities; i++) {
        if (!node->visited[i]) {
            int min_edge = INT_MAX;
            for (int j = 0; j < data->n_cities; j++) {
                if (i != j && data->matrix[i][j] < min_edge) {
                    min_edge = data->matrix[i][j];
                }
            }
            if (min_edge != INT_MAX) {
                bound += min_edge;
            }
        }
    }
    
    return bound;
}

// Função recursiva que testa TODAS as permutações (N!)
void branch_and_bound_recursive_full(TSPData *data, Node *current_node) {
    data->nodes_explored++;
    
    if (data->nodes_explored % 1000000 == 0) {
        printf("Progresso: %lld nós explorados, %lld podados (%.2f%% poda)\n", 
               data->nodes_explored, data->nodes_pruned,
               (double)data->nodes_pruned / (data->nodes_explored + data->nodes_pruned) * 100);
    }
    
    if (current_node->level == data->n_cities) {
        int final_cost = current_node->current_cost + 
                        data->matrix[current_node->path[current_node->level - 1]][current_node->path[0]];
        
        if (final_cost < data->best_cost) {
            data->best_cost = final_cost;
            memcpy(data->best_path, current_node->path, data->n_cities * sizeof(int));
            printf("Nova melhor solução: %d (nó %lld)\n", data->best_cost, data->nodes_explored);
        }
        return;
    }
    
    // SEM OTIMIZAÇÃO: explora TODAS as cidades (0 até n-1)
    for (int i = 0; i < data->n_cities; i++) {
        if (!current_node->visited[i]) {
            Node next_node;
            next_node.path = malloc(data->n_cities * sizeof(int));
            next_node.visited = malloc(data->n_cities * sizeof(bool));
            
            memcpy(next_node.path, current_node->path, data->n_cities * sizeof(int));
            memcpy(next_node.visited, current_node->visited, data->n_cities * sizeof(bool));
            
            next_node.path[current_node->level] = i;
            next_node.visited[i] = true;
            next_node.level = current_node->level + 1;
            
            if (current_node->level == 0) {
                next_node.current_cost = 0;
            } else {
                next_node.current_cost = current_node->current_cost + 
                                       data->matrix[current_node->path[current_node->level - 1]][i];
            }
            
            next_node.bound = calculate_bound_unoptimized(data, &next_node);
            
            if (next_node.bound < data->best_cost) {
                branch_and_bound_recursive_full(data, &next_node);
            } else {
                data->nodes_pruned++;
            }
            
            free(next_node.path);
            free(next_node.visited);
        }
    }
}

// Algoritmo Branch and Bound SEM OTIMIZAÇÃO - usa N! permutações
void solve_tsp_branch_bound_full_factorial(TSPData *data) {
    clock_t start_time = clock();
    
    printf("=== INICIANDO BRANCH AND BOUND N! (SEM OTIMIZAÇÃO) ===\n");
    printf("Número de cidades: %d\n", data->n_cities);
    
    long long factorial = 1;
    for (int i = 2; i <= data->n_cities; i++) {
        factorial *= i;
    }
    printf("Permutações teóricas a explorar: %lld (%d!)\n", factorial, data->n_cities);
    
    long long factorial_optimized = 1;
    for (int i = 2; i <= data->n_cities - 1; i++) {
        factorial_optimized *= i;
    }
    printf("Versão otimizada exploraria: %lld (%d!)\n", factorial_optimized, data->n_cities - 1);
    printf("Esta versão explora %.1fx mais possibilidades!\n", (double)factorial / factorial_optimized);
    
    if (data->n_cities > 10) {
        printf("\n⚠️  AVISO: %d cidades com %d! pode demorar MUITO!\n", data->n_cities, data->n_cities);
        printf("⚠️  Recomenda-se usar timeout ou a versão otimizada.\n");
        printf("Continuar mesmo assim? (s/n): ");
        char response;
        if (scanf(" %c", &response) != 1) {
            printf("Erro ao ler resposta\n");
            return;
        }
        if (response != 's' && response != 'S') {
            printf("Execução cancelada.\n");
            return;
        }
    }
    
    printf("\nIniciando busca...\n");
    
    // Inicializa nó raiz VAZIO (sem fixar cidade)
    Node root;
    root.path = malloc(data->n_cities * sizeof(int));
    root.visited = malloc(data->n_cities * sizeof(bool));
    
    for (int i = 0; i < data->n_cities; i++) {
        root.visited[i] = false;
    }
    root.current_cost = 0;
    root.level = 0;
    root.bound = calculate_bound_unoptimized(data, &root);
    
    branch_and_bound_recursive_full(data, &root);
    
    clock_t end_time = clock();
    data->execution_time = ((double)(end_time - start_time)) / CLOCKS_PER_SEC;
    
    free(root.path);
    free(root.visited);
}

void print_results(TSPData *data, const char* filename) {
    printf("\n=== RESULTADOS BRANCH AND BOUND N! (SEM OTIMIZAÇÃO) ===\n");
    printf("Arquivo: %s\n", filename);
    printf("Número de cidades: %d\n", data->n_cities);
    printf("Melhor custo encontrado: %d\n", data->best_cost);
    printf("Tempo de execução: %.6f segundos\n", data->execution_time);
    printf("Nós explorados: %lld\n", data->nodes_explored);
    printf("Nós podados: %lld\n", data->nodes_pruned);
    printf("Taxa de poda: %.2f%%\n", 
           (double)data->nodes_pruned / (data->nodes_explored + data->nodes_pruned) * 100);
    printf("Melhor caminho: ");
    for (int i = 0; i < data->n_cities; i++) {
        printf("%d ", data->best_path[i]);
    }
    printf("\n");
    
    // Comparação teórica
    long long factorial_full = 1, factorial_opt = 1;
    for (int i = 2; i <= data->n_cities; i++) {
        factorial_full *= i;
    }
    for (int i = 2; i <= data->n_cities - 1; i++) {
        factorial_opt *= i;
    }
    
    printf("\n=== COMPARAÇÃO ===\n");
    printf("Nós explorados nesta versão (n!): %lld\n", data->nodes_explored);
    printf("Nós que versão otimizada exploraria ((n-1)!): %lld\n", factorial_opt);
    printf("Overhead desta versão: %.1fx mais nós\n", 
           (double)data->nodes_explored / factorial_opt);
}

void save_results(TSPData *data, const char* filename, const char* output_file) {
    FILE *file = fopen(output_file, "a");
    if (file) {
        fprintf(file, "%s,%d,%d,%.6f,BRANCH_BOUND_N_FACTORIAL_C,%lld,%lld\n", 
                filename, data->n_cities, data->best_cost, data->execution_time,
                data->nodes_explored, data->nodes_pruned);
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
        printf("AVISO: Esta versão usa n! permutações (sem otimização de cidade fixa)\n");
        return 1;
    }
    
    TSPData *data = read_tsp_file(argv[1]);
    if (!data) {
        return 1;
    }
    
    solve_tsp_branch_bound_full_factorial(data);
    print_results(data, argv[1]);
    save_results(data, argv[1], "../../results/exact_results_n_factorial.txt");
    
    free_tsp_data(data);
    return 0;
}