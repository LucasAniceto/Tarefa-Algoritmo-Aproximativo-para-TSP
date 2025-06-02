#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include <time.h>
#include <stdbool.h>

#define MAX_CITIES 50

typedef struct {
    int **matrix;
    int n_cities;
    int *approx_path;
    int approx_cost;
    double execution_time;
} TSPData;

typedef struct {
    int u, v, weight;
} Edge;

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
    data->approx_cost = 0;
    
    data->matrix = malloc(data->n_cities * sizeof(int*));
    for (int i = 0; i < data->n_cities; i++) {
        data->matrix[i] = malloc(data->n_cities * sizeof(int));
    }
    data->approx_path = malloc(data->n_cities * sizeof(int));
    
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
                free(data->approx_path);
                free(data);
                return NULL;
            }
        }
    }
    
    fclose(file);
    return data;
}

// Algoritmo de Prim para encontrar MST
int* find_mst_prim(TSPData *data) {
    int *parent = malloc(data->n_cities * sizeof(int));
    int *key = malloc(data->n_cities * sizeof(int));
    bool *in_mst = malloc(data->n_cities * sizeof(bool));
    
    for (int i = 0; i < data->n_cities; i++) {
        key[i] = INT_MAX;
        in_mst[i] = false;
    }
    
    key[0] = 0;
    parent[0] = -1;
    
    for (int count = 0; count < data->n_cities - 1; count++) {
        int min_key = INT_MAX, min_index = -1;
        for (int v = 0; v < data->n_cities; v++) {
            if (!in_mst[v] && key[v] < min_key) {
                min_key = key[v];
                min_index = v;
            }
        }
        
        in_mst[min_index] = true;
        
        for (int v = 0; v < data->n_cities; v++) {
            if (!in_mst[v] && data->matrix[min_index][v] < key[v]) {
                parent[v] = min_index;
                key[v] = data->matrix[min_index][v];
            }
        }
    }
    
    free(key);
    free(in_mst);
    return parent;
}

// Cria lista de adjacência da MST
int** create_mst_adjacency_list(TSPData *data, int *mst_parent) {
    int **adj_list = malloc(data->n_cities * sizeof(int*));
    int *adj_count = calloc(data->n_cities, sizeof(int));
    
    for (int i = 1; i < data->n_cities; i++) {
        adj_count[i]++;
        adj_count[mst_parent[i]]++;
    }
    
    for (int i = 0; i < data->n_cities; i++) {
        adj_list[i] = malloc((adj_count[i] + 1) * sizeof(int));
        adj_list[i][0] = 0;
    }
    
    for (int i = 1; i < data->n_cities; i++) {
        int parent = mst_parent[i];
        
        adj_list[parent][++adj_list[parent][0]] = i;
        adj_list[i][++adj_list[i][0]] = parent;
    }
    
    free(adj_count);
    return adj_list;
}

// DFS para criar tour Euleriano
void dfs_preorder(int **adj_list, int vertex, bool *visited, int *tour, int *tour_index) {
    visited[vertex] = true;
    tour[(*tour_index)++] = vertex;
    
    for (int i = 1; i <= adj_list[vertex][0]; i++) {
        int neighbor = adj_list[vertex][i];
        if (!visited[neighbor]) {
            dfs_preorder(adj_list, neighbor, visited, tour, tour_index);
        }
    }
}

// Algoritmo MST - Aproximação com garantia de 2x o ótimo
void solve_tsp_mst_approximation(TSPData *data) {
    clock_t start_time = clock();
    
    printf("Iniciando algoritmo MST para %d cidades...\n", data->n_cities);
    
    int *mst_parent = find_mst_prim(data);
    int **adj_list = create_mst_adjacency_list(data, mst_parent);
    
    bool *visited = calloc(data->n_cities, sizeof(bool));
    int *tour = malloc(data->n_cities * sizeof(int));
    int tour_index = 0;
    
    dfs_preorder(adj_list, 0, visited, tour, &tour_index);
    
    memcpy(data->approx_path, tour, data->n_cities * sizeof(int));
    
    data->approx_cost = 0;
    for (int i = 0; i < data->n_cities - 1; i++) {
        data->approx_cost += data->matrix[tour[i]][tour[i + 1]];
    }
    data->approx_cost += data->matrix[tour[data->n_cities - 1]][tour[0]];
    
    clock_t end_time = clock();
    data->execution_time = ((double)(end_time - start_time)) / CLOCKS_PER_SEC;
    
    free(mst_parent);
    for (int i = 0; i < data->n_cities; i++) {
        free(adj_list[i]);
    }
    free(adj_list);
    free(visited);
    free(tour);
}

void print_results(TSPData *data, const char* filename) {
    printf("\n=== RESULTADOS MST APROXIMATIVO ===\n");
    printf("Arquivo: %s\n", filename);
    printf("Número de cidades: %d\n", data->n_cities);
    printf("Custo aproximado: %d\n", data->approx_cost);
    printf("Tempo de execução: %.6f segundos\n", data->execution_time);
    printf("Caminho aproximado: ");
    for (int i = 0; i < data->n_cities; i++) {
        printf("%d ", data->approx_path[i]);
    }
    printf("\n");
    
    const char *basename = filename;
    const char *last_slash = strrchr(filename, '/');
    if (last_slash) basename = last_slash + 1;
    
    const char *underscore = strrchr(basename, '_');
    const char *dot = strrchr(basename, '.');
    
    if (underscore && dot && underscore < dot) {
        int optimal = 0;
        int len = dot - underscore - 1;
        char optimal_str[32] = {0};
        if (len > 0 && len < 31) {
            strncpy(optimal_str, underscore + 1, len);
            optimal = atoi(optimal_str);
            
            if (optimal > 0) {
                double ratio = (double)data->approx_cost / optimal;
                printf("Valor ótimo esperado: %d\n", optimal);
                printf("Razão aproximação: %.3f\n", ratio);
                printf("Qualidade: %.1f%% do ótimo\n", ratio * 100);
            }
        }
    }
}

void save_results(TSPData *data, const char* filename, const char* output_file) {
    FILE *file = fopen(output_file, "a");
    if (file) {
        const char *basename = filename;
        const char *last_slash = strrchr(filename, '/');  
        if (last_slash) basename = last_slash + 1;
        
        const char *underscore = strrchr(basename, '_');
        const char *dot = strrchr(basename, '.');
        int optimal = 0;
        
        if (underscore && dot && underscore < dot) {
            int len = dot - underscore - 1;
            char optimal_str[32] = {0};
            if (len > 0 && len < 31) {
                strncpy(optimal_str, underscore + 1, len);
                optimal = atoi(optimal_str);
            }
        }
        
        fprintf(file, "%s,%d,%d,%.6f,MST_APPROX_C,%d,%.3f\n", 
                filename, data->n_cities, data->approx_cost, data->execution_time,
                optimal, optimal > 0 ? (double)data->approx_cost / optimal : 0.0);
        
        fclose(file);
    }
}

void free_tsp_data(TSPData *data) {
    for (int i = 0; i < data->n_cities; i++) {
        free(data->matrix[i]);
    }
    free(data->matrix);
    free(data->approx_path);
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
    
    solve_tsp_mst_approximation(data);
    print_results(data, argv[1]);
    save_results(data, argv[1], "../../results/approximate_results.txt");
    
    free_tsp_data(data);
    return 0;
}