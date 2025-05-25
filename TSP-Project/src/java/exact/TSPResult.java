import java.io.*;

/**
 * Armazena resultado de um algoritmo TSP
 */
public class TSPResult {
    public int[] bestPath;
    public int bestCost;
    public double executionTime;
    public String algorithm;
    public long nodesExplored;
    public long nodesPruned;
    
    public TSPResult(String algorithm) {
        this.algorithm = algorithm;
        this.nodesExplored = 0;
        this.nodesPruned = 0;
        this.bestCost = Integer.MAX_VALUE;
    }
    
    public void printResults(TSPInstance instance) {
        System.out.println("\n=== RESULTADOS " + algorithm + " ===");
        System.out.println("Arquivo: " + instance.filename);
        System.out.println("Número de cidades: " + instance.nCities);
        System.out.println("Melhor custo: " + bestCost);
        System.out.printf("Tempo de execução: %.6f segundos%n", executionTime);
        
        if (nodesExplored > 0) {
            System.out.println("Nós explorados: " + nodesExplored);
            System.out.println("Nós podados: " + nodesPruned);
            if (nodesExplored + nodesPruned > 0) {
                double pruningRate = (double) nodesPruned / (nodesExplored + nodesPruned) * 100;
                System.out.printf("Taxa de poda: %.2f%%%n", pruningRate);
            }
        }
        
        System.out.print("Melhor caminho: ");
        if (bestPath != null) {
            for (int city : bestPath) {
                System.out.print(city + " ");
            }
        }
        System.out.println();
        
        int optimal = instance.getOptimalValue();
        if (optimal > 0) {
            double ratio = (double) bestCost / optimal;
            System.out.println("Valor ótimo esperado: " + optimal);
            System.out.printf("Razão de aproximação: %.3f%n", ratio);
            System.out.printf("Qualidade: %.1f%% do ótimo%n", ratio * 100);
        }
    }
    
    public void saveToFile(TSPInstance instance, String outputFile) {
        try (PrintWriter pw = new PrintWriter(new FileWriter(outputFile, true))) {
            int optimal = instance.getOptimalValue();
            double ratio = optimal > 0 ? (double) bestCost / optimal : 0.0;
            
            pw.printf("%s,%d,%d,%.6f,%s,%d,%.3f,%d,%d%n",
                instance.filename, instance.nCities, bestCost, executionTime,
                algorithm, optimal, ratio, nodesExplored, nodesPruned);
        } catch (IOException e) {
            System.err.println("Erro ao salvar resultados: " + e.getMessage());
        }
    }
}
