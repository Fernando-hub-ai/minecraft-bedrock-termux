# Servidor de Minecraft Bedrock en Termux (sin proot)

[![English](https://img.shields.io/badge/lang-en-blue)](README.md)

Guía paso a paso para ejecutar el servidor oficial de Minecraft Bedrock (BDS) en Termux **sin usar proot-distro**, solo con Termux nativo + glibc + Box64.

## Requisitos

- Dispositivo Android con arquitectura **ARM64** (aarch64)
- **4 GB+ de RAM** (recomendado 6 GB+)
- **2 GB+ de espacio libre**
- Android 10 o superior
- Termux instalado desde **F-Droid** (la versión de Play Store está desactualizada)

## Instalación

### 1. Preparar Termux

```bash
pkg update && pkg upgrade -y
pkg install wget curl unzip nano -y
```

### 2. Instalar repositorio glibc

```bash
pkg install glibc-repo glibc-runner -y
```

Esto permite ejecutar binarios de Linux (glibc) directamente en Termux.

### 3. Compilar e instalar Box64

Box64 traduce binarios x86_64 a ARM64. El servidor oficial de Bedrock es x86_64.

```bash
# Dependencias de compilación
pkg install git cmake-glibc make-glibc python-glibc -y

# Clonar Box64
cd ~
git clone https://github.com/ptitSeb/box64
cd box64

# Parchear rutas para Termux glibc
sed -i 's|/usr|/data/data/com.termux/files/usr/glibc|g' CMakeLists.txt
sed -i 's|/etc|/data/data/com.termux/files/usr/glibc/etc|g' CMakeLists.txt

# Compilar
mkdir build && cd build
cmake --install-prefix $PREFIX/glibc .. \
  -DARM_DYNAREC=1 \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DBAD_SIGNAL=ON \
  -DSD845=ON
make -j$(nproc)
make install
```

Verifica que Box64 se instaló:

```bash
box64 --version
```

### 4. Descargar el servidor oficial de Minecraft Bedrock

Ve a la [página oficial de Minecraft Bedrock Server](https://www.minecraft.net/en-us/download/server/bedrock) y copia el enlace de descarga para Linux, o usa:

```bash
cd ~
mkdir bedrock-server && cd bedrock-server

# Descargar la última versión (reemplaza la URL con la actual)
wget https://minecraft.azureedge.net/bin-linux/bedrock-server-1.21.73.02.zip

# Si el enlace cambia, descarga manualmente desde:
# https://www.minecraft.net/en-us/download/server/bedrock
```

Extraer:

```bash
unzip bedrock-server-*.zip
rm bedrock-server-*.zip
```

### 5. Configurar el servidor

Edita `server.properties`:

```bash
nano server.properties
```

Ajustes recomendados para Android:

```properties
server-port=19132
server-portv6=19133
server-name=Servidor Bedrock Android
gamemode=survival
difficulty=normal
max-players=10
view-distance=10
tick-distance=4
correct-player-movement=false
```

### 6. Crear script de inicio

```bash
nano start.sh
```

Contenido:

```bash
#!/data/data/com.termux/files/usr/bin/bash
export GLIBC_PREFIX=/data/data/com.termux/files/usr/glibc
export BOX64_PATH=$GLIBC_PREFIX/bin
export BOX64_LD_LIBRARY_PATH=$GLIBC_PREFIX/lib
export LD_LIBRARY_PATH=$GLIBC_PREFIX/lib
cd "$(dirname "$0")"
box64 ./bedrock_server
```

Dar permisos:

```bash
chmod +x start.sh
```

### 7. Iniciar el servidor

```bash
./start.sh
```

## Conectarse al servidor

### Red local

La IP local del dispositivo se obtiene con:

```bash
ip addr show wlan0 | grep "inet "
```

En Minecraft Bedrock → **Servidores → Añadir servidor** → IP local + puerto `19132`.

### Internet (con Playit.gg)

Playit.gg crea un túnel sin necesidad de abrir puertos.

```bash
# Descargar Playit
curl -SsL https://playit.gg/download -o playit
chmod +x playit

# Ejecutar para vincular
./playit
```

Sigue las instrucciones para vincular tu túnel al puerto `19132`.

## Script de arranque rápido

Guarda esto como `setup-bedrock.sh`:

```bash
#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "[1/5] Actualizando Termux..."
pkg update && pkg upgrade -y
pkg install wget curl unzip nano git cmake-glibc make-glibc python-glibc -y
pkg install glibc-repo glibc-runner -y

echo "[2/5] Compilando Box64..."
cd ~
[ -d box64 ] || git clone https://github.com/ptitSeb/box64
cd box64
sed -i 's|/usr|/data/data/com.termux/files/usr/glibc|g' CMakeLists.txt
sed -i 's|/etc|/data/data/com.termux/files/usr/glibc/etc|g' CMakeLists.txt
mkdir -p build && cd build
cmake --install-prefix $PREFIX/glibc .. -DARM_DYNAREC=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBAD_SIGNAL=ON -DSD845=ON
make -j$(nproc)
make install

echo "[3/5] Descargando Bedrock Server..."
cd ~
mkdir -p bedrock-server && cd bedrock-server
wget https://minecraft.azureedge.net/bin-linux/bedrock-server-1.21.73.02.zip
unzip bedrock-server-*.zip
rm bedrock-server-*.zip

echo "[4/5] Creando script de inicio..."
cat > start.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
export GLIBC_PREFIX=/data/data/com.termux/files/usr/glibc
export BOX64_PATH=$GLIBC_PREFIX/bin
export BOX64_LD_LIBRARY_PATH=$GLIBC_PREFIX/lib
export LD_LIBRARY_PATH=$GLIBC_PREFIX/lib
cd "$(dirname "$0")"
box64 ./bedrock_server
EOF
chmod +x start.sh

echo "[5/5] Instalación completa."
echo "Para iniciar: cd ~/bedrock-server && ./start.sh"
```

## Notas importantes

- **Rendimiento:** Box64 añade overhead. Espera entre 5-15 jugadores según la RAM.
- **Mantener en segundo plano:** Usa `tmux` para mantener el servidor corriendo al cerrar Termux:
  ```bash
  pkg install tmux -y
  tmux new -s minecraft
  ./start.sh
  # Ctrl+B luego D para desconectarte
  # tmux attach -t minecraft para volver
  ```
- **Actualizar servidor:** Descarga la nueva versión, extrae sobre la carpeta existente (sin borrar `worlds/`).
- **Crash aleatorio:** Box64 + BDS puede ser inestable en Android. Reduce `view-distance` y `tick-distance` si hay crashes.

## Licencia

MIT
