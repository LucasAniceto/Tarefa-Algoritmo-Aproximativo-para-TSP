#!/bin/bash

echo "🚀 === COMPARAÇÃO DE LINGUAGENS - ALGORITMOS EXATOS TSP ==="
echo ""

# Criar arquivo de resultados
mkdir -p results
echo "Arquivo,Linguagem,Algoritmo,Cidades,Custo,Tempo(s),Permutacoes" > results/comparacao_linguagens.csv

# Arquivos VIÁVEIS para algoritmos exatos (baseado na performance do seu Ryzen 5 9600X)
echo "🎯 MODO INTELIGENTE - Apenas arquivos que terminam em tempo razoável"
echo "   ✅ tsp2_1248.txt (6 cidades) = Segundos"
echo "   ✅ tsp1_253.txt (11 cidades) = Minutos"
echo "   ⚠️ tsp3_1194.txt (15 cidades) = Minutos a horas"
echo "   ❌ tsp4_7013.txt (44 cidades) = IMPOSSÍVEL para força bruta"
echo "   ❌ tsp5_27603.txt (29 cidades) = IMPOSSÍVEL para força bruta"
echo ""

# Arquivos para testar - ATENÇÃO: Arquivos grandes podem demorar horas!
echo "⚠️  AVISO: Alguns arquivos podem demorar muito tempo!"
echo ""

read -p "🤔 Testar todos os arquivos? (s/N): " response
if [[ "$response" =~ ^[Ss]$ ]]; then
    # TODOS os arquivos (PERIGOSO!)
    files=("tsp2_1248.txt" "tsp1_253.txt" "tsp3_1194.txt" "tsp4_7013.txt" "tsp5_27603.txt")
    cities=(6 11 15 44 29)
    optimal=(1248 253 1194 7013 27603)
    strategies=("exact" "exact" "mixed" "approx" "approx")
    timeouts=(30 60 1800 999999 999999)  # timeouts em segundos
    echo "🚀 Modo ÉPICO ativado - testando TODOS os arquivos!"
else
    # Apenas arquivos pequenos e médios (SEGURO)
    files=("tsp2_1248.txt" "tsp1_253.txt" "tsp3_1194.txt")
    cities=(6 11 15)
    optimal=(1248 253 1194)
    strategies=("exact" "exact" "mixed")
    timeouts=(30 60 1800)  # 30s, 1min, 30min
    echo "🎯 Modo SEGURO - testando arquivos pequenos e médios"
fi

echo "📋 Testando arquivos: ${files[@]}"
echo "🏁 Algoritmos: Força Bruta em C, Java e Python"
echo ""

for i in "${!files[@]}"; do
    file=${files[$i]}
    n=${cities[$i]}
    opt=${optimal[$i]}
    strategy=${strategies[$i]}
    
    echo "🧪 === TESTANDO $file ($n cidades, ótimo=$opt, estratégia=$strategy) ==="
    echo ""
    
    if [[ "$strategy" == "exact" ]]; then
        # ALGORITMOS EXATOS - C, Java, Python
        echo "🎯 Rodando algoritmos EXATOS nas 3 linguagens"
        echo ""
        
        # 1. Força Bruta C
        echo "🔥 1. Força Bruta C:"
        if [[ -f "bin/brute_force" ]]; then
            output=$(timeout 120 ./bin/brute_force "data/$file" 2>&1)
            if [[ $? -eq 0 ]]; then
                cost=$(echo "$output" | grep "Melhor custo encontrado:" | awk '{print $4}')
                time_c=$(echo "$output" | grep "Tempo de execução:" | awk '{print $4}')
                echo "  ✅ Custo: $cost, Tempo: ${time_c}s"
                echo "$file,C,BRUTE_FORCE,$n,$cost,$time_c,EXACT" >> results/comparacao_linguagens.csv
            else
                echo "  ⏱️ Timeout C"
            fi
        fi
        
        # 2. Força Bruta Java
        echo "☕ 2. Força Bruta Java:"
        if [[ -f "src/java/exact/BruteForce.class" ]]; then
            cd src/java/exact
            output=$(timeout 120 java BruteForce "../../../data/$file" 2>&1)
            if [[ $? -eq 0 ]]; then
                cost=$(echo "$output" | grep "Melhor custo:" | awk '{print $3}')
                time_java=$(echo "$output" | grep "Tempo de execução:" | awk '{print $4}')
                echo "  ✅ Custo: $cost, Tempo: ${time_java}s"
                echo "$file,Java,BRUTE_FORCE,$n,$cost,$time_java,EXACT" >> ../../../results/comparacao_linguagens.csv
            else
                echo "  ⏱️ Timeout Java"
            fi
            cd ../../..
        fi
        
        # 3. Força Bruta Python
        echo "🐍 3. Força Bruta Python:"
        if [[ -f "src/python/exact/brute_force_python.py" ]]; then
            output=$(timeout 120 python3 src/python/exact/brute_force_python.py "data/$file" 2>&1)
            if [[ $? -eq 0 ]]; then
                cost=$(echo "$output" | grep "Melhor custo encontrado:" | awk '{print $4}')
                time_python=$(echo "$output" | grep "Tempo de execução:" | awk '{print $4}')
                echo "  ✅ Custo: $cost, Tempo: ${time_python}s"
                echo "$file,Python,BRUTE_FORCE,$n,$cost,$time_python,EXACT" >> results/comparacao_linguagens.csv
            else
                echo "  ⏱️ Timeout Python"
            fi
        fi
        
        # 4. Branch & Bound Java (bonus)
        echo "🌳 4. Branch & Bound Java:"
        if [[ -f "src/java/exact/BranchBound.class" ]]; then
            cd src/java/exact
            output=$(timeout 120 java BranchBound "../../../data/$file" 2>&1)
            if [[ $? -eq 0 ]]; then
                cost=$(echo "$output" | grep "Melhor custo:" | awk '{print $3}')
                time_bb=$(echo "$output" | grep "Tempo de execução:" | awk '{print $4}')
                pruned=$(echo "$output" | grep "Nós podados:" | awk '{print $3}')
                echo "  ✅ Custo: $cost, Tempo: ${time_bb}s, Podados: $pruned"
                echo "$file,Java,BRANCH_BOUND,$n,$cost,$time_bb,EXACT" >> ../../../results/comparacao_linguagens.csv
            else
                echo "  ⏱️ Timeout Branch & Bound"
            fi
            cd ../../..
        fi
        
    elif [[ "$strategy" == "mixed" ]]; then
        # MISTO - Exatos C/Java, Aproximativo Python
        echo "🎯 Rodando EXATOS (C,Java) + APROXIMATIVO (Python)"
        echo ""
        
        # 1. Força Bruta C (com timeout maior)
        echo "🔥 1. Força Bruta C:"
        if [[ -f "bin/brute_force" ]]; then
            output=$(timeout 1800 ./bin/brute_force "data/$file" 2>&1)
            if [[ $? -eq 0 ]]; then
                cost=$(echo "$output" | grep "Melhor custo encontrado:" | awk '{print $4}')
                time_c=$(echo "$output" | grep "Tempo de execução:" | awk '{print $4}')
                echo "  ✅ Custo: $cost, Tempo: ${time_c}s"
                echo "$file,C,BRUTE_FORCE,$n,$cost,$time_c,EXACT" >> results/comparacao_linguagens.csv
            else
                echo "  ⏱️ Timeout C (30min)"
            fi
        fi
        
        # 2. Branch & Bound Java (mais eficiente)
        echo "🌳 2. Branch & Bound Java:"
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
        fi
        
        # 3. MST Python (aproximativo)
        echo "🐍 3. MST Aproximativo Python:"
        if [[ -f "src/python/approximate/mst_algorithm.py" ]]; then
            output=$(python3 src/python/approximate/mst_algorithm.py "data/$file" 2>&1)
            cost=$(echo "$output" | grep "Custo aproximado:" | awk '{print $3}')
            time_python=$(echo "$output" | grep "Tempo de execução:" | awk '{print $4}')
            if [[ -n "$cost" && -n "$time_python" ]]; then
                ratio=$(echo "scale=3; $cost / $opt" | bc -l)
                echo "  ✅ Custo: $cost, Tempo: ${time_python}s, Razão: $ratio"
                echo "$file,Python,MST_APPROX,$n,$cost,$time_python,APPROX" >> results/comparacao_linguagens.csv
            fi
        fi
        
    elif [[ "$strategy" == "approx" ]]; then
        # APENAS APROXIMATIVOS - C e Python
        echo "🌳 Rodando apenas algoritmos APROXIMATIVOS (instâncias grandes)"
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
            fi
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
            fi
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
    
    # Análise básica
    echo "📈 === ANÁLISE DE PERFORMANCE ==="
    echo ""
    
    # Comparar tempos para tsp2_1248.txt
    echo "📊 tsp2_1248.txt (6 cidades):"
    grep "tsp2_1248.txt" results/comparacao_linguagens.csv | while IFS=, read -r file lang algo cities cost time perms; do
        if [[ "$lang" != "Linguagem" ]]; then
            echo "  $lang ($algo): ${time}s"
        fi
    done
    
    echo ""
    echo "📊 tsp1_253.txt (11 cidades):"
    grep "tsp1_253.txt" results/comparacao_linguagens.csv | while IFS=, read -r file lang algo cities cost time perms; do
        if [[ "$lang" != "Linguagem" ]]; then
            echo "  $lang ($algo): ${time}s"
        fi
    done
    
else
    echo "❌ Arquivo de resultados não foi gerado"
fi

echo ""
echo "🏆 === COMPARAÇÃO CONCLUÍDA ==="
echo "🎯 Resultados salvos em: results/comparacao_linguagens.csv"
