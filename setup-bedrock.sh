#!/data/data/com.termux/files/usr/bin/bash
set -e

API_URL="https://net-secondary.web.minecraft-services.net/api/v1.0/download/links"
INSTALL_DIR="$HOME/bedrock-server"

echo "========================================"
echo "  Minecraft Bedrock Server - Termux"
echo "  (sin proot, glibc + Box64)"
echo "========================================"
echo ""

# --- 1. Actualizar Termux ---
echo "[1/5] Actualizando Termux..."
pkg update -y
pkg upgrade -y
pkg install wget curl unzip nano git jq cmake make -y

pkg install glibc-repo -y
echo "  OK"
echo ""

# --- 2. Compilar Box64 ---
echo "[2/5] Compilando Box64..."
cd ~
if [ ! -d box64 ]; then
  git clone https://github.com/ptitSeb/box64
fi
cd box64
sed -i 's|/usr|/data/data/com.termux/files/usr/glibc|g' CMakeLists.txt 2>/dev/null || true
sed -i 's|/etc|/data/data/com.termux/files/usr/glibc/etc|g' CMakeLists.txt 2>/dev/null || true
mkdir -p build && cd build
cmake --install-prefix $PREFIX/glibc .. -DARM_DYNAREC=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBAD_SIGNAL=ON -DSD845=ON
make -j$(nproc)
make install
echo "  OK"
echo ""

# Verificar Box64
if ! command -v box64 &>/dev/null; then
  echo "[ERROR] Box64 no se instaló correctamente."
  exit 1
fi
echo "  Box64 version: $(box64 --version 2>&1)"
echo ""

# --- 3. Descargar Bedrock Server ---
echo "[3/5] Descargando Bedrock Server..."
echo "  Consultando API para obtener última versión..."
DATA=$(curl -fsSL "$API_URL")
BEDROCK_URL=$(echo "$DATA" | jq -r '.result.links[] | select(.downloadType == "serverBedrockLinux") | .downloadUrl')
BEDROCK_VERSION=$(echo "$BEDROCK_URL" | grep -oP '\d+\.\d+\.\d+\.\d+' | head -1)

if [ -z "$BEDROCK_URL" ] || [ "$BEDROCK_URL" = "null" ]; then
  echo "[ERROR] No se pudo obtener la URL de descarga."
  echo "  Revisa: $API_URL"
  exit 1
fi

rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"
echo "  Versión: $BEDROCK_VERSION"
echo "  Descargando..."
wget "$BEDROCK_URL" -O bedrock-server.zip
unzip -q bedrock-server.zip
rm bedrock-server.zip
echo "  OK"
echo ""

# --- 4. Crear script de inicio ---
echo "[4/5] Creando script de inicio..."
cat > start.sh << 'SHEOF'
#!/data/data/com.termux/files/usr/bin/bash
export GLIBC_PREFIX=/data/data/com.termux/files/usr/glibc
export BOX64_PATH=$GLIBC_PREFIX/bin
export BOX64_LD_LIBRARY_PATH=$GLIBC_PREFIX/lib
export LD_LIBRARY_PATH=$GLIBC_PREFIX/lib
cd "$(dirname "$0")"
echo "Iniciando Minecraft Bedrock Server..."
echo "GLIBC_PREFIX=$GLIBC_PREFIX"
box64 ./bedrock_server
SHEOF
chmod +x start.sh
echo "  OK"
echo ""

# --- 5. Configurar server.properties ---
echo "[5/5] Configuración inicial de server.properties..."
if [ -f server.properties ]; then
  sed -i 's/^server-name=.*/server-name=Bedrock Android Server/' server.properties
  sed -i 's/^max-players=.*/max-players=10/' server.properties
  sed -i 's/^view-distance=.*/view-distance=10/' server.properties
  sed -i 's/^tick-distance=.*/tick-distance=4/' server.properties
fi
echo "  OK"
echo ""

# --- Fin ---
echo "========================================"
echo "  Instalación completada"
echo "========================================"
echo ""
echo "Directorio: $INSTALL_DIR"
echo ""
echo "Para iniciar el servidor:"
echo "  cd ~/bedrock-server && ./start.sh"
echo ""
echo "Para mantenerlo en segundo plano (tmux):"
echo "  pkg install tmux -y"
echo "  tmux new -s minecraft"
echo "  cd ~/bedrock-server && ./start.sh"
echo "  # Ctrl+B luego D para salir"
echo "  # tmux attach -t minecraft para volver"
echo ""
echo "IP local del dispositivo:"
ip addr show wlan0 2>/dev/null | grep "inet " | awk '{print $2}' || echo "  (wlan0 no disponible)"
echo ""
echo "Puerto: 19132"
echo "========================================"
