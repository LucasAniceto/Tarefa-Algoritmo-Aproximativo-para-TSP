#!/bin/bash

# Script simples para rodar força bruta TSP nos 3 arquivos principais
# Com log em tempo real e resultados no final

echo "🚀 === EXECUTANDO FORÇA BRUTA TSP ===" 
echo "📅 Início: $(date)"
echo ""

# Verificar se executável existe
if [ ! -f "bin/brute_force" ]; then
    echo "❌ Erro: bin/brute_force não encontrado!"
    echo "💡 Compile com: gcc -O3 -o bin/brute_force src/c/exact/brute_force.c"
    exit 1
fi

# Criar arquivo de resultados
mkdir -p results
echo "# Resultados Força Bruta - $(date)" > results/resultados_final.txt
echo "Arquivo,Cidades,Custo_Encontrado,Custo_Esperado,Tempo_Segundos,Status" >> results/resultados_final.txt

# Função para executar e monitorar
run_tsp() {
    local file=$1
    local expected=$2
    local cities=$3
    local description=$4
    
    echo "🎯 === $file ($cities cidades) ==="
    echo "📊 $description"
    echo "💰 Custo esperado: $expected"
    echo "🚦 Iniciando às $(date '+%H:%M:%S')..."
    
    # Executar em background
    timeout 72000 ./bin/brute_force "data/$file" > "results/temp_$file.log" 2>&1 &
    local pid=$!
    
    # Monitor simples
    local start_time=$(date +%s)
    local count=0
    
    while kill -0 $pid 2>/dev/null; do
        local elapsed=$(( $(date +%s) - start_time ))
        local hours=$((elapsed / 3600))
        local minutes=$(((elapsed % 3600) / 60))
        local secs=$((elapsed % 60))
        
        # Mostrar progresso a cada 30 segundos
        if [ $((count % 3)) -eq 0 ]; then
            printf "\r⏱️  Rodando há %02d:%02d:%02d - PID: %d - Arquivo: %s   " $hours $minutes $secs $pid $file
        fi
        
        sleep 10
        count=$((count + 1))
    done
    
    # Pegar resultado
    wait $pid
    local exit_code=$?
    local end_time=$(date +%s)
    local total_time=$((end_time - start_time))
    
    printf "\n"
    
    if [ $exit_code -eq 0 ]; then
        # Extrair dados do log
        local cost=$(grep "Melhor custo encontrado:" "results/temp_$file.log" | awk '{print $4}')
        local time_exec=$(grep "Tempo de execução:" "results/temp_$file.log" | awk '{print $4}')
        
        echo "✅ CONCLUÍDO!"
        echo "   💰 Custo: $cost"
        echo "   ⏱️  Tempo: ${time_exec}s (${total_time}s total)"
        
        # Verificar se é ótimo
        if [ "$cost" = "$expected" ]; then
            echo "   🎯 ÓTIMO ENCONTRADO!"
            status="OPTIMAL"
        else
            echo "   ⚠️  Diferente do esperado"
            status="SUCCESS"
        fi
        
        # Salvar resultado
        echo "$file,$cities,$cost,$expected,$time_exec,$status" >> results/resultados_final.txt
        
    elif [ $exit_code -eq 124 ]; then
        echo "⏱️  TIMEOUT após ${total_time}s"
        echo "$file,$cities,TIMEOUT,$expected,$total_time,TIMEOUT" >> results/resultados_final.txt
    else
        echo "❌ ERRO (código: $exit_code)"
        echo "$file,$cities,ERROR,$expected,$total_time,ERROR" >> results/resultados_final.txt
    fi
    
    echo "🏁 Finalizado às $(date '+%H:%M:%S')"
    echo ""
}

# Executar os 3 arquivos principais
echo "📋 Arquivos a processar:"
echo "  1. tsp2_1248.txt (6 cidades) - ~segundos"
echo "  2. tsp1_253.txt (11 cidades) - ~minutos" 
echo "  3. tsp3_1194.txt (15 cidades) - ~17 horas"
echo ""

read -p "🤔 Continuar? (s/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo "❌ Cancelado pelo usuário"
    exit 0
fi

echo ""

# Executar na ordem crescente de dificuldade
run_tsp "tsp2_1248.txt" "1248" "6" "Teste rápido - alguns segundos"
run_tsp "tsp1_253.txt" "253" "11" "Teste médio - alguns minutos"

# Perguntar antes do pesado
echo "⚠️  PRÓXIMO: tsp3_1194.txt (15 cidades)"
echo "⚠️  Este pode demorar até 17+ horas!"
echo ""
read -p "🤔 Executar mesmo assim? (s/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Ss]$ ]]; then
    run_tsp "tsp3_1194.txt" "1194" "15" "Teste pesado - muitas horas"
else
    echo "⏭️  Pulando tsp3_1194.txt"
    echo "tsp3_1194.txt,15,SKIPPED,1194,0,SKIPPED" >> results/resultados_final.txt
fi

# Mostrar resultados finais
echo ""
echo "🏆 === RESULTADOS FINAIS ==="
echo ""
column -t -s',' results/resultados_final.txt
echo ""
echo "📁 Resultados detalhados salvos em:"
echo "   - results/resultados_final.txt"
echo "   - results/temp_*.log"
echo ""
echo "🎉 Execução concluída às $(date)!"

# Limpeza opcional
read -p "🗑️  Deletar logs temporários? (s/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Ss]$ ]]; then
    rm -f results/temp_*.log
    echo "✅ Logs temporários removidos"
fi
