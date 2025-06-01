#!/bin/bash

# Script para verificar se os arquivos TSP estão corretos
# e diagnosticar problemas de compilação

echo "🔍 === DIAGNÓSTICO COMPLETO TSP ==="
echo "📅 $(date)"
echo ""

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 1. VERIFICAR ARQUIVOS TSP
echo -e "${BLUE}1. VERIFICANDO ARQUIVOS TSP...${NC}"
echo ""

for file in tsp1_253.txt tsp2_1248.txt tsp3_1194.txt; do
    filepath="data/$file"
    echo -e "${BLUE}📁 Arquivo: $file${NC}"
    
    if [ -f "$filepath" ]; then
        lines=$(wc -l < "$filepath")
        size=$(du -h "$filepath" | cut -f1)
        
        echo "   ✅ Existe: $size, $lines linhas"
        
        # Verificar se tem o número correto de linhas
        case $file in
            "tsp1_253.txt") expected_lines=11 ;;
            "tsp2_1248.txt") expected_lines=6 ;;
            "tsp3_1194.txt") expected_lines=15 ;;
        esac
        
        if [ "$lines" -eq "$expected_lines" ]; then
            echo -e "   ${GREEN}✅ Número de linhas correto: $lines${NC}"
        else
            echo -e "   ${RED}❌ Número incorreto de linhas: $lines (esperado: $expected_lines)${NC}"
        fi
        
        # Mostrar primeiras linhas
        echo "   📄 Primeiras 3 linhas:"
        head -3 "$filepath" | sed 's/^/      /'
        
        # Verificar se primeira linha tem números corretos
        first_line=$(head -1 "$filepath")
        num_columns=$(echo "$first_line" | wc -w)
        
        if [ "$num_columns" -eq "$expected_lines" ]; then
            echo -e "   ${GREEN}✅ Primeira linha tem $num_columns números (correto)${NC}"
        else
            echo -e "   ${RED}❌ Primeira linha tem $num_columns números (esperado: $expected_lines)${NC}"
        fi
        
        # Verificar se são todos números
        if echo "$first_line" | grep -q '^[0-9 \t]*$'; then
            echo -e "   ${GREEN}✅ Primeira linha contém apenas números${NC}"
        else
            echo -e "   ${RED}❌ Primeira linha contém caracteres não-numéricos${NC}"
            echo "   👀 Caracteres encontrados: $(echo "$first_line" | tr -d '0-9 \t')"
        fi
        
    else
        echo -e "   ${RED}❌ Arquivo não encontrado!${NC}"
    fi
    echo ""
done

# 2. VERIFICAR COMPILAÇÃO
echo -e "${BLUE}2. VERIFICANDO COMPILAÇÃO...${NC}"
echo ""

if [ -f "bin/brute_force" ]; then
    echo -e "${GREEN}✅ Executável bin/brute_force existe${NC}"
    ls -la bin/brute_force
    
    # Verificar se é executável
    if [ -x "bin/brute_force" ]; then
        echo -e "${GREEN}✅ Tem permissão de execução${NC}"
    else
        echo -e "${RED}❌ Não tem permissão de execução${NC}"
        echo "   Corrija com: chmod +x bin/brute_force"
    fi
    
    # Testar dependências
    echo ""
    echo "🔧 Testando dependências..."
    if ldd bin/brute_force 2>/dev/null | grep -q "not found"; then
        echo -e "${RED}❌ Bibliotecas faltando:${NC}"
        ldd bin/brute_force | grep "not found"
    else
        echo -e "${GREEN}✅ Todas as bibliotecas encontradas${NC}"
    fi
    
else
    echo -e "${RED}❌ Executável bin/brute_force NÃO EXISTE${NC}"
    echo ""
    echo "🔧 RECOMPILANDO..."
    
    if [ -f "src/c/exact/brute_force.c" ]; then
        echo "   Código fonte encontrado: src/c/exact/brute_force.c"
        echo "   Compilando com: gcc -Wall -Wextra -O3 -std=c99 -o bin/brute_force src/c/exact/brute_force.c"
        
        mkdir -p bin
        gcc -Wall -Wextra -O3 -std=c99 -o bin/brute_force src/c/exact/brute_force.c
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Compilação bem-sucedida!${NC}"
        else
            echo -e "${RED}❌ Erro na compilação!${NC}"
            exit 1
        fi
    else
        echo -e "${RED}❌ Código fonte não encontrado: src/c/exact/brute_force.c${NC}"
        exit 1
    fi
fi

# 3. TESTE BÁSICO
echo ""
echo -e "${BLUE}3. TESTE BÁSICO DE EXECUÇÃO...${NC}"
echo ""

# Criar arquivo de teste simples
echo "📝 Criando arquivo de teste (4x4)..."
mkdir -p data
cat > data/test_4x4.txt << EOF
0 10 15 20
10 0 35 25
15 35 0 30
20 25 30 0
EOF

