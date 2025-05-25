import java.io.*;
import java.util.*;

/**
 * Classe principal para resolver o Problema do Caixeiro Viajante
 * Coordena a execução dos diferentes algoritmos
 */
public class TSPSolver {
    
    public static void main(String[] args) {
        if (args.length < 2) {
            System.out.println("Uso: java TSPSolver <algoritmo> <arquivo>");
            System.out.println("Algoritmos disponíveis:");
            System.out.println("  brute-force    - Força bruta");
            System.out.println("  branch-bound   - Branch and Bound");
            System.out.println("  both-exact     - Ambos algoritmos exatos");
            return;
        }
        
        String algorithm = args[0];
        String filename = args[1];
        
        try {
            TSPInstance instance = new TSPInstance(filename);
            
            switch (algorithm.toLowerCase()) {
                case "brute-force":
                    runBruteForce(instance);
                    break;
                case "branch-bound":
                    runBranchBound(instance);
                    break;
                case "both-exact":
                    runBruteForce(instance);
                    runBranchBound(instance);
                    break;
                default:
                    System.out.println("Algoritmo não reconhecido: " + algorithm);
            }
            
        } catch (IOException e) {
            System.err.println("Erro ao ler arquivo: " + e.getMessage());
        }
    }
    
    private static void runBruteForce(TSPInstance instance) {
        if (instance.nCities > 12) {
            System.out.printf("AVISO: %d cidades pode demorar muito! Continuar? (s/n): ", 
                             instance.nCities);
            Scanner scanner = new Scanner(System.in);
            String response = scanner.nextLine();
            if (!response.toLowerCase().startsWith("s")) {
                System.out.println("Execução cancelada.");
                return;
            }
        }
        
        BruteForce bf = new BruteForce();
        TSPResult result = bf.solve(instance);
        result.printResults(instance);
        result.saveToFile(instance, "../../results/exact_results.txt");
    }
    
    private static void runBranchBound(TSPInstance instance) {
        BranchBound bb = new BranchBound();
        TSPResult result = bb.solve(instance);
        result.printResults(instance);
        result.saveToFile(instance, "../../results/exact_results.txt");
    }
}
