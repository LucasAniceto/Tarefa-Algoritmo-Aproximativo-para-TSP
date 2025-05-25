import java.util.*;

/**
 * Implementação do algoritmo Branch and Bound para TSP
 * Usa poda para eliminar caminhos não promissores
 */
public class BranchBound {
    
    private TSPInstance instance;
    private TSPResult result;
    
    /**
     * Classe para representar um nó na árvore de busca
     */
    private static class Node {
        int[] path;
        boolean[] visited;
        int currentCost;
        int level;
        int bound;
        
        Node(int nCities) {
            path = new int[nCities];
            visited = new boolean[nCities];
            currentCost = 0;
            level = 0;
            bound = 0;
        }
        
        Node(Node other) {
            path = other.path.clone();
            visited = other.visited.clone();
            currentCost = other.currentCost;
            level = other.level;
            bound = other.bound;
        }
    }
    
    public TSPResult solve(TSPInstance instance) {
        this.instance = instance;
        this.result = new TSPResult("BRANCH_BOUND_JAVA");
        
        System.out.println("Iniciando Branch and Bound para " + instance.nCities + " cidades...");
        
        long startTime = System.nanoTime();
        
        result.bestCost = Integer.MAX_VALUE;
        result.bestPath = new int[instance.nCities];
        
        // Inicializa nó raiz
        Node root = new Node(instance.nCities);
        root.path[0] = 0;  // Começa da cidade 0
        root.visited[0] = true;
        root.level = 1;
        root.bound = calculateBound(root);
        
        // Usa uma pilha para implementar DFS com poda
        Stack<Node> stack = new Stack<>();
        stack.push(root);
        
        while (!stack.isEmpty()) {
            Node current = stack.pop();
            result.nodesExplored++;
            
            // Mostra progresso a cada 10000 nós
            if (result.nodesExplored % 10000 == 0) {
                System.out.printf("Nós explorados: %d, Melhor custo atual: %d%n", 
                                 result.nodesExplored, result.bestCost);
            }
            
            // Se chegou ao final do caminho
            if (current.level == instance.nCities) {
                int finalCost = current.currentCost + 
                               instance.matrix[current.path[current.level - 1]][0];
                
                if (finalCost < result.bestCost) {
                    result.bestCost = finalCost;
                    System.arraycopy(current.path, 0, result.bestPath, 0, instance.nCities);
                    System.out.printf("Nova melhor solução: %d%n", finalCost);
                }
                continue;
            }
            
            // Expande o nó atual
            for (int nextCity = 1; nextCity < instance.nCities; nextCity++) {
                if (!current.visited[nextCity]) {
                    Node child = new Node(current);
                    
                    // Atualiza estado do filho
                    child.path[current.level] = nextCity;
                    child.visited[nextCity] = true;
                    child.level = current.level + 1;
                    child.currentCost = current.currentCost + 
                                       instance.matrix[current.path[current.level - 1]][nextCity];
                    
                    // Calcula bound
                    child.bound = calculateBound(child);
                    
                    // Poda: só continua se o bound for promissor
                    if (child.bound < result.bestCost) {
                        stack.push(child);
                    } else {
                        result.nodesPruned++;
                    }
                }
            }
        }
        
        long endTime = System.nanoTime();
        result.executionTime = (endTime - startTime) / 1_000_000_000.0;
        
        return result;
    }
    
    /**
     * Calcula lower bound usando redução de matriz simplificada
     */
    private int calculateBound(Node node) {
        int bound = node.currentCost;
        
        // Para cada cidade não visitada, adiciona a menor aresta saindo dela
        for (int i = 0; i < instance.nCities; i++) {
            if (!node.visited[i] || i == node.path[node.level - 1]) {
                int minEdge = Integer.MAX_VALUE;
                
                // Encontra menor aresta saindo de i
                for (int j = 0; j < instance.nCities; j++) {
                    if (i != j && (!node.visited[j] || j == 0)) {
                        if (instance.matrix[i][j] < minEdge) {
                            minEdge = instance.matrix[i][j];
                        }
                    }
                }
                
                if (minEdge != Integer.MAX_VALUE) {
                    bound += minEdge;
                }
            }
        }
        
        return bound;
    }
    
    /**
     * Método para testar a classe isoladamente
     */
    public static void main(String[] args) {
        if (args.length != 1) {
            System.out.println("Uso: java BranchBound <arquivo_tsp>");
            return;
        }
        
        try {
            TSPInstance instance = new TSPInstance(args[0]);
            BranchBound bb = new BranchBound();
            TSPResult result = bb.solve(instance);
            result.printResults(instance);
        } catch (Exception e) {
            System.err.println("Erro: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
