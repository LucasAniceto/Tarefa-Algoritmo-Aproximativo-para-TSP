#!/bin/bash

echo "=== COMPILAÇÃO JAVA DEDICADA ==="

JAVA_DIR="src/java/exact"

if [ ! -d "$JAVA_DIR" ]; then
    echo "❌ Diretório $JAVA_DIR não encontrado"
    exit 1
fi

cd "$JAVA_DIR"

echo "📁 Diretório atual: $(pwd)"
echo "📄 Arquivos Java disponíveis:"
ls -la *.java 2>/dev/null || echo "Nenhum arquivo .java encontrado"

# Remover arquivos .class antigos
echo "🧹 Removendo arquivos .class antigos..."
rm -f *.class

# Lista de arquivos na ordem de compilação
FILES=(
    "TSPInstance.java"
    "TSPResult.java" 
    "BruteForce.java"
    "BranchBound.java"
    "TSPSolver.java"
)

echo "🔨 Compilando na ordem de dependências..."

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  Compilando $file..."
        javac "$file"
        if [ $? -eq 0 ]; then
            echo "  ✅ $file compilado com sucesso"
        else
            echo "  ❌ Erro compilando $file"
            exit 1
        fi
    else
        echo "  ⚠️ Arquivo $file não encontrado"
        exit 1
    fi
done

echo ""
echo "📊 Arquivos .class gerados:"
ls -la *.class

echo ""
echo "🧪 Testando compilação..."
echo "  Testando BruteForce..."
java BruteForce ../../../data/tsp2_1248.txt > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "  ✅ BruteForce funciona"
else
    echo "  ❌ BruteForce com problemas"
fi

echo "  Testando BranchBound..."
java BranchBound ../../../data/tsp2_1248.txt > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "  ✅ BranchBound funciona"
else
    echo "  ❌ BranchBound com problemas"
fi

cd ../../..
echo ""
echo "🎉 Compilação Java concluída!"
echo "Para testar:"
echo "  cd src/java/exact"
echo "  java BruteForce ../../../data/tsp2_1248.txt"
echo "  java BranchBound ../../../data/tsp2_1248.txt"
