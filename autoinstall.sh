#!/bin/bash

# Caminho para o arquivo de controle
CONTROL_FILE="/tmp/script_status"

# Caminho do arquivo de serviço systemd
SERVICE_FILE="/etc/systemd/system/config-script.service"

# Função para verificar o progresso do script
check_progress() {
    if [ -f "$CONTROL_FILE" ]; then
        STEP=$(cat "$CONTROL_FILE")
    else
        STEP=0
    fi
}

# Função para salvar o progresso
save_progress() {
    echo $1 > "$CONTROL_FILE"
}

# Função para configurar reinício automático
configure_autorun() {
    echo "Configurando o serviço para reinício automático após reboot..."
    sudo bash -c "cat > $SERVICE_FILE" <<EOF
[Unit]
Description=Configuração Prime Stream
After=network.target

[Service]
ExecStart=/bin/bash $0
Restart=on-failure
User=$(whoami)

[Install]
WantedBy=default.target
EOF

    echo "Ativando o serviço no systemd..."
    sudo systemctl enable config-script.service
    echo "Serviço configurado com sucesso!"
}

# Função para remover o reinício automático
remove_autorun() {
    echo "Removendo configuração de reinício automático..."
    if [ -f "$SERVICE_FILE" ]; then
        sudo systemctl disable config-script.service
        sudo rm -f "$SERVICE_FILE"
        echo "Configuração de reinício automático removida!"
    else
        echo "Nenhuma configuração de reinício automático encontrada."
    fi
}

# Função para verificar a execução de comandos e tratar erros
check_command() {
    if [ $? -ne 0 ]; then
        echo "Erro durante a execução do comando: $1. Abortando o script."
        exit 1
    fi
}

# Limpar a tela
clear
echo -e "\033[1;32m"
echo "######## +PRIME STREAM ACADEMY+ ###########"
echo "# Bem-vindo ao script de configuração!    #"
echo "# Este script irá configurar sua máquina  #"
echo "# com os pacotes necessários e serviços! #"
echo "###########################################"
echo -e "\033[0m"
echo ""

# Etapa 1: Configuração inicial
echo "Configurando fuso horário para America/Sao_Paulo..."
sudo timedatectl set-timezone America/Sao_Paulo
check_command "Configuração de fuso horário"

echo "Atualizando pacotes..."
sudo apt update
check_command "Atualização de pacotes"

echo "Aplicando upgrades..."
sudo apt upgrade -y
check_command "Aplicação de upgrades"

# Pausa de 4 segundos
sleep 4

# Etapa 2: Instalação de pacotes necessários
echo "Instalando pacotes necessários..."
sudo apt install -y curl wget git vim build-essential
check_command "Instalação de pacotes necessários"

# Pausa de 4 segundos
sleep 4

# Etapa 3: Instalação do Glances
echo "Instalando o Glances para monitoramento do sistema..."
sudo apt install -y glances
check_command "Instalação do Glances"

# Pausa de 4 segundos
sleep 4

# Etapa 4: Configuração do túnel Cloudflare
echo "Criando túnel Cloudflare..."
read -p "Deseja atualizar o comando do Cloudflare Tunnel? (s/n): " update_command
if [[ "$update_command" == "s" || "$update_command" == "S" ]]; then
    read -p "Insira o novo comando completo: " cloudflare_command
else
    cloudflare_command="curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb && sudo dpkg -i cloudflared.deb && sudo cloudflared service install eyJhIjoiZjMwNjRjN2NiOTcxMDIwNmIwOTcyZDljYWU2NGViMWYiLCJ0IjoiYTZkYjM5ZTMtMzJmMi00YzEwLTkxN2UtN2U5ZWJkNzZkNzBkIiwicyI6Ik1tUTVNRFUwWm1VdE1tRXlaUzAwWVRVeExUbG1NekF0TURObU1XSmhZMlJtTXpjMSJ9"
fi

if ! eval $cloudflare_command; then
    echo "Erro ao executar o comando do Cloudflare Tunnel. Verifique e tente novamente." >&2
    exit 1
fi
echo "Túnel Cloudflare configurado com sucesso!"

# Pausa de 4 segundos
sleep 4

# Etapa 5: Instalação do PostgreSQL
echo "Instalando o PostgreSQL..."
sudo apt-get install -y postgresql postgresql-contrib
check_command "Instalação do PostgreSQL"

echo "Iniciando o serviço do PostgreSQL..."
sudo service postgresql start
check_command "Início do serviço do PostgreSQL"

# Pausa de 4 segundos
sleep 4

