#!/bin/bash

echo "🔍 === DEBUG - VERIFICAÇÃO DE OUTPUTS TSP ==="
echo "   Testa apenas 1 arquivo com 1 algoritmo para debug rápido"
echo ""

# Cria diretório results se não existir
mkdir -p results

# Arquivo mais simples para teste
TEST_FILE="tsp2_1248.txt"
OPTIMAL=1248

echo "🧪 Testando com $TEST_FILE (6 cidades, ótimo=$OPTIMAL)"
echo ""

# Verifica se arquivo existe
if [[ ! -f "data/$TEST_FILE" ]]; then
    echo "❌ Arquivo data/$TEST_FILE não encontrado"
    echo "📁 Arquivos disponíveis em data/:"
    ls -la data/tsp*.txt 2>/dev/null || echo "Nenhum arquivo TSP encontrado"
    exit 1
fi

# Testa MST Aproximativo C
echo "🔥 Testando MST Aproximativo C:"
if [[ -f "bin/mst_approx" ]]; then
    echo "  📝 Executando: ./bin/mst_approx data/$TEST_FILE"
    echo "  📤 Output completo:"
    echo "  ┌─────────────────────────────────────────────"
    ./bin/mst_approx "data/$TEST_FILE"
    exit_code=$?
    echo "  └─────────────────────────────────────────────"
    echo "  🔍 Exit code: $exit_code"
    
    if [[ $exit_code -eq 0 ]]; then
        echo "  ✅ Execução bem-sucedida"
    else
        echo "  ❌ Erro na execução"
    fi
else
    echo "  ❌ Executável bin/mst_approx não encontrado"
    echo "  💡 Execute: make all"
fi

echo ""
echo "🔍 Verificando arquivos de resultado gerados:"

# Verifica approximate_results.txt
if [[ -f "results/approximate_results.txt" ]]; then
    echo "  ✅ results/approximate_results.txt existe"
    echo "  📄 Conteúdo:"
    echo "  ┌─────────────────────────────────────────────"
    cat results/approximate_results.txt | sed 's/^/  │ /'
    echo "  └─────────────────────────────────────────────"
    
    # Verifica se contém o arquivo testado
    if grep -q "$TEST_FILE" results/approximate_results.txt; then
        echo "  ✅ Resultado para $TEST_FILE encontrado no arquivo"
    else
        echo "  ⚠️ Resultado para $TEST_FILE NÃO encontrado no arquivo"
    fi
else
    echo "  ❌ results/approximate_results.txt NÃO existe"
fi

echo ""
echo "🔍 Verificando estrutura de diretórios:"
echo "📁 Estrutura atual:"
echo "  $(pwd)"
echo "  ├── data/"
ls -la data/tsp*.txt 2>/dev/null | sed 's/^/  │   /' || echo "  │   (nenhum arquivo TSP)"
echo "  ├── bin/"
ls -la bin/ 2>/dev/null | sed 's/^/  │   /' || echo "  │   (vazio)"
echo "  └── results/"
ls -la results/ 2>/dev/null | sed 's/^/  │   /' || echo "  │   (vazio)"

echo ""
echo "💡 COMANDOS ÚTEIS PARA DEBUG:"
echo "  1. Compilar tudo:           make all"
echo "  2. Testar Python:           python3 src/python/approximate/mst_algorithm.py data/$TEST_FILE"
echo "  3. Verificar executáveis:   ls -la bin/"
echo "  4. Limpar e recompilar:     make clean && make all"
echo "  5. Ver últimos resultados:  tail -5 results/*.txt"

echo ""
echo "🏁 Debug concluído!"
