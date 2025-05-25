import java.io.*;
import java.util.*;

/**
 * Representa uma instância do problema TSP
 */
public class TSPInstance {
    public int[][] matrix;
    public int nCities;
    public String filename;
    
    public TSPInstance(String filename) throws IOException {
        this.filename = filename;
        loadFromFile(filename);
    }
    
    private void loadFromFile(String filename) throws IOException {
        BufferedReader br = new BufferedReader(new FileReader(filename));
        
        // Lê primeira linha para contar cidades
        String firstLine = br.readLine();
        if (firstLine == null) {
            br.close();
            throw new IOException("Arquivo vazio");
        }
        
        String[] tokens = firstLine.trim().split("\\s+");
        nCities = tokens.length;
        
        // Inicializa matriz
        matrix = new int[nCities][nCities];
        
        // Preenche primeira linha
        for (int j = 0; j < nCities; j++) {
            matrix[0][j] = Integer.parseInt(tokens[j]);
        }
        
        // Preenche demais linhas
        for (int i = 1; i < nCities; i++) {
            String line = br.readLine();
            if (line == null) {
                br.close();
                throw new IOException("Arquivo incompleto");
            }
            tokens = line.trim().split("\\s+");
            if (tokens.length != nCities) {
                br.close();
                throw new IOException("Linha " + i + " tem tamanho incorreto");
            }
            for (int j = 0; j < nCities; j++) {
                matrix[i][j] = Integer.parseInt(tokens[j]);
            }
        }
        
        br.close();
    }
    
    public int calculatePathCost(int[] path) {
        int totalCost = 0;
        for (int i = 0; i < path.length - 1; i++) {
            totalCost += matrix[path[i]][path[i + 1]];
        }
        // Retorna ao início
        totalCost += matrix[path[path.length - 1]][path[0]];
        return totalCost;
    }
    
    public int getOptimalValue() {
        // Extrai valor ótimo do nome do arquivo
        String name = new File(filename).getName();
        int underscoreIndex = name.lastIndexOf('_');
        int dotIndex = name.lastIndexOf('.');
        
        if (underscoreIndex != -1 && dotIndex != -1 && underscoreIndex < dotIndex) {
            try {
                return Integer.parseInt(name.substring(underscoreIndex + 1, dotIndex));
            } catch (NumberFormatException e) {
                return -1;
            }
        }
        return -1;
    }
}
