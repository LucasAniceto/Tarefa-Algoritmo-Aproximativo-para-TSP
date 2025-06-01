#!/bin/bash

# Script de debug para descobrir por que o TSP3 não executa completamente

echo "🔍 === DEBUG: POR QUE O TSP3 PARA? ==="
echo "📅 $(date)"
echo ""

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Verificações básicas
echo -e "${BLUE}1. VERIFICANDO AMBIENTE...${NC}"

# Verificar executável
if [ -f "bin/brute_force" ]; then
    echo -e "${GREEN}✅ bin/brute_force existe${NC}"
    ls -la bin/brute_force
    echo "   Compilado em: $(stat -c %y bin/brute_force 2>/dev/null || stat -f %Sm bin/brute_force)"
else
    echo -e "${RED}❌ bin/brute_force NÃO EXISTE${NC}"
    echo "   Precisa compilar primeiro!"
    exit 1
fi

# Verificar arquivos de dados
echo ""
echo -e "${BLUE}2. VERIFICANDO ARQUIVOS DE DADOS...${NC}"
for file in tsp1_253.txt tsp2_1248.txt tsp3_1194.txt; do
    if [ -f "data/$file" ]; then
        echo -e "${GREEN}✅ data/$file existe ($(wc -l < "data/$file") linhas)${NC}"
    else
        echo -e "${RED}❌ data/$file NÃO EXISTE${NC}"
    fi
done

# Teste simples primeiro
echo ""
echo -e "${BLUE}3. TESTE SIMPLES COM TSP2...${NC}"
echo "Executando: ./bin/brute_force data/tsp2_1248.txt"
echo "Saída:"
echo "----------------------------------------"

# Executar TSP2 com timeout menor e verbose
timeout 60 ./bin/brute_force data/tsp2_1248.txt
tsp2_exit_code=$?

echo "----------------------------------------"
echo "Exit code: $tsp2_exit_code"

if [ $tsp2_exit_code -eq 0 ]; then
    echo -e "${GREEN}✅ TSP2 funcionou!${NC}"
elif [ $tsp2_exit_code -eq 124 ]; then
    echo -e "${YELLOW}⏱️ TSP2 deu timeout (>60s - estranho!)${NC}"
else
    echo -e "${RED}❌ TSP2 deu erro!${NC}"
    echo "Isso indica problema no executável ou dados"
    exit 1
fi

# Agora testar TSP3 com debug
echo ""
echo -e "${BLUE}4. TESTE DEBUG COM TSP3...${NC}"
echo "Executando TSP3 por 2 minutos para ver se inicia..."

# Criar arquivo de log detalhado
log_file="debug_tsp3_$(date +%Y%m%d_%H%M%S).log"

echo "📝 Log será salvo em: $log_file"
echo ""

# Executar com timeout de 2 minutos e capturar TUDO
echo "🚦 Iniciando TSP3 às $(date '+%H:%M:%S')..."

{
    echo "=== DEBUG TSP3 - $(date) ==="
    echo "Comando: ./bin/brute_force data/tsp3_1194.txt"
    echo "PID: $$"
    echo "Diretório: $(pwd)"
    echo "Usuário: $(whoami)"
    echo "Sistema: $(uname -a)"
    echo "Memória livre: $(free -m 2>/dev/null || echo 'N/A')"
    echo "=== INÍCIO EXECUÇÃO ==="
    
    # Executar e capturar stderr também
    timeout 120 stdbuf -oL -eL ./bin/brute_force data/tsp3_1194.txt 2>&1
    
    echo "=== FIM EXECUÇÃO ==="
    echo "Exit code: $?"
    echo "Fim às: $(date)"
} | tee "$log_file"

tsp3_exit_code=${PIPESTATUS[0]}

echo ""
echo -e "${BLUE}5. ANÁLISE DO RESULTADO...${NC}"

if [ $tsp3_exit_code -eq 0 ]; then
    echo -e "${GREEN}✅ TSP3 executou normalmente (terminou em <2min?)${NC}"
    echo "   Isso é estranho - deveria demorar horas!"
    echo "   Verifique se o arquivo tsp3_1194.txt está correto"
    
elif [ $tsp3_exit_code -eq 124 ]; then
    echo -e "${YELLOW}⏱️ TSP3 deu timeout após 2 minutos${NC}"
    echo -e "${GREEN}   ✅ ISSO É NORMAL! Significa que está executando${NC}"
    echo "   O timeout nos scripts principais pode estar muito baixo"
    
