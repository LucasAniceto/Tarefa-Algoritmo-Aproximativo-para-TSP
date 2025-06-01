#!/bin/bash

echo "🚀 === COMPARAÇÃO DE LINGUAGENS - ALGORITMOS TSP ==="
echo ""

# Criar arquivo de resultados
mkdir -p results
echo "Arquivo,Linguagem,Algoritmo,Cidades,Custo,Tempo(s),Tipo" > results/comparacao_linguagens.csv

# Arquivos TSP com estratégias específicas
echo "🎯 ESTRATÉGIA INTELIGENTE POR ARQUIVO:"
echo "   ✅ tsp2_1248.txt (6 cidades) = Exatos + Aproximativos"
echo "   ✅ tsp1_253.txt (11 cidades) = Exatos + Aproximativos"
echo "   ⚠️ tsp3_1194.txt (15 cidades) = C SEM timeout, Java/Python COM timeout + Aproximativos"
echo "   🌳 tsp4_7013.txt (44 cidades) = APENAS Aproximativos"
echo "   🌳 tsp5_27603.txt (29 cidades) = APENAS Aproximativos"
echo ""

# Arquivos para testar
files=("tsp2_1248.txt" "tsp1_253.txt" "tsp3_1194.txt" "tsp4_7013.txt" "tsp5_27603.txt")
cities=(6 11 15 44 29)
optimal=(1248 253 1194 7013 27603)
strategies=("full_exact" "full_exact" "mixed_exact" "approx_only" "approx_only")

echo "📋 Testando arquivos: ${files[@]}"
echo "🏁 Executando algoritmos conforme estratégia de cada arquivo"
echo ""

