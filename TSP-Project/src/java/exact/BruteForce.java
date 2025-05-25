import java.util.*;

/**
 * Implementação do algoritmo de Força Bruta para TSP
 * Testa todas as permutações possíveis para encontrar a solução ótima
 */
public class BruteForce {
    
    private TSPInstance instance;
    private TSPResult result;
    private long permutationsGenerated;
    
    public TSPResult solve(TSPInstance instance) {
        this.instance = instance;
        this.result = new TSPResult("BRUTE_FORCE_JAVA");
        this.permutationsGenerated = 0;
        
        System.out.println("Iniciando força bruta para " + instance.nCities + " cidades...");
        long expectedPermutations = factorial(instance.nCities - 1);
        System.out.println("Número de permutações a testar: " + expectedPermutations);
        
        long startTime = System.nanoTime();
        
        // Inicializa com primeiro caminho possível
        result.bestCost = Integer.MAX_VALUE;
        result.bestPath = new int[instance.nCities];
        
        // Gera todas as permutações começando da cidade 1 (fixamos cidade 0)
        int[] citiesWithoutFirst = new int[instance.nCities - 1];
        for (int i = 1; i < instance.nCities; i++) {
            citiesWithoutFirst[i - 1] = i;
        }
        
        generatePermutations(citiesWithoutFirst, 0);
        
        long endTime = System.nanoTime();
        result.executionTime = (endTime - startTime) / 1_000_000_000.0;
        result.nodesExplored = permutationsGenerated;
        
        System.out.println("Permutações testadas: " + permutationsGenerated);
        
        return result;
    }
    
    /**
     * Gera todas as permutações usando algoritmo de Heap
     */
    private void generatePermutations(int[] cities, int startIndex) {
        if (startIndex == cities.length - 1) {
            // Testa esta permutação
            testPermutation(cities);
            return;
        }
        
        for (int i = startIndex; i < cities.length; i++) {
            swap(cities, startIndex, i);
            generatePermutations(cities, startIndex + 1);
            swap(cities, startIndex, i); // backtrack
        }
    }
    
    /**
     * Testa uma permutação específica
     */
    private void testPermutation(int[] cities) {
        permutationsGenerated++;
        
        // Constrói caminho completo (começando com cidade 0)
        int[] fullPath = new int[instance.nCities];
        fullPath[0] = 0;
        System.arraycopy(cities, 0, fullPath, 1, cities.length);
        
        // Calcula custo
        int cost = instance.calculatePathCost(fullPath);
        
        // Atualiza melhor solução se necessário
        if (cost < result.bestCost) {
            result.bestCost = cost;
            System.arraycopy(fullPath, 0, result.bestPath, 0, fullPath.length);
            
            // Mostra progresso a cada melhoria
            System.out.printf("Nova melhor solução encontrada: %d (permutação %d)%n", 
                             cost, permutationsGenerated);
        }
        
        // Mostra progresso a cada 1 milhão de permutações
        if (permutationsGenerated % 1_000_000 == 0) {
            System.out.printf("Progresso: %d permutações testadas...%n", permutationsGenerated);
        }
    }
    
    /**
     * Troca dois elementos no array
     */
    private void swap(int[] array, int i, int j) {
        int temp = array[i];
        array[i] = array[j];
        array[j] = temp;
    }
    
    /**
     * Calcula fatorial de um número
     */
    private long factorial(int n) {
        if (n <= 1) return 1;
        long result = 1;
        for (int i = 2; i <= n; i++) {
            result *= i;
        }
        return result;
    }
    
    /**
     * Método para testar a classe isoladamente
     */
    public static void main(String[] args) {
        if (args.length != 1) {
            System.out.println("Uso: java BruteForce <arquivo_tsp>");
            return;
        }
        
        try {
            TSPInstance instance = new TSPInstance(args[0]);
            BruteForce bf = new BruteForce();
            TSPResult result = bf.solve(instance);
            result.printResults(instance);
        } catch (Exception e) {
            System.err.println("Erro: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