echo "✅ Arquivo de teste criado: data/test_4x4.txt"
echo ""

# Testar execução básica
echo "🧪 Testando execução básica..."
echo "Comando: ./bin/brute_force data/test_4x4.txt"
echo "Saída:"
echo "----------------------------------------"

./bin/brute_force data/test_4x4.txt 2>&1
test_exit_code=$?

echo "----------------------------------------"
echo "Exit code: $test_exit_code"

if [ $test_exit_code -eq 0 ]; then
    echo -e "${GREEN}✅ Teste básico PASSOU!${NC}"
    echo "   O programa funciona corretamente"
else
    echo -e "${RED}❌ Teste básico FALHOU!${NC}"
    echo "   Há problema no programa ou sistema"
    
    # Diagnostics adicionais
    echo ""
    echo "🔍 Diagnósticos adicionais:"
    echo "   Sistema: $(uname -a)"
    echo "   Arquitetura: $(uname -m)"
    echo "   GCC versão: $(gcc --version 2>/dev/null | head -1)"
    
    exit 1
fi

# 4. TESTE COM TSP2 (pequeno)
echo ""
echo -e "${BLUE}4. TESTE COM TSP2 (arquivo real)...${NC}"
echo ""

if [ -f "data/tsp2_1248.txt" ]; then
    echo "🧪 Testando tsp2_1248.txt (deve ser rápido)..."
    echo "Comando: ./bin/brute_force data/tsp2_1248.txt"
    echo "Saída:"
    echo "----------------------------------------"
    
    timeout 30 ./bin/brute_force data/tsp2_1248.txt 2>&1
    tsp2_exit_code=$?
    
    echo "----------------------------------------"
    echo "Exit code: $tsp2_exit_code"
    
    if [ $tsp2_exit_code -eq 0 ]; then
        echo -e "${GREEN}✅ TSP2 funcionou perfeitamente!${NC}"
    elif [ $tsp2_exit_code -eq 124 ]; then
        echo -e "${YELLOW}⏱️ TSP2 deu timeout (>30s - estranho para 6 cidades)${NC}"
    else
        echo -e "${RED}❌ TSP2 falhou!${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ tsp2_1248.txt não encontrado, pulando teste${NC}"
fi

# 5. TESTE RÁPIDO COM TSP3
echo ""
echo -e "${BLUE}5. TESTE RÁPIDO COM TSP3...${NC}"
echo ""

if [ -f "data/tsp3_1194.txt" ]; then
    echo "🧪 Testando tsp3_1194.txt por 10 segundos (só para ver se inicia)..."
    echo "Comando: timeout 10 ./bin/brute_force data/tsp3_1194.txt"
    echo "Saída:"
    echo "----------------------------------------"
    
    timeout 10 ./bin/brute_force data/tsp3_1194.txt 2>&1
    tsp3_exit_code=$?
    
    echo "----------------------------------------"
    echo "Exit code: $tsp3_exit_code"
    
    if [ $tsp3_exit_code -eq 124 ]; then
        echo -e "${GREEN}✅ TSP3 iniciou corretamente!${NC}"
        echo "   (Timeout é esperado - programa estava rodando)"
    elif [ $tsp3_exit_code -eq 0 ]; then
        echo -e "${RED}❌ TSP3 terminou muito rápido!${NC}"
        echo "   Isso indica problema no arquivo ou algoritmo"
    else
        echo -e "${RED}❌ TSP3 deu erro!${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ tsp3_1194.txt não encontrado${NC}"
fi

# 6. DIAGNÓSTICO FINAL
echo ""
echo -e "${BLUE}6. DIAGNÓSTICO FINAL...${NC}"
echo ""

if [ $test_exit_code -eq 0 ]; then
    if [ -f "data/tsp3_1194.txt" ]; then
        lines=$(wc -l < "data/tsp3_1194.txt")
        if [ "$lines" -eq 15 ]; then
            echo -e "${GREEN}✅ TUDO PARECE OK!${NC}"
            echo ""
            echo "💡 PRÓXIMOS PASSOS:"
            echo "   1. Execute TSP3 manualmente:"
            echo "      nohup ./bin/brute_force data/tsp3_1194.txt > tsp3_result.log 2>&1 &"
            echo "   2. Monitore com:"
            echo "      tail -f tsp3_result.log"
            echo "   3. Aguarde ~17 horas para conclusão"
        else
            echo -e "${RED}❌ PROBLEMA: tsp3_1194.txt tem $lines linhas (deveria ter 15)${NC}"
            echo "   Verifique se o arquivo está correto"
        fi
    else
        echo -e "${RED}❌ PROBLEMA: tsp3_1194.txt não encontrado${NC}"
    fi
else
    echo -e "${RED}❌ PROBLEMA: Programa não funciona corretamente${NC}"
    echo "   Verifique compilação e dependências"
fi

echo ""
echo "🏁 Diagnóstico concluído!"