for i in "${!files[@]}"; do
    file=${files[$i]}
    n=${cities[$i]}
    opt=${optimal[$i]}
    strategy=${strategies[$i]}
    
    echo "🧪 === TESTANDO $file ($n cidades, ótimo=$opt, estratégia=$strategy) ==="
    echo ""
    
    if [[ "$strategy" == "full_exact" ]]; then
        # ARQUIVOS PEQUENOS (6 e 11 cidades) - Todos os algoritmos exatos + aproximativos
        echo "🎯 Rodando TODOS os algoritmos (exatos + aproximativos)"
        echo ""
        
        # === ALGORITMOS EXATOS ===
        echo "🔥 === ALGORITMOS EXATOS ==="
        
        # 1. Força Bruta C (timeout padrão)
        echo "🔥 1. Força Bruta C:"
        if [[ -f "bin/brute_force" ]]; then
            output=$(timeout 300 ./bin/brute_force "data/$file" 2>&1)
            if [[ $? -eq 0 ]]; then
                cost=$(echo "$output" | grep "Melhor custo encontrado:" | awk '{print $4}')
                time_c=$(echo "$output" | grep "Tempo de execução:" | awk '{print $4}')
                echo "  ✅ Custo: $cost, Tempo: ${time_c}s"
                echo "$file,C,BRUTE_FORCE,$n,$cost,$time_c,EXACT" >> results/comparacao_linguagens.csv
            else
                echo "  ⏱️ Timeout C (5min)"
            fi
        else
            echo "  ❌ Executável não encontrado: bin/brute_force"
        fi
        
        # 2. Força Bruta Java
        echo "☕ 2. Força Bruta Java:"
        if [[ -f "src/java/exact/BruteForce.class" ]]; then
            cd src/java/exact
            output=$(timeout 300 java BruteForce "../../../data/$file" 2>&1)
            if [[ $? -eq 0 ]]; then
                cost=$(echo "$output" | grep "Melhor custo:" | awk '{print $3}')
                time_java=$(echo "$output" | grep "Tempo de execução:" | awk '{print $4}')
                echo "  ✅ Custo: $cost, Tempo: ${time_java}s"
                echo "$file,Java,BRUTE_FORCE,$n,$cost,$time_java,EXACT" >> ../../../results/comparacao_linguagens.csv
            else
                echo "  ⏱️ Timeout Java (5min)"
            fi
            cd ../../..
        else
            echo "  ❌ Classe não encontrada: src/java/exact/BruteForce.class"
        fi
        
        # 3. Força Bruta Python
        echo "🐍 3. Força Bruta Python:"
        if [[ -f "src/python/exact/brute_force_python.py" ]]; then
            output=$(timeout 300 python3 src/python/exact/brute_force_python.py "data/$file" 2>&1)
            if [[ $? -eq 0 ]]; then
                cost=$(echo "$output" | grep "Melhor custo encontrado:" | awk '{print $4}')
                time_python=$(echo "$output" | grep "Tempo de execução:" | awk '{print $4}')
                echo "  ✅ Custo: $cost, Tempo: ${time_python}s"
                echo "$file,Python,BRUTE_FORCE,$n,$cost,$time_python,EXACT" >> results/comparacao_linguagens.csv
            else
                echo "  ⏱️ Timeout Python (5min)"
            fi
        else
            echo "  ❌ Script não encontrado: src/python/exact/brute_force_python.py"
        fi
        
        # 4. Branch & Bound Java
        echo "🌳 4. Branch & Bound Java:"
        if [[ -f "src/java/exact/BranchBound.class" ]]; then
            cd src/java/exact
            output=$(timeout 300 java BranchBound "../../../data/$file" 2>&1)
            if [[ $? -eq 0 ]]; then
                cost=$(echo "$output" | grep "Melhor custo:" | awk '{print $3}')
                time_bb=$(echo "$output" | grep "Tempo de execução:" | awk '{print $4}')
                pruned=$(echo "$output" | grep "Nós podados:" | awk '{print $3}')
                echo "  ✅ Custo: $cost, Tempo: ${time_bb}s, Podados: $pruned"
                echo "$file,Java,BRANCH_BOUND,$n,$cost,$time_bb,EXACT" >> ../../../results/comparacao_linguagens.csv
            else
                echo "  ⏱️ Timeout Branch & Bound (5min)"
            fi
            cd ../../..
        else
            echo "  ❌ Classe não encontrada: src/java/exact/BranchBound.class"
        fi
        
        echo ""
        echo "🌳 === ALGORITMOS APROXIMATIVOS ==="
        
        # 5. MST C
        echo "🔥 5. MST Aproximativo C:"
        if [[ -f "bin/mst_approx" ]]; then
            output=$(./bin/mst_approx "data/$file" 2>&1)
            cost=$(echo "$output" | grep "Custo aproximado:" | awk '{print $3}')
            time_c=$(echo "$output" | grep "Tempo de execução:" | awk '{print $4}')
            if [[ -n "$cost" && -n "$time_c" ]]; then
                ratio=$(echo "scale=3; $cost / $opt" | bc -l)
                echo "  ✅ Custo: $cost, Tempo: ${time_c}s, Razão: $ratio"
                echo "$file,C,MST_APPROX,$n,$cost,$time_c,APPROX" >> results/comparacao_linguagens.csv
            else
                echo "  ❌ Erro na execução"
            fi
        else
            echo "  ❌ Executável não encontrado: bin/mst_approx"
        fi
        
        # 6. MST Python
        echo "🐍 6. MST Aproximativo Python:"
        if [[ -f "src/python/approximate/mst_algorithm.py" ]]; then
            output=$(python3 src/python/approximate/mst_algorithm.py "data/$file" 2>&1)
            cost=$(echo "$output" | grep "Custo aproximado:" | awk '{print $3}')
            time_python=$(echo "$output" | grep "Tempo de execução:" | awk '{print $4}')
            if [[ -n "$cost" && -n "$time_python" ]]; then
                ratio=$(echo "scale=3; $cost / $opt" | bc -l)
                echo "  ✅ Custo: $cost, Tempo: ${time_python}s, Razão: $ratio"
                echo "$file,Python,MST_APPROX,$n,$cost,$time_python,APPROX" >> results/comparacao_linguagens.csv
            else
                echo "  ❌ Erro na execução"
            fi
        else
            echo "  ❌ Script não encontrado: src/python/approximate/mst_algorithm.py"
        fi
        
    elif [[ "$strategy" == "mixed_exact" ]]; then
        # ARQUIVO MÉDIO (15 cidades) - C sem timeout, Java/Python com timeout + aproximativos
        echo "⚠️ Rodando EXATOS (C sem timeout, Java/Python com timeout) + APROXIMATIVOS"
        echo ""
        
        # === ALGORITMOS EXATOS ===
        echo "🔥 === ALGORITMOS EXATOS ==="
        
        # 1. Força Bruta C (SEM TIMEOUT - pode demorar muito!)
        echo "🔥 1. Força Bruta C (SEM TIMEOUT - pode demorar horas!):"
        if [[ -f "bin/brute_force" ]]; then
            echo "  ⏳ Iniciando execução sem timeout..."
            start_time=$(date +%s)
            output=$(./bin/brute_force "data/$file" 2>&1)
            end_time=$(date +%s)
            elapsed_time=$((end_time - start_time))
            
            if [[ $? -eq 0 ]]; then
                cost=$(echo "$output" | grep "Melhor custo encontrado:" | awk '{print $4}')
                time_c=$(echo "$output" | grep "Tempo de execução:" | awk '{print $4}')
                echo "  ✅ Custo: $cost, Tempo: ${time_c}s (Tempo real: ${elapsed_time}s)"
                echo "$file,C,BRUTE_FORCE,$n,$cost,$time_c,EXACT" >> results/comparacao_linguagens.csv
            else
                echo "  ❌ Erro na execução após ${elapsed_time}s"
            fi
        else
            echo "  ❌ Executável não encontrado: bin/brute_force"
        fi
        
        # 2. Força Bruta Java (COM TIMEOUT de 30 minutos)
        echo "☕ 2. Força Bruta Java (timeout 30min):"
        if [[ -f "src/java/exact/BruteForce.class" ]]; then
            cd src/java/exact
            output=$(timeout 1800 java BruteForce "../../../data/$file" 2>&1)
            if [[ $? -eq 0 ]]; then
                cost=$(echo "$output" | grep "Melhor custo:" | awk '{print $3}')
                time_java=$(echo "$output" | grep "Tempo de execução:" | awk '{print $4}')
                echo "  ✅ Custo: $cost, Tempo: ${time_java}s"
                echo "$file,Java,BRUTE_FORCE,$n,$cost,$time_java,EXACT" >> ../../../results/comparacao_linguagens.csv
            else
                echo "  ⏱️ Timeout Java (30min)"
            fi
            cd ../../..
        else
            echo "  ❌ Classe não encontrada: src/java/exact/BruteForce.class"
        fi
        
        # 3. Força Bruta Python (COM TIMEOUT de 30 minutos)
        echo "🐍 3. Força Bruta Python (timeout 30min):"
        if [[ -f "src/python/exact/brute_force_python.py" ]]; then
            output=$(timeout 1800 python3 src/python/exact/brute_force_python.py "data/$file" 2>&1)
            if [[ $? -eq 0 ]]; then
                cost=$(echo "$output" | grep "Melhor custo encontrado:" | awk '{print $4}')
                time_python=$(echo "$output" | grep "Tempo de execução:" | awk '{print $4}')
                echo "  ✅ Custo: $cost, Tempo: ${time_python}s"
                echo "$file,Python,BRUTE_FORCE,$n,$cost,$time_python,EXACT" >> results/comparacao_linguagens.csv
            else
                echo "  ⏱️ Timeout Python (30min)"
            fi
        else
            echo "  ❌ Script não encontrado: src/python/exact/brute_force_python.py"
        fi
        
        # 4. Branch & Bound Java (COM TIMEOUT de 30 minutos)
        echo "🌳 4. Branch & Bound Java (timeout 30min):"
        if [[ -f "src/java/exact/BranchBound.class" ]]; then
            cd src/java/exact
            output=$(timeout 1800 java BranchBound "../../../data/$file" 2>&1)
            if [[ $? -eq 0 ]]; then
                cost=$(echo "$output" | grep "Melhor custo:" | awk '{print $3}')
                time_bb=$(echo "$output" | grep "Tempo de execução:" | awk '{print $4}')
                pruned=$(echo "$output" | grep "Nós podados:" | awk '{print $3}')
                echo "  ✅ Custo: $cost, Tempo: ${time_bb}s, Podados: $pruned"
                echo "$file,Java,BRANCH_BOUND,$n,$cost,$time_bb,EXACT" >> ../../../results/comparacao_linguagens.csv
            else
                echo "  ⏱️ Timeout Branch & Bound (30min)"
            fi
            cd ../../..
        else
            echo "  ❌ Classe não encontrada: src/java/exact/BranchBound.class"
        fi
        
        echo ""
        echo "🌳 === ALGORITMOS APROXIMATIVOS ==="
        
        # 5. MST C
        echo "🔥 5. MST Aproximativo C:"
        if [[ -f "bin/mst_approx" ]]; then
            output=$(./bin/mst_approx "data/$file" 2>&1)
            cost=$(echo "$output" | grep "Custo aproximado:" | awk '{print $3}')
            time_c=$(echo "$output" | grep "Tempo de execução:" | awk '{print $4}')
            if [[ -n "$cost" && -n "$time_c" ]]; then
                ratio=$(echo "scale=3; $cost / $opt" | bc -l)
                echo "  ✅ Custo: $cost, Tempo: ${time_c}s, Razão: $ratio"
                echo "$file,C,MST_APPROX,$n,$cost,$time_c,APPROX" >> results/comparacao_linguagens.csv
            else
                echo "  ❌ Erro na execução"
            fi
        else
            echo "  ❌ Executável não encontrado: bin/mst_approx"
        fi
        
        # 6. MST Python
        echo "🐍 6. MST Aproximativo Python:"
        if [[ -f "src/python/approximate/mst_algorithm.py" ]]; then
            output=$(python3 src/python/approximate/mst_algorithm.py "data/$file" 2>&1)
            cost=$(echo "$output" | grep "Custo aproximado:" | awk '{print $3}')
            time_python=$(echo "$output" | grep "Tempo de execução:" | awk '{print $4}')
            if [[ -n "$cost" && -n "$time_python" ]]; then
                ratio=$(echo "scale=3; $cost / $opt" | bc -l)
                echo "  ✅ Custo: $cost, Tempo: ${time_python}s, Razão: $ratio"
                echo "$file,Python,MST_APPROX,$n,$cost,$time_python,APPROX" >> results/comparacao_linguagens.csv
            else
                echo "  ❌ Erro na execução"
            fi
        else
            echo "  ❌ Script não encontrado: src/python/approximate/mst_algorithm.py"
        fi
        
    elif [[ "$strategy" == "approx_only" ]]; then
        # ARQUIVOS GRANDES (29 e 44 cidades) - APENAS algoritmos aproximativos
        echo "🌳 Rodando APENAS algoritmos APROXIMATIVOS (instâncias grandes)"
        echo ""
        
        # 1. MST C
        echo "🔥 1. MST Aproximativo C:"
        if [[ -f "bin/mst_approx" ]]; then
            output=$(./bin/mst_approx "data/$file" 2>&1)
            cost=$(echo "$output" | grep "Custo aproximado:" | awk '{print $3}')
            time_c=$(echo "$output" | grep "Tempo de execução:" | awk '{print $4}')
            if [[ -n "$cost" && -n "$time_c" ]]; then
                ratio=$(echo "scale=3; $cost / $opt" | bc -l)
                echo "  ✅ Custo: $cost, Tempo: ${time_c}s, Razão: $ratio"
                echo "$file,C,MST_APPROX,$n,$cost,$time_c,APPROX" >> results/comparacao_linguagens.csv
            else
                echo "  ❌ Erro na execução"
            fi
        else
            echo "  ❌ Executável não encontrado: bin/mst_approx"
        fi
        
        # 2. MST Python
        echo "🐍 2. MST Aproximativo Python:"
        if [[ -f "src/python/approximate/mst_algorithm.py" ]]; then
            output=$(python3 src/python/approximate/mst_algorithm.py "data/$file" 2>&1)
            cost=$(echo "$output" | grep "Custo aproximado:" | awk '{print $3}')
            time_python=$(echo "$output" | grep "Tempo de execução:" | awk '{print $4}')
            if [[ -n "$cost" && -n "$time_python" ]]; then
                ratio=$(echo "scale=3; $cost / $opt" | bc -l)
                echo "  ✅ Custo: $cost, Tempo: ${time_python}s, Razão: $ratio"
                echo "$file,Python,MST_APPROX,$n,$cost,$time_python,APPROX" >> results/comparacao_linguagens.csv
            else
                echo "  ❌ Erro na execução"
            fi
        else
            echo "  ❌ Script não encontrado: src/python/approximate/mst_algorithm.py"
        fi
    fi
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
done

