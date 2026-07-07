# Minecraft Bedrock Server on Termux (without proot)

[![Español](https://img.shields.io/badge/lang-es-yellow)](README.es.md)

Step-by-step guide to run the official Minecraft Bedrock Dedicated Server (BDS) on Termux **without proot-distro**, using native Termux + glibc + Box64.

## Requirements

- Android device with **ARM64** architecture (aarch64)
- **4 GB+ RAM** (6 GB+ recommended)
- **2 GB+ free storage**
- Android 10 or higher
- Termux installed from **F-Droid** (Play Store version is outdated)

## Installation

### 1. Prepare Termux

```bash
pkg update && pkg upgrade -y
pkg install wget curl unzip nano jq -y
```

### 2. Install glibc repository

```bash
pkg install glibc-repo -y
```

This enables running Linux (glibc) binaries directly in Termux.

### 3. Compile and install Box64

Box64 translates x86_64 binaries to ARM64. The official Bedrock server is x86_64.

```bash
# Build dependencies
pkg install git cmake make -y

# Clone Box64
cd ~
git clone https://github.com/ptitSeb/box64
cd box64

# Patch paths for Termux glibc
sed -i 's|/usr|/data/data/com.termux/files/usr/glibc|g' CMakeLists.txt
sed -i 's|/etc|/data/data/com.termux/files/usr/glibc/etc|g' CMakeLists.txt

# Build
mkdir build && cd build
cmake --install-prefix $PREFIX/glibc .. \
  -DARM_DYNAREC=1 \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DBAD_SIGNAL=ON \
  -DSD845=ON
make -j$(nproc)
make install
```

Verify Box64 installation:

```bash
box64 --version
```

### 4. Download the official Minecraft Bedrock Server

Use the API to get the latest version download link:

```bash
cd ~
mkdir bedrock-server && cd bedrock-server

# Get download URL from Mojang API
curl -fsSL https://net-secondary.web.minecraft-services.net/api/v1.0/download/links \
  | jq -r '.result.links[] | select(.downloadType == "serverBedrockLinux") | .downloadUrl' \
  | xargs wget -O bedrock-server.zip
```

Extract:

```bash
unzip -q bedrock-server.zip
rm bedrock-server.zip
```

### 5. Configure the server

Edit `server.properties`:

```bash
nano server.properties
```

Recommended settings for Android:

```properties
server-port=19132
server-portv6=19133
server-name=Bedrock Android Server
gamemode=survival
difficulty=normal
max-players=10
view-distance=10
tick-distance=4
correct-player-movement=false
```

### 6. Create startup script

```bash
nano start.sh
```

Content:

```bash
#!/data/data/com.termux/files/usr/bin/bash
export GLIBC_PREFIX=/data/data/com.termux/files/usr/glibc
export BOX64_PATH=$GLIBC_PREFIX/bin
export BOX64_LD_LIBRARY_PATH=$GLIBC_PREFIX/lib
export LD_LIBRARY_PATH=$GLIBC_PREFIX/lib
cd "$(dirname "$0")"
box64 ./bedrock_server
```

Make it executable:

```bash
chmod +x start.sh
```

### 7. Start the server

```bash
./start.sh
```

## Connecting to the server

### Local network

Get your device's local IP:

```bash
ip addr show wlan0 | grep "inet "
```

In Minecraft Bedrock → **Servers → Add Server** → local IP + port `19132`.

### Internet (with Playit.gg)

Playit.gg creates a tunnel without opening ports.

```bash
# Download Playit
curl -SsL https://playit.gg/download -o playit
chmod +x playit

# Run to link
./playit
```

Follow the instructions to link your tunnel to port `19132`.

## Quick setup script

Save as `setup-bedrock.sh`:

```bash
#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "[1/5] Updating Termux..."
pkg update && pkg upgrade -y
pkg install wget curl unzip nano git jq cmake make -y
pkg install glibc-repo -y
echo "[2/5] Compiling Box64..."
cd ~
[ -d box64 ] || git clone https://github.com/ptitSeb/box64
cd box64
sed -i 's|/usr|/data/data/com.termux/files/usr/glibc|g' CMakeLists.txt
sed -i 's|/etc|/data/data/com.termux/files/usr/glibc/etc|g' CMakeLists.txt
mkdir -p build && cd build
cmake --install-prefix $PREFIX/glibc .. -DARM_DYNAREC=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBAD_SIGNAL=ON -DSD845=ON
make -j$(nproc)
make install

echo "[3/5] Downloading Bedrock Server..."
cd ~
mkdir -p bedrock-server && cd bedrock-server
curl -fsSL https://net-secondary.web.minecraft-services.net/api/v1.0/download/links \
  | jq -r '.result.links[] | select(.downloadType == "serverBedrockLinux") | .downloadUrl' \
  | xargs wget -O bedrock-server.zip
unzip -q bedrock-server.zip
rm bedrock-server.zip

echo "[4/5] Creating startup script..."
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

echo "[5/5] Installation complete."
echo "To start: cd ~/bedrock-server && ./start.sh"
```

## Important notes

- **Performance:** Box64 adds overhead. Expect 5-15 players depending on RAM.
- **Keep running in background:** Use `tmux` to keep the server running after closing Termux:
  ```bash
  pkg install tmux -y
  tmux new -s minecraft
  ./start.sh
  # Ctrl+B then D to detach
  # tmux attach -t minecraft to reattach
  ```
- **Update server:** Download the new version, extract over the existing folder (don't delete `worlds/`).
- **Random crashes:** Box64 + BDS can be unstable on Android. Reduce `view-distance` and `tick-distance` if crashes occur.

## License

MIT