# Etapa 6: Configuração do PostgreSQL
echo "Configurando o PostgreSQL..."
sudo -u postgres psql <<EOF
CREATE USER evolutionv2 WITH PASSWORD '142536';
ALTER USER evolutionv2 WITH SUPERUSER;
ALTER USER evolutionv2 CREATEDB;
CREATE DATABASE evolutionv2;

CREATE USER n8n_users WITH PASSWORD '142536';
ALTER USER n8n_users WITH SUPERUSER;
ALTER USER n8n_users CREATEDB;
CREATE DATABASE n8n_usersdb;
EOF
check_command "Configuração do PostgreSQL"

# Pausa de 4 segundos
sleep 4

# Etapa 7: Instalação do Redis
echo "Instalando o Redis..."
sudo apt-get install -y redis-server
check_command "Instalação do Redis"

echo "Iniciando o serviço do Redis..."
sudo service redis-server start
check_command "Início do serviço do Redis"

# Pausa de 4 segundos
sleep 4

# Etapa 8: Instalação do Node.js via NVM
echo "Instalando o NVM (Node Version Manager)..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
check_command "Instalação do NVM"

# Carregar o NVM no ambiente atual para uso imediato
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # Carrega o nvm

# Verificar se o NVM foi instalado corretamente
if ! command -v nvm &> /dev/null; then
    echo "Erro: o NVM não foi instalado corretamente. Abortando o script."
    exit 1
fi

echo "Instalando o Node.js v22..."
nvm install 22 && nvm use v22
check_command "Instalação do Node.js v22"

# Pausa de 4 segundos
sleep 4

# Etapa 9: Clone do repositório da Evolution API v2
echo "Clonando o repositório Evolution API v2..."
mkdir -p ~/Projetos
git clone -b develop https://github.com/EvolutionAPI/evolution-api.git ~/Projetos/evolution-api
check_command "Clone do repositório Evolution API v2"

echo "Repositório clonado em: ~/Projetos/evolution-api"

# Pausa de 4 segundos
sleep 4

# Etapa 10: Instalação das dependências do projeto
echo "Acessando o diretório do projeto e instalando dependências..."
cd ~/Projetos/evolution-api
npm install --force
check_command "Instalação das dependências"

# Pausa de 4 segundos
sleep 4

# Etapa 11: Configuração do arquivo .env
echo "Vamos configurar sua Evolution API?"
read -p "Pressione Enter para configurar..."

cd ~/Projetos/evolution-api
curl -O https://raw.githubusercontent.com/eliezermoreira/vmlocal/main/.env
nano ./.env
check_command "Configuração do arquivo .env"

# Pausa de 4 segundos
sleep 4

# Etapa 12: Gerar arquivos do Prisma
echo "Gerando arquivos do Prisma..."
cd ~/Projetos/evolution-api
npm run db:generate
check_command "Geração dos arquivos do Prisma"

# Pausa de 4 segundos
sleep 4

# Etapa 13: Deploy das migrations
echo "Realizando o deploy das migrations..."
cd ~/Projetos/evolution-api
npm run db:deploy
check_command "Deploy das migrations"

# Pausa de 4 segundos
sleep 4

# Etapa 13A: Fazer o build da Evolution API
echo "Buildando a Evolution API..."
cd ~/Projetos/evolution-api
npm run build
check_command "Deploy do build"

# Pausa de 4 segundos
sleep 4

# Etapa 14: Configuração do PM2
echo "Instalando o PM2..."
npm install pm2 -g
check_command "Instalação do PM2"

echo "Iniciando a API com PM2..."
cd ~/Projetos/evolution-api
pm2 start 'npm run start:prod' --name ApiEvolution
pm2 save
check_command "Configuração do PM2 para a API"

# Pausa de 4 segundos
sleep 4

# Etapa 15: Instalação do n8n
echo "Instalando o n8n..."
cd /
npm install n8n -g n8n@1.66.0
check_command "Instalação do n8n"

echo "Iniciando o n8n com PM2..."
pm2 start n8n
pm2 startup
pm2 save --force
check_command "Configuração do PM2 para o n8n"

# Pausa de 4 segundos
sleep 4

# Etapa 16: Instalação do MinIO
echo "Instalando o MinIO..."
cd /
wget https://dl.min.io/server/minio/release/linux-amd64/archive/minio_20241107005220.0.0_amd64.deb -O minio.deb
sudo dpkg -i minio.deb
check_command "Instalação do MinIO"

echo "Iniciando o MinIO..."
mkdir ~/minio
minio server ~/minio --console-address :9001
check_command "Início do servidor MinIO"

echo "Iniciando o MinIO com PM2..."
pm2 start /usr/local/bin/minio -- server ~/minio --console-address ":9001"
check_command "Configuração do MinIO com PM2"

echo "Script concluído com sucesso!"
