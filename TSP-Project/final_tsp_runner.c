#!/bin/bash

# Script final para executar TSP - agora sabemos que funciona!

echo "🚀 === EXECUTAR TSP - VERSÃO FINAL ==="
echo "📅 $(date)"
echo ""

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}✅ DIAGNÓSTICO CONFIRMOU: TSP3 FUNCIONA!${NC}"
echo ""

# Criar diretório de resultados
mkdir -p results

# Função para executar e monitorar
run_tsp() {
    local file=$1
    local expected=$2
    local cities=$3
    local estimated_time=$4
    
    echo -e "${BLUE}🎯 === $file ($cities cidades) ===${NC}"
    echo -e "${BLUE}💰 Custo esperado: $expected${NC}"
    echo -e "${BLUE}⏱️  Tempo estimado: $estimated_time${NC}"
    echo -e "${BLUE}🚦 Iniciando às $(date '+%H:%M:%S')...${NC}"
    
    # Log file
    local log_file="results/${file%.txt}_$(date +%Y%m%d_%H%M%S).log"
    
    # Executar sem timeout (deixar rodar quanto precisar)
    {
        echo "=== EXECUÇÃO $file - $(date) ==="
        echo "Comando: ./bin/brute_force data/$file"
        echo "Custo esperado: $expected"
        echo "=== INÍCIO SAÍDA ==="
        
        ./bin/brute_force "data/$file" 2>&1
        local exit_code=$?
        
        echo "=== FIM SAÍDA ==="
        echo "Exit code: $exit_code"
        echo "Término: $(date)"
        
        return $exit_code
        
    } | tee "$log_file" &
    
    local pid=$!
    local start_time=$(date +%s)
    
    # Monitor em tempo real
    while kill -0 $pid 2>/dev/null; do
        local elapsed=$(( $(date +%s) - start_time ))
        local hours=$((elapsed / 3600))
        local minutes=$(((elapsed % 3600) / 60))
        local secs=$((elapsed % 60))
        
        printf "\r${YELLOW}⏱️  Executando há %02d:%02d:%02d | Log: %s${NC}" $hours $minutes $secs "$log_file"
        sleep 10
    done
    
    # Obter resultado
    wait $pid
    local final_exit_code=$?
    
    printf "\n"
    local end_time=$(date +%s)
    local total_time=$((end_time - start_time))
    
    if [ $final_exit_code -eq 0 ]; then
        # Extrair custo do log
        local cost=$(grep "Melhor custo encontrado:" "$log_file" | tail -1 | awk '{print $4}')
        local exec_time=$(grep "Tempo de execução:" "$log_file" | tail -1 | awk '{print $4}')
        
        echo -e "${GREEN}✅ CONCLUÍDO COM SUCESSO!${NC}"
        echo -e "${GREEN}   💰 Custo encontrado: $cost${NC}"
        echo -e "${GREEN}   ⏱️  Tempo execução: ${exec_time}s${NC}"
        echo -e "${GREEN}   🕐 Tempo total: ${total_time}s${NC}"
        
        if [ "$cost" = "$expected" ]; then
            echo -e "${GREEN}   🎯 CUSTO ÓTIMO ENCONTRADO!${NC}"
        fi
        
        # Salvar resultado resumido
        echo "$file,$cities,$cost,$expected,$exec_time,$total_time,SUCCESS" >> results/resultados_resumo.txt
        
    else
        echo -e "${RED}❌ ERRO na execução (exit code: $final_exit_code)${NC}"
        echo "$file,$cities,ERROR,$expected,0,$total_time,ERROR" >> results/resultados_resumo.txt
    fi
    
    echo -e "${BLUE}📁 Log completo salvo em: $log_file${NC}"
    echo ""
}

# Executar os 3 arquivos
echo "📋 ARQUIVOS A PROCESSAR:"
echo "  1. tsp2_1248.txt (6 cidades) - alguns segundos"
echo "  2. tsp1_253.txt (11 cidades) - alguns minutos"
echo "  3. tsp3_1194.txt (15 cidades) - ~17 horas"
echo ""

# Criar cabeçalho do arquivo de resultados
echo "Arquivo,Cidades,Custo,Esperado,TempoExec,TempoTotal,Status" > results/resultados_resumo.txt

# Executar um por vez
run_tsp "tsp2_1248.txt" "1248" "6" "segundos"

echo "⏸️  Pausa de 5 segundos..."
sleep 5

run_tsp "tsp1_253.txt" "253" "11" "minutos"

# Confirmação antes do pesado
echo ""
echo -e "${YELLOW}⚠️  PRÓXIMO: tsp3_1194.txt${NC}"
echo -e "${YELLOW}⚠️  Este vai demorar ~17 horas!${NC}"
echo -e "${YELLOW}⚠️  Computador ficará ocupado durante todo esse tempo${NC}"
echo ""
read -p "🤔 Executar TSP3 agora? (s/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo ""
    echo -e "${BLUE}🎬 INICIANDO TSP3 - O GRANDE TESTE!${NC}"
    run_tsp "tsp3_1194.txt" "1194" "15" "~17 horas"
else
    echo ""
    echo -e "${YELLOW}⏭️  TSP3 pulado pelo usuário${NC}"
    echo "tsp3_1194.txt,15,SKIPPED,1194,0,0,SKIPPED" >> results/resultados_resumo.txt
fi

# Mostrar resultados finais
echo ""
echo -e "${BLUE}🏆 === RESULTADOS FINAIS ===${NC}"
echo ""

if [ -f "results/resultados_resumo.txt" ]; then
    column -t -s',' results/resultados_resumo.txt
    echo ""
    echo -e "${BLUE}📁 Resultados salvos em results/resultados_resumo.txt${NC}"
    echo -e "${BLUE}📁 Logs detalhados em results/*.log${NC}"
else
    echo "❌ Arquivo de resultados não encontrado"
fi

echo ""
echo -e "${GREEN}🎉 EXECUÇÃO CONCLUÍDA!${NC}"
echo -e "${GREEN}📅 Término: $(date)${NC}"

# Verificar se há processos ainda rodando
if pgrep -f "brute_force" > /dev/null; then
    echo ""
    echo -e "${YELLOW}⚠️  Ainda há processos brute_force rodando em background${NC}"
    echo -e "${YELLOW}   Para acompanhar: ps aux | grep brute_force${NC}"
    echo -e "${YELLOW}   Para parar: pkill -f brute_force${NC}"
fi