elif [ $tsp3_exit_code -eq 130 ]; then
    echo -e "${YELLOW}⚠️ TSP3 foi interrompido (Ctrl+C)${NC}"
    
else
    echo -e "${RED}❌ TSP3 deu erro (exit code: $tsp3_exit_code)${NC}"
    echo "   Verifique o log para detalhes"
fi

# Análise do log
echo ""
echo -e "${BLUE}6. ANÁLISE DO LOG...${NC}"

if [ -f "$log_file" ]; then
    echo "📊 Primeiras linhas do log:"
    head -20 "$log_file"
    echo ""
    echo "📊 Últimas linhas do log:"
    tail -10 "$log_file"
    
    # Procurar por indicadores
    echo ""
    echo "🔍 Buscando indicadores no log..."
    
    if grep -q "Iniciando força bruta" "$log_file"; then
        echo -e "${GREEN}✅ Programa iniciou corretamente${NC}"
    else
        echo -e "${RED}❌ Programa não mostrou início${NC}"
    fi
    
    if grep -q "Número de permutações a testar" "$log_file"; then
        permutations=$(grep "Número de permutações a testar" "$log_file" | awk '{print $NF}')
        echo -e "${GREEN}✅ Calculou permutações: $permutations${NC}"
    else
        echo -e "${YELLOW}⚠️ Não mostrou cálculo de permutações${NC}"
    fi
    
    if grep -q "Nova melhor solução" "$log_file"; then
        echo -e "${GREEN}✅ Encontrou pelo menos uma solução${NC}"
    else
        echo -e "${YELLOW}⚠️ Não encontrou soluções ainda (normal em 2min)${NC}"
    fi
    
    if grep -q "erro\|error\|Error\|ERROR" "$log_file"; then
        echo -e "${RED}❌ Log contém erros:${NC}"
        grep -i "erro\|error" "$log_file"
    fi
fi

# Verificar processos
echo ""
echo -e "${BLUE}7. VERIFICANDO PROCESSOS...${NC}"

if pgrep -f "brute_force" > /dev/null; then
    echo -e "${YELLOW}⚠️ Ainda há processos brute_force rodando:${NC}"
    pgrep -f "brute_force" | while read pid; do
        echo "   PID: $pid"
        ps -p $pid -o pid,ppid,cmd,time 2>/dev/null || echo "   (processo já terminou)"
    done
    echo ""
    echo "Para matar todos: pkill -f brute_force"
else
    echo -e "${GREEN}✅ Nenhum processo brute_force rodando${NC}"
fi

# Recomendações
echo ""
echo -e "${BLUE}8. DIAGNÓSTICO E RECOMENDAÇÕES...${NC}"

if [ $tsp3_exit_code -eq 124 ]; then
    echo -e "${GREEN}✅ DIAGNÓSTICO: Programa funcionando normalmente!${NC}"
    echo ""
    echo "🔧 PROBLEMA PROVÁVEL: Timeout muito baixo nos scripts"
    echo ""
    echo "💡 SOLUÇÕES:"
    echo "   1. Aumentar timeout nos scripts de 72000s para mais"
    echo "   2. Ou executar TSP3 manualmente:"
    echo "      nohup ./bin/brute_force data/tsp3_1194.txt > tsp3_result.log 2>&1 &"
    echo "   3. Monitorar com: tail -f tsp3_result.log"
    echo ""
    echo "⏱️  TEMPO ESPERADO REAL: ~17 horas para TSP3"
    
elif [ $tsp3_exit_code -eq 0 ]; then
    echo -e "${YELLOW}⚠️ DIAGNÓSTICO: Programa termina muito rápido${NC}"
    echo ""
    echo "🔧 POSSÍVEIS CAUSAS:"
    echo "   1. Arquivo tsp3_1194.txt corrompido ou muito pequeno"
    echo "   2. Programa compilado incorretamente"
    echo "   3. Algoritmo modificado para retornar mais cedo"
    echo ""
    echo "💡 VERIFICAÇÕES:"
    echo "   wc -l data/tsp3_1194.txt    # Deve ter 15 linhas"
    echo "   head -3 data/tsp3_1194.txt  # Verificar formato"
    
else
    echo -e "${RED}❌ DIAGNÓSTICO: Erro na execução${NC}"
    echo ""
    echo "💡 VERIFICAR:"
    echo "   1. Permissões do executável: chmod +x bin/brute_force"
    echo "   2. Dependências do sistema"
    echo "   3. Log detalhado em: $log_file"
fi

echo ""
echo -e "${BLUE}🏁 Debug concluído! Log salvo em: $log_file${NC}"
