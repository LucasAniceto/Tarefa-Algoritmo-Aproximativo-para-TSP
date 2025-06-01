#!/bin/bash

# Script para executar força bruta TSP com monitoramento em tempo real
# Executa tsp1, tsp2, tsp3 automaticamente e coleta resultados

set -e  # Para no primeiro erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configurações
EXECUTABLE="bin/brute_force"
DATA_DIR="data"
RESULTS_DIR="results"
LOG_FILE="$RESULTS_DIR/execution_log.txt"
RESULTS_FILE="$RESULTS_DIR/brute_force_results.txt"

# Criar diretórios se não existirem
mkdir -p "$RESULTS_DIR"

echo -e "${BLUE}🚀 === EXECUÇÃO AUTOMÁTICA FORÇA BRUTA TSP ===${NC}"
echo -e "${BLUE}📅 Data/Hora: $(date)${NC}"
echo -e "${BLUE}💻 Sistema: $(uname -a)${NC}"
echo ""

# Verificar se executável existe
if [ ! -f "$EXECUTABLE" ]; then
    echo -e "${RED}❌ Erro: Executável não encontrado: $EXECUTABLE${NC}"
    echo -e "${YELLOW}💡 Para compilar:${NC}"
    echo -e "${YELLOW}   gcc -Wall -Wextra -O3 -std=c99 -o $EXECUTABLE src/c/exact/brute_force.c${NC}"
    exit 1
fi

# Arquivos para testar
declare -a FILES=("tsp1_253.txt" "tsp2_1248.txt" "tsp3_1194.txt")
declare -a EXPECTED_COSTS=(253 1248 1194)
declare -a CITIES=(11 6 15)
declare -a PERMUTATIONS=(3628800 120 87178291200)
declare -a ESTIMATED_TIMES=("segundos" "instantâneo" "17+ horas")

# Limpar arquivos de resultado anteriores
> "$LOG_FILE"
> "$RESULTS_FILE"

echo -e "${CYAN}📋 ARQUIVOS A PROCESSAR:${NC}"
for i in "${!FILES[@]}"; do
    echo -e "${CYAN}  ${FILES[i]} - ${CITIES[i]} cidades - ${PERMUTATIONS[i]} permutações - ~${ESTIMATED_TIMES[i]}${NC}"
done
echo ""

# Função para monitorar progresso
monitor_progress() {
    local pid=$1
    local filename=$2
    local expected_time=$3
    local start_time=$(date +%s)
    
    echo -e "${YELLOW}⏱️  Monitorando execução de $filename...${NC}"
    
    while kill -0 $pid 2>/dev/null; do
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        local hours=$((elapsed / 3600))
        local minutes=$(((elapsed % 3600) / 60))
        local seconds=$((elapsed % 60))
        
        printf "\r${PURPLE}🔄 Executando: %02d:%02d:%02d elapsed | PID: %d | Arquivo: %s${NC}" $hours $minutes $seconds $pid $filename
        sleep 10
    done
    printf "\n"
}

# Função para executar um arquivo TSP
execute_tsp() {
    local filename=$1
    local expected_cost=$2
    local cities=$3
    local permutations=$4
    local estimated_time=$5
    
    echo -e "${GREEN}🎯 === EXECUTANDO: $filename ===${NC}"
    echo -e "${GREEN}📊 Cidades: $cities | Permutações: $permutations | Estimativa: $estimated_time${NC}"
    
    local filepath="$DATA_DIR/$filename"
    
    if [ ! -f "$filepath" ]; then
        echo -e "${RED}❌ Arquivo não encontrado: $filepath${NC}"
        echo "$filename,ERROR,FILE_NOT_FOUND,0,0,0" >> "$RESULTS_FILE"
        return 1
    fi
    
    # Criar arquivo temporário para capturar output
    local temp_output=$(mktemp)
    local start_timestamp=$(date +%s)
    local start_human=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo -e "${BLUE}🚦 Iniciando às $start_human${NC}"
    echo "=== EXECUTANDO $filename às $start_human ===" >> "$LOG_FILE"
    
    # Executar em background e capturar PID
    timeout 72000 "$EXECUTABLE" "$filepath" > "$temp_output" 2>&1 &  # timeout de 20 horas
    local pid=$!
    
    # Monitorar progresso
    monitor_progress $pid $filename $estimated_time
    
    # Aguardar conclusão
    wait $pid
    local exit_code=$?
    
    local end_timestamp=$(date +%s)
    local end_human=$(date '+%Y-%m-%d %H:%M:%S')
    local total_time=$((end_timestamp - start_timestamp))
    
    echo -e "${BLUE}🏁 Finalizado às $end_human${NC}"
    
    # Processar resultado
    if [ $exit_code -eq 0 ]; then
        # Sucesso - extrair dados do output
        local cost=$(grep "Melhor custo encontrado:" "$temp_output" | awk '{print $4}' | head -1)
        local time_seconds=$(grep "Tempo de execução:" "$temp_output" | awk '{print $4}' | head -1)
        local path=$(grep "Melhor caminho:" "$temp_output" | cut -d: -f2 | head -1 | xargs)
        
        if [ -z "$cost" ]; then
            cost="UNKNOWN"
        fi
        if [ -z "$time_seconds" ]; then
            time_seconds="$total_time"
        fi
        
        echo -e "${GREEN}✅ SUCESSO!${NC}"
        echo -e "${GREEN}   💰 Custo encontrado: $cost${NC}"
        echo -e "${GREEN}   💰 Custo esperado: $expected_cost${NC}"
        echo -e "${GREEN}   ⏱️  Tempo execução: ${time_seconds}s${NC}"
        echo -e "${GREEN}   🕐 Tempo total: ${total_time}s${NC}"
        
        # Verificar se encontrou o ótimo
        local status="SUCCESS"
        if [ "$cost" = "$expected_cost" ]; then
            echo -e "${GREEN}   🎯 ÓTIMO ENCONTRADO!${NC}"
            status="OPTIMAL"
        elif [ "$cost" != "UNKNOWN" ] && [ "$cost" -lt "$expected_cost" ]; then
            echo -e "${YELLOW}   ⚠️  Custo menor que esperado (verificar)${NC}"
            status="BETTER_THAN_EXPECTED"
        elif [ "$cost" != "UNKNOWN" ] && [ "$cost" -gt "$expected_cost" ]; then
            echo -e "${RED}   ❌ Custo maior que esperado (erro?)${NC}"
            status="SUBOPTIMAL"
        fi
        
        # Salvar resultado
        echo "$filename,$status,$cost,$expected_cost,$time_seconds,$total_time" >> "$RESULTS_FILE"
        
    elif [ $exit_code -eq 124 ]; then
        # Timeout
        echo -e "${YELLOW}⏱️  TIMEOUT após ${total_time}s${NC}"
        echo "$filename,TIMEOUT,0,$expected_cost,0,$total_time" >> "$RESULTS_FILE"
        
    else
        # Erro
        echo -e "${RED}❌ ERRO (exit code: $exit_code)${NC}"
        echo "$filename,ERROR,$exit_code,$expected_cost,0,$total_time" >> "$RESULTS_FILE"
    fi
    
    # Salvar log detalhado
    echo "=== OUTPUT DE $filename ===" >> "$LOG_FILE"
    cat "$temp_output" >> "$LOG_FILE"
    echo "=== FIM OUTPUT $filename ===" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    
    # Limpar arquivo temporário
    rm -f "$temp_output"
    
    echo ""
}