echo "📊 === RESULTADOS FINAIS ==="
echo ""

if [[ -f "results/comparacao_linguagens.csv" ]]; then
    echo "Arquivo de resultados: results/comparacao_linguagens.csv"
    echo ""
    echo "Tabela de Comparação:"
    column -t -s',' results/comparacao_linguagens.csv
    echo ""
    
    # Análise por arquivo
    echo "📈 === ANÁLISE DE PERFORMANCE POR ARQUIVO ==="
    echo ""
    
    for file in "${files[@]}"; do
        echo "📊 $file:"
        grep "$file" results/comparacao_linguagens.csv | while IFS=, read -r fname lang algo cities cost time tipo; do
            if [[ "$lang" != "Linguagem" ]]; then
                echo "  $lang ($algo, $tipo): ${time}s, Custo: $cost"
            fi
        done
        echo ""
    done
    
    # Resumo por tipo
    echo "📈 === RESUMO POR TIPO DE ALGORITMO ==="
    echo ""
    echo "🔥 Algoritmos Exatos:"
    grep "EXACT" results/comparacao_linguagens.csv | while IFS=, read -r fname lang algo cities cost time tipo; do
        echo "  $fname - $lang ($algo): ${time}s"
    done
    echo ""
    echo "🌳 Algoritmos Aproximativos:"
    grep "APPROX" results/comparacao_linguagens.csv | while IFS=, read -r fname lang algo cities cost time tipo; do
        echo "  $fname - $lang ($algo): ${time}s"
    done
    
else
    echo "❌ Arquivo de resultados não foi gerado"
fi

echo ""
echo "🏆 === COMPARAÇÃO CONCLUÍDA ==="
echo "🎯 Resultados salvos em: results/comparacao_linguagens.csv"
echo ""
echo "⚠️  NOTA: O algoritmo C para tsp3_1194.txt roda SEM timeout - pode demorar várias horas!"
echo "   Se precisar interromper, use Ctrl+C"
