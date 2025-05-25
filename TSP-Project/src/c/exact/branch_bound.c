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

// Função para ler a matriz de adjacência (mesma do força bruta)
TSPData* read_tsp_file(const char* filename) {
    FILE *file = fopen(filename, "r");
    if (!file) {
        printf("Erro ao abrir arquivo %s\n", filename);
        return NULL;
    }
    
    TSPData *data = malloc(sizeof(TSPData));
    
    // Conta número de cidades
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
    
    // Aloca memória
    data->matrix = malloc(data->n_cities * sizeof(int*));
    for (int i = 0; i < data->n_cities; i++) {
        data->matrix[i] = malloc(data->n_cities * sizeof(int));
    }
    data->best_path = malloc(data->n_cities * sizeof(int));
    
    // Lê matriz
    rewind(file);
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

// Calcula lower bound usando redução de matriz
int calculate_bound(TSPData *data, Node *node) {
    int bound = node->current_cost;
    
    // Para cada cidade não visitada, adiciona a menor aresta saindo dela
    for (int i = 0; i < data->n_cities; i++) {
        if (!node->visited[i] || i == node->path[node->level - 1]) {
            int min_edge = INT_MAX;
            for (int j = 0; j < data->n_cities; j++) {
                if (i != j && (!node->visited[j] || j == 0)) {
                    if (data->matrix[i][j] < min_edge) {
                        min_edge = data->matrix[i][j];
                    }
                }
            }
            if (min_edge != INT_MAX) {
                bound += min_edge;
            }
        }
    }
    
    return bound;
}

// Função recursiva do Branch and Bound
void branch_and_bound_recursive(TSPData *data, Node *current_node) {
    data->nodes_explored++;
    
    // Se chegamos ao final do caminho
    if (current_node->level == data->n_cities) {
        // Adiciona o custo de volta ao início
        int final_cost = current_node->current_cost + 
                        data->matrix[current_node->path[current_node->level - 1]][0];
        
        if (final_cost < data->best_cost) {
            data->best_cost = final_cost;
            memcpy(data->best_path, current_node->path, data->n_cities * sizeof(int));
        }
        return;
    }
    
    // Explora próximas cidades
    for (int i = 1; i < data->n_cities; i++) {
        if (!current_node->visited[i]) {
            // Cria novo nó
            Node next_node;
            next_node.path = malloc(data->n_cities * sizeof(int));
            next_node.visited = malloc(data->n_cities * sizeof(bool));
            
            // Copia estado atual
            memcpy(next_node.path, current_node->path, data->n_cities * sizeof(int));
            memcpy(next_node.visited, current_node->visited, data->n_cities * sizeof(bool));
            
            // Atualiza novo estado
            next_node.path[current_node->level] = i;
            next_node.visited[i] = true;
            next_node.level = current_node->level + 1;
            next_node.current_cost = current_node->current_cost + 
                                   data->matrix[current_node->path[current_node->level - 1]][i];
            
            // Calcula bound
            next_node.bound = calculate_bound(data, &next_node);
            
            // Poda: se bound >= melhor solução atual, não explora
            if (next_node.bound < data->best_cost) {
                branch_and_bound_recursive(data, &next_node);
            } else {
                data->nodes_pruned++;
            }
            
            free(next_node.path);
            free(next_node.visited);
        }
    }
}

// Algoritmo Branch and Bound principal
void solve_tsp_branch_bound(TSPData *data) {
    clock_t start_time = clock();
    
    printf("Iniciando Branch and Bound para %d cidades...\n", data->n_cities);
    
    // Inicializa nó raiz
    Node root;
    root.path = malloc(data->n_cities * sizeof(int));
    root.visited = malloc(data->n_cities * sizeof(bool));
    
    // Começa da cidade 0
    root.path[0] = 0;
    for (int i = 0; i < data->n_cities; i++) {
        root.visited[i] = false;
    }
    root.visited[0] = true;
    root.current_cost = 0;
    root.level = 1;
    root.bound = calculate_bound(data, &root);
    
    // Inicia busca
    branch_and_bound_recursive(data, &root);
    
    clock_t end_time = clock();
    data->execution_time = ((double)(end_time - start_time)) / CLOCKS_PER_SEC;
    
    free(root.path);
    free(root.visited);
}

// Função para imprimir resultados
void print_results(TSPData *data, const char* filename) {
    printf("\n=== RESULTADOS BRANCH AND BOUND ===\n");
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
}

// Função para salvar resultados
void save_results(TSPData *data, const char* filename, const char* output_file) {
    FILE *file = fopen(output_file, "a");
    if (file) {
        fprintf(file, "%s,%d,%d,%.6f,BRANCH_BOUND_C,%lld,%lld\n", 
                filename, data->n_cities, data->best_cost, data->execution_time,
                data->nodes_explored, data->nodes_pruned);
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
        return 1;
    }
    
    TSPData *data = read_tsp_file(argv[1]);
    if (!data) {
        return 1;
    }
    
    solve_tsp_branch_bound(data);
    print_results(data, argv[1]);
    save_results(data, argv[1], "../../results/exact_results.txt");
    
    free_tsp_data(data);
    return 0;
}