# Executar todos os arquivos
echo -e "${CYAN}🎬 INICIANDO EXECUÇÕES...${NC}"
echo ""

for i in "${!FILES[@]}"; do
    execute_tsp "${FILES[i]}" "${EXPECTED_COSTS[i]}" "${CITIES[i]}" "${PERMUTATIONS[i]}" "${ESTIMATED_TIMES[i]}"
    
    # Pausa entre execuções (exceto na última)
    if [ $i -lt $((${#FILES[@]} - 1)) ]; then
        echo -e "${BLUE}⏸️  Pausa de 5 segundos antes do próximo...${NC}"
        sleep 5
    fi
done

# Gerar relatório final
echo -e "${CYAN}📊 === RELATÓRIO FINAL ===${NC}"
echo ""

if [ -f "$RESULTS_FILE" ]; then
    echo -e "${CYAN}📁 Arquivo de resultados: $RESULTS_FILE${NC}"
    echo -e "${CYAN}📋 Resultados:${NC}"
    echo ""
    
    printf "%-15s %-12s %-8s %-8s %-12s %-10s\n" "ARQUIVO" "STATUS" "CUSTO" "ESPERADO" "TEMPO(s)" "TOTAL(s)"
    echo "------------------------------------------------------------------------"
    
    while IFS=',' read -r filename status cost expected time_exec time_total; do
        if [ "$status" = "OPTIMAL" ]; then
            color=$GREEN
        elif [ "$status" = "SUCCESS" ]; then
            color=$YELLOW
        elif [ "$status" = "TIMEOUT" ]; then
            color=$PURPLE
        else
            color=$RED
        fi
        
        printf "${color}%-15s %-12s %-8s %-8s %-12s %-10s${NC}\n" \
            "$filename" "$status" "$cost" "$expected" "$time_exec" "$time_total"
    done < "$RESULTS_FILE"
    
    echo ""
    
    # Estatísticas
    local total_files=$(wc -l < "$RESULTS_FILE")
    local successful=$(grep -c "SUCCESS\|OPTIMAL" "$RESULTS_FILE" || echo "0")
    local timeouts=$(grep -c "TIMEOUT" "$RESULTS_FILE" || echo "0")
    local errors=$(grep -c "ERROR" "$RESULTS_FILE" || echo "0")
    
    echo -e "${CYAN}📈 ESTATÍSTICAS:${NC}"
    echo -e "${GREEN}  ✅ Sucessos: $successful/$total_files${NC}"
    echo -e "${YELLOW}  ⏱️  Timeouts: $timeouts/$total_files${NC}"
    echo -e "${RED}  ❌ Erros: $errors/$total_files${NC}"
    
else
    echo -e "${RED}❌ Arquivo de resultados não encontrado!${NC}"
fi

echo ""
echo -e "${BLUE}📄 Log detalhado salvo em: $LOG_FILE${NC}"
echo -e "${BLUE}🏁 Execução concluída às $(date)${NC}"

# Verificar se algum processo ainda está rodando (limpeza)
if pgrep -f "$EXECUTABLE" > /dev/null; then
    echo -e "${YELLOW}⚠️  Ainda há processos do brute_force rodando:${NC}"
    pgrep -f "$EXECUTABLE" | while read pid; do
        echo -e "${YELLOW}   PID: $pid${NC}"
    done
    echo -e "${YELLOW}   Use 'pkill -f brute_force' para matá-los se necessário${NC}"
fi

echo ""
echo -e "${GREEN}🎉 SCRIPT CONCLUÍDO!${NC}"
