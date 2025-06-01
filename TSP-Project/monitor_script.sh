#!/bin/bash

echo "📊 === MONITOR DE EXPERIMENTOS TSP ==="
echo ""

# Função para mostrar status
show_status() {
    echo "🔍 Verificando processos TSP..."
    
    # Verifica processos relacionados
    tsp_processes=$(ps aux | grep -E "(compare_languages|brute_force|mst_approx|java.*TSP)" | grep -v grep)
    
    if [[ -n "$tsp_processes" ]]; then
        echo "✅ Processos TSP encontrados:"
        echo "$tsp_processes"
        echo ""
    else
        echo "❌ Nenhum processo TSP ativo encontrado"
        echo ""
    fi
    
    # Verifica arquivo de log mais recente
    latest_log=$(ls -t experimento_tsp_*.log 2>/dev/null | head -1)
    if [[ -n "$latest_log" ]]; then
        echo "📄 Log mais recente: $latest_log"
        echo "📏 Tamanho: $(du -h "$latest_log" | cut -f1)"
        echo "🕐 Última modificação: $(date -r "$latest_log")"
        echo ""
        
        echo "📋 Últimas 10 linhas do log:"
        tail -10 "$latest_log"
        echo ""
    fi
    
    # Verifica resultados parciais
    if [[ -f "results/comparacao_linguagens.csv" ]]; then
        echo "📊 Resultados parciais encontrados:"
        echo "   Linhas no CSV: $(wc -l < results/comparacao_linguagens.csv)"
        echo "   Últimos resultados:"
        tail -5 results/comparacao_linguagens.csv
        echo ""
    fi
}

# Função para seguir o log em tempo real
follow_log() {
    latest_log=$(ls -t experimento_tsp_*.log 2>/dev/null | head -1)
    if [[ -n "$latest_log" ]]; then
        echo "📺 Seguindo log em tempo real: $latest_log"
        echo "   (Ctrl+C para parar)"
        echo ""
        tail -f "$latest_log"
    else
        echo "❌ Nenhum arquivo de log encontrado"
    fi
}

# Função para parar experimento
stop_experiment() {
    if [[ -f "tsp_experiment.pid" ]]; then
        pid=$(cat tsp_experiment.pid)
        echo "🛑 Parando experimento (PID: $pid)..."
        kill $pid 2>/dev/null
        if [[ $? -eq 0 ]]; then
            echo "✅ Processo parado com sucesso"
            rm -f tsp_experiment.pid
        else
            echo "⚠️  Processo pode já ter terminado"
        fi
    else
        echo "❌ Arquivo PID não encontrado. Tentando parar processos relacionados..."
        pkill -f compare_languages.sh
        pkill -f brute_force
        echo "✅ Tentativa de parada concluída"
    fi
}

# Menu principal
while true; do
    echo "📋 Opções:"
    echo "  1) Mostrar status atual"
    echo "  2) Seguir log em tempo real"
    echo "  3) Parar experimento"
    echo "  4) Sair"
    echo ""
    
    read -p "Escolha uma opção (1-4): " opcao
    
    case $opcao in
        1)
            show_status
            ;;
        2)
            follow_log
            ;;
        3)
            stop_experiment
            ;;
        4)
            echo "👋 Saindo do monitor..."
            exit 0
            ;;
        *)
            echo "❌ Opção inválida!"
            ;;
    esac
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
done
