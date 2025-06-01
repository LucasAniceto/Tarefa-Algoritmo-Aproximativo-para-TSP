#!/bin/bash

echo "🚀 === COMPARAÇÃO SIMPLES DE LINGUAGENS - TSP ==="
echo "   🎯 Foco em algoritmos RÁPIDOS para verificação de output"
echo ""

# Criar arquivo de resultados
mkdir -p results
echo "Arquivo,Linguagem,Algoritmo,Cidades,Custo,Tempo(s),Tipo" > results/comparacao_simples.csv

# Apenas arquivos pequenos e médios para teste rápido
files=("tsp2_1248.txt" "tsp1_253.txt" "tsp3_1194.txt")
cities=(6 11 15)
optimal=(1248 253 1194)

echo "📋 Testando arquivos: ${files[@]}"
echo "🏁 Algoritmos: MST Aproximativo (C e Python) + Força Bruta (C) apenas para arquivos pequenos"
echo ""

for i in "${!files[@]}"; do
    file=${files[$i]}
    n=${cities[$i]}
    opt=${optimal[$i]}
    
    echo "🧪 === TESTANDO $file ($n cidades, ótimo=$opt) ==="
    echo ""
    
    # 1. MST Aproximativo C (sempre rápido)
    echo "🔥 1. MST Aproximativo C:"
    if [[ -f "bin/mst_approx" ]]; then
        start_time=$(date +%s.%N)
        output=$(./bin/mst_approx "data/$file" 2>&1)
        end_time=$(date +%s.%N)
        execution_time=$(echo "$end_time - $start_time" | bc -l)
        
        if [[ $? -eq 0 ]]; then
            cost=$(echo "$output" | grep "Custo aproximado:" | awk '{print $3}')
            if [[ -n "$cost" ]]; then
                ratio=$(echo "scale=3; $cost / $opt" | bc -l)
                echo "  ✅ Custo: $cost, Tempo: ${execution_time}s, Razão: $ratio"
                echo "$file,C,MST_APPROX,$n,$cost,$execution_time,APPROX" >> results/comparacao_simples.csv
            else
                echo "  ⚠️ Não foi possível extrair custo do output"
            fi
        else
            echo "  ❌ Erro na execução"
        fi
    else
        echo "  ❌ Executável bin/mst_approx não encontrado"
    fi
    
    # 2. MST Aproximativo Python (sempre rápido)
    echo "🐍 2. MST Aproximativo Python:"
    if [[ -f "src/python/approximate/mst_algorithm.py" ]]; then
        start_time=$(date +%s.%N)
        output=$(python3 src/python/approximate/mst_algorithm.py "data/$file" 2>&1)
        end_time=$(date +%s.%N)
        execution_time=$(echo "$end_time - $start_time" | bc -l)
        
        if [[ $? -eq 0 ]]; then
            cost=$(echo "$output" | grep "Custo aproximado:" | awk '{print $3}')
            if [[ -n "$cost" ]]; then
                ratio=$(echo "scale=3; $cost / $opt" | bc -l)
                echo "  ✅ Custo: $cost, Tempo: ${execution_time}s, Razão: $ratio"
                echo "$file,Python,MST_APPROX,$n,$cost,$execution_time,APPROX" >> results/comparacao_simples.csv
            else
                echo "  ⚠️ Não foi possível extrair custo do output"
            fi
        else
            echo "  ❌ Erro na execução"
        fi
    else
        echo "  ❌ Script src/python/approximate/mst_algorithm.py não encontrado"
    fi
    
    # 3. Força Bruta C (apenas para arquivos muito pequenos)
    if [[ $n -le 11 ]]; then
        echo "🔥 3. Força Bruta C (só para arquivos pequenos):"
        if [[ -f "bin/brute_force" ]]; then
            start_time=$(date +%s.%N)
            
            # Timeout de 60 segundos para segurança
            timeout 60 ./bin/brute_force "data/$file" > /tmp/brute_output.txt 2>&1
            exit_code=$?
            
            end_time=$(date +%s.%N)
            execution_time=$(echo "$end_time - $start_time" | bc -l)
            
            if [[ $exit_code -eq 0 ]]; then
                cost=$(grep "Melhor custo encontrado:" /tmp/brute_output.txt | awk '{print $4}')
                if [[ -n "$cost" ]]; then
                    echo "  ✅ Custo: $cost, Tempo: ${execution_time}s"
                    echo "$file,C,BRUTE_FORCE,$n,$cost,$execution_time,EXACT" >> results/comparacao_simples.csv
                else
                    echo "  ⚠️ Não foi possível extrair custo do output"
                fi
            elif [[ $exit_code -eq 124 ]]; then
                echo "  ⏱️ Timeout (60s)"
                echo "$file,C,BRUTE_FORCE,$n,TIMEOUT,$execution_time,EXACT" >> results/comparacao_simples.csv
            else
                echo "  ❌ Erro na execução"
            fi
            
            rm -f /tmp/brute_output.txt
        else
            echo "  ❌ Executável bin/brute_force não encontrado"
        fi
    else
        echo "  ⏩ Pulando Força Bruta para $n cidades (muito lento)"
    fi
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
done

