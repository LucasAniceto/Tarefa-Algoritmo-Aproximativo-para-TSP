#!/bin/bash

echo "🚀 === INICIADOR DE EXPERIMENTOS TSP EM BACKGROUND ==="
echo ""

# Verifica se o script principal existe
if [[ ! -f "compare_languages.sh" ]]; then
    echo "❌ Arquivo compare_languages.sh não encontrado!"
    echo "   Certifique-se de que está no diretório correto"
    exit 1
fi

# Torna o script executável
chmod +x compare_languages.sh

echo "📋 Opções de execução:"
echo "  1) Executar em foreground (normal)"
echo "  2) Executar em background com nohup"
echo "  3) Executar em screen (recomendado para sessões longas)"
echo ""

read -p "Escolha uma opção (1-3): " opcao

case $opcao in
    1)
        echo "🔥 Executando em foreground..."
        ./compare_languages.sh
        ;;
    2)
        echo "🚀 Executando em background com nohup..."
        timestamp=$(date +"%Y%m%d_%H%M%S")
        logfile="experimento_tsp_${timestamp}.log"
        
        nohup ./compare_languages.sh > "$logfile" 2>&1 &
        pid=$!
        
        echo "✅ Processo iniciado em background!"
        echo "   PID: $pid"
        echo "   Log: $logfile"
        echo ""
        echo "📋 Comandos úteis:"
        echo "   tail -f $logfile          # Ver progresso em tempo real"
        echo "   ps aux | grep $pid        # Verificar se ainda está rodando"
        echo "   kill $pid                 # Parar o processo (se necessário)"
        echo ""
        echo "⚠️  IMPORTANTE: Não feche o WSL completamente!"
        
        # Salva o PID para referência
        echo $pid > tsp_experiment.pid
        echo "   PID salvo em: tsp_experiment.pid"
        ;;
    3)
        echo "📺 Verificando se screen está instalado..."
        if ! command -v screen &> /dev/null; then
            echo "❌ Screen não encontrado. Instalando..."
            sudo apt update && sudo apt install screen -y
        fi
        
        echo "🚀 Iniciando sessão screen..."
        echo "   Nome da sessão: tsp_experimento"
        echo ""
        echo "📋 Controles do screen:"
        echo "   Ctrl+A, depois D  = Desconectar (deixar rodando)"
        echo "   screen -r tsp_experimento = Reconectar"
        echo "   screen -ls = Listar sessões"
        echo ""
        echo "Pressione ENTER para continuar..."
        read
        
        screen -S tsp_experimento ./compare_languages.sh
        ;;
    *)
        echo "❌ Opção inválida!"
        exit 1
        ;;
esac

echo ""
echo "🏁 Script iniciado conforme opção selecionada"
