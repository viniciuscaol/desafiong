#!/bin/bash
# Script Mestre: Instala, configura e ativa o serviço de monitoramento.

# --- VARIÁVEIS DE CONFIGURAÇÃO CORRIGIDAS ---
# Obtém o nome do usuário que invocou o script com 'sudo'
USER_NAME=$SUDO_USER 
HOME_DIR=$(getent passwd "$USER_NAME" | cut -d: -f6)

WATCHER_SCRIPT="$HOME_DIR/desafiong/desafio3/script.sh"
SERVICE_FILE="/etc/systemd/system/file-watcher.service"
INBOX_DIR="$HOME_DIR/desafiong/desafio3/inbox"
PROCESSED_DIR="$HOME_DIR/desafiong/desafio3/processed"
LOG_DIR="$HOME_DIR/desafiong/desafio3/log"
LOG_FILE="$LOG_DIR/script.log"

echo "=== INÍCIO DO PROVISIONAMENTO ==="

# 1. Checagem de Privilégios
if [ "$EUID" -ne 0 ]; then
  echo "ERRO: Por favor, execute este script com sudo ou como root."
  exit 1
fi

# 2. Instalar Pré-requisitos (inotify-tools)
install_prereqs() {
    echo "1. Instalando inotify-tools..."
    if command -v apt >/dev/null; then
        apt update && apt install inotify-tools -y
    elif command -v yum >/dev/null; then
        yum install inotify-tools -y
    else
        echo "ERRO: Gerenciador de pacotes não suportado (apenas apt/yum)."
        exit 1
    fi
}

# 3. Criar Diretórios e Log (Utilizando HOME_DIR absoluta)
create_dirs() {
    echo "2. Criando diretórios de monitoramento..."
    mkdir -p "$INBOX_DIR"
    mkdir -p "$PROCESSED_DIR"
    mkdir -p "$LOG_DIR"
    touch "$LOG_FILE"
    
    # Garante que as pastas e o script pertencem ao usuário, não ao root
    chown -R "$USER_NAME":"$USER_NAME" "$HOME_DIR/desafiong"
}

# 4. Criar o Script de Monitoramento (script.sh)
create_watcher_script() {
    echo "3. Criando o script de monitoramento: $WATCHER_SCRIPT"
    
    cat << EOF > "$WATCHER_SCRIPT"
#!/bin/bash
# Script de monitoramento do inotify

WATCH_DIR="$INBOX_DIR"
DEST_DIR="$PROCESSED_DIR"
LOG_FILE="$LOG_FILE"

echo "\$(date): Serviço de monitoramento iniciado pelo systemd." >> "\$LOG_FILE"

/usr/bin/inotifywait -m -e close_write --format '%f' "\$WATCH_DIR" | while read FILENAME
do
    echo "\$(date): Arquivo detectado: \$FILENAME" >> "\$LOG_FILE"
    if [ -f "\$WATCH_DIR/\$FILENAME" ]; then
        /bin/mv "\$WATCH_DIR/\$FILENAME" "\$DEST_DIR/\$FILENAME"
        echo "\$(date): Arquivo movido com sucesso." >> "\$LOG_FILE"
    fi
done
EOF

    chmod +x "$WATCHER_SCRIPT"
    chown "$USER_NAME":"$USER_NAME" "$WATCHER_SCRIPT"
}

# 5. Criar o Arquivo de Serviço systemd (ExecStart usa caminho absoluto)
create_service_file() {
    echo "4. Criando o arquivo de serviço systemd: $SERVICE_FILE"
    cat << EOF > "$SERVICE_FILE"
[Unit]
Description=Serviço de Monitoramento de Diretório (Inotify)
After=network.target

[Service]
Type=simple
ExecStart=$WATCHER_SCRIPT
Restart=always
# CRÍTICO: Roda o serviço com o seu usuário, o proprietário das pastas.
User=$USER_NAME 
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
}

# 6. Ativar e Iniciar o Serviço
activate_service() {
    echo "5. Ativando e iniciando o serviço..."
    # Os comandos do systemctl devem ser executados pelo root (sudo)
    systemctl daemon-reload
    systemctl enable file-watcher.service
    systemctl start file-watcher.service
    echo "Verificando o status..."
    systemctl status file-watcher.service | grep 'Active:'
    echo "=== PROVISIONAMENTO CONCLUÍDO! ==="
    echo "Diretórios: $INBOX_DIR -> $PROCESSED_DIR"
    echo "Verifique o log em: $LOG_FILE"
}

# --- Execução Principal ---
install_prereqs
create_dirs
create_watcher_script
create_service_file
activate_service