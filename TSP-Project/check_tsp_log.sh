#!/bin/bash

# Script para verificar o log do TSP3 e descobrir onde travou

echo "🔍 === VERIFICANDO LOG TSP3 ==="
echo "📅 $(date)"
echo ""

LOG_FILE="results/tsp3_1194_20250526_001028.log"

if [ -f "$LOG_FILE" ]; then
    echo "✅ Log encontrado: $LOG_FILE"
    echo "📊 Tamanho: $(du -h "$LOG_FILE" | cut -f1)"
    echo "📊 Linhas: $(wc -l < "$LOG_FILE")"
    echo "📊 Última modificação: $(stat -c %y "$LOG_FILE" 2>/dev/null || stat -f %Sm "$LOG_FILE")"
    echo ""
    
    echo "📄 === CONTEÚDO COMPLETO DO LOG ==="
    echo "----------------------------------------"
    cat "$LOG_FILE"
    echo "----------------------------------------"
    echo ""
    
    echo "🔍 === ANÁLISE ==="
    
    # Verificar se programa iniciou
    if grep -q "Iniciando força bruta" "$LOG_FILE"; then
        echo "✅ Programa iniciou corretamente"
        
        # Verificar cálculo de permutações
        if grep -q "Número de permutações" "$LOG_FILE"; then
            perms=$(grep "Número de permutações" "$LOG_FILE" | awk '{print $NF}')
            echo "✅ Calculou permutações: $perms"
        else
            echo "❌ NÃO calculou permutações - travou antes"
        fi
        
        # Verificar se está processando
        if grep -q "Nova melhor solução" "$LOG_FILE"; then
            echo "✅ Está encontrando soluções"
        else
            echo "⚠️  Ainda não encontrou soluções (pode ser normal no início)"
        fi
        
        # Verificar se há erro
        if grep -iq "erro\|error\|segmentation\|fault" "$LOG_FILE"; then
            echo "❌ ERRO encontrado no log:"
            grep -i "erro\|error\|segmentation\|fault" "$LOG_FILE"
        fi
        
    else
        echo "❌ Programa NÃO iniciou - problema na execução"
    fi
    
else
    echo "❌ Log não encontrado: $LOG_FILE"
    echo ""
    echo "🔍 Procurando outros logs..."
    find results/ -name "*tsp3*.log" -o -name "*20250526*.log" 2>/dev/null | while read log; do
        echo "📄 Encontrado: $log"
        echo "   Tamanho: $(du -h "$log" | cut -f1)"
        echo "   Conteúdo:"
        cat "$log" | sed 's/^/      /'
        echo ""
    done
fi

echo ""
echo "💡 === DIAGNÓSTICO ==="

# Verificar se processo ainda existe
if kill -0 814 2>/dev/null; then
    echo "✅ Processo PID 814 ainda está rodando"
    
    # Ver status atual
    status=$(ps -p 814 -o stat --no-headers 2>/dev/null)
    cpu=$(ps -p 814 -o %cpu --no-headers 2>/dev/null)
    
    echo "   Status: $status"
    echo "   CPU: $cpu%"
    
    if [ "$status" = "S+" ] || [ "$status" = "S" ]; then
        echo "❌ Processo está SLEEPING (pausado/travado)"
        echo "   Possíveis causas:"
        echo "   • Aguardando input do usuário"
        echo "   • Deadlock interno"
        echo "   • Problema de memória"
        echo "   • Bug no código"
    elif [[ "$status" == "R"* ]]; then
        echo "✅ Processo está RUNNING (executando)"
    fi
    
else
    echo "❌ Processo PID 814 não existe mais"
fi

echo ""
echo "🎯 === PRÓXIMOS PASSOS ==="

if [ -f "$LOG_FILE" ] && [ -s "$LOG_FILE" ]; then
    if grep -q "Iniciando força bruta" "$LOG_FILE" && ! grep -q "Número de permutações" "$LOG_FILE"; then
        echo "🔧 PROBLEMA: Travou após iniciar mas antes de calcular permutações"
        echo ""
        echo "💡 SOLUÇÕES:"
        echo "1. Matar processo e executar com timeout menor para debug:"
        echo "   kill 814"
        echo "   timeout 60 ./bin/brute_force data/tsp3_1194.txt"
        echo ""
        echo "2. Verificar se há confirmação esperando:"
        echo "   (Pode ter pergunta oculta no código)"
        echo ""
        echo "3. Compilar com debug symbols:"
        echo "   gcc -g -O0 -o bin/brute_force_debug src/c/exact/brute_force.c"
        echo "   gdb ./bin/brute_force_debug"
        
    elif [ ! -s "$LOG_FILE" ]; then
        echo "🔧 PROBLEMA: Log vazio - processo não consegue escrever"
        echo ""
        echo "💡 SOLUÇÕES:"
        echo "1. Verificar permissões:"
        echo "   ls -la results/"
        echo "   touch results/test.txt"
        echo ""
        echo "2. Executar direto no terminal:"
        echo "   kill 814"
        echo "   ./bin/brute_force data/tsp3_1194.txt"
        
    else
        echo "🔧 Analise o log acima para identificar onde travou"
    fi
else
    echo "🔧 PROBLEMA: Nenhum log encontrado"
    echo ""
    echo "💡 SOLUÇÕES:"
    echo "1. Executar direto para ver output:"
    echo "   kill 814"
    echo "   ./bin/brute_force data/tsp3_1194.txt"
fi