echo "📊 === RESULTADOS FINAIS ==="
echo ""

if [[ -f "results/comparacao_simples.csv" ]]; then
    echo "✅ Arquivo de resultados: results/comparacao_simples.csv"
    echo ""
    echo "📋 Tabela de Comparação:"
    if command -v column &> /dev/null; then
        column -t -s',' results/comparacao_simples.csv
    else
        cat results/comparacao_simples.csv
    fi
    echo ""
    
    # Análise básica
    echo "📈 === ANÁLISE RÁPIDA ==="
    echo ""
    
    # Verifica se existem resultados para comparar
    echo "🔍 Verificando outputs salvos em results/:"
    if [[ -f "results/approximate_results.txt" ]]; then
        echo "  ✅ results/approximate_results.txt existe"
        echo "  📄 Últimas 3 linhas:"
        tail -3 results/approximate_results.txt | sed 's/^/    /'
    else
        echo "  ❌ results/approximate_results.txt NÃO existe"
    fi
    
    if [[ -f "results/exact_results.txt" ]]; then
        echo "  ✅ results/exact_results.txt existe"
        echo "  📄 Últimas 3 linhas:"
        tail -3 results/exact_results.txt | sed 's/^/    /'
    else
        echo "  ❌ results/exact_results.txt NÃO existe"
    fi
    
    echo ""
    echo "🎯 Comparação de qualidade dos algoritmos aproximativos:"
    
    # Para cada arquivo, compara resultados C vs Python
    for file in "${files[@]}"; do
        echo ""
        echo "📊 $file:"
        
        c_line=$(grep "$file,C,MST_APPROX" results/comparacao_simples.csv 2>/dev/null)
        python_line=$(grep "$file,Python,MST_APPROX" results/comparacao_simples.csv 2>/dev/null)
        
        if [[ -n "$c_line" && -n "$python_line" ]]; then
            c_cost=$(echo "$c_line" | cut -d',' -f5)
            c_time=$(echo "$c_line" | cut -d',' -f6)
            python_cost=$(echo "$python_line" | cut -d',' -f5)
            python_time=$(echo "$python_line" | cut -d',' -f6)
            
            echo "  C:      Custo=$c_cost, Tempo=${c_time}s"
            echo "  Python: Custo=$python_cost, Tempo=${python_time}s"
            
            # Compara custos
            if [[ "$c_cost" == "$python_cost" ]]; then
                echo "  🎯 Custos IDÊNTICOS (algoritmo determinístico)"
            else
                echo "  ⚠️ Custos DIFERENTES (verificar implementação)"
            fi
            
            # Compara tempos (C deveria ser mais rápido)
            if (( $(echo "$c_time < $python_time" | bc -l) )); then
                speedup=$(echo "scale=2; $python_time / $c_time" | bc -l)
                echo "  🚀 C é ${speedup}x mais rápido que Python"
            fi
        else
            echo "  ❌ Dados incompletos para comparação"
        fi
    done
    
else
    echo "❌ Arquivo de resultados não foi gerado"
fi

echo ""
echo "🏆 === TESTE SIMPLES CONCLUÍDO ==="
echo "🎯 Resultados salvos em: results/comparacao_simples.csv"
echo ""
echo "💡 PRÓXIMOS PASSOS:"
echo "   1. Verificar se outputs estão sendo salvos corretamente em results/"
echo "   2. Se tudo estiver OK, rodar o script completo: ./compare_languages.sh"
echo "   3. Verificar se todos os executáveis foram compilados: make all"
