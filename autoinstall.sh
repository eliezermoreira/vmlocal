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

\c n8n_usersdb;
CREATE TABLE contatos (
    id SERIAL PRIMARY KEY,                   -- Chave primária única e sequencial
    remoteJid VARCHAR(255) NOT NULL,         -- Identificador remoto obrigatório
    fullCode VARCHAR(20) NOT NULL,           -- Código obrigatório com limite de 20 caracteres
    nome VARCHAR(255),                       -- Nome do contato
    numero_telefone VARCHAR(20),             -- Número de telefone
    assinou BOOLEAN DEFAULT FALSE,           -- Indica se assinou, padrão é falso
    solicitou_teste BOOLEAN DEFAULT FALSE,   -- Indica se solicitou teste, padrão é falso
    data_adesao DATE,                        -- Data de adesão
    data_renovacao DATE,                     -- Data de renovação
    data_vencimento DATE,                    -- Data de vencimento
    login VARCHAR(255),                      -- Login associado
    senha VARCHAR(255),                      -- Senha associada
    CONSTRAINT unique_remoteJid_fullCode UNIQUE (remoteJid, fullCode) -- Restrições únicas combinadas
);
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

sudo apt-get install curl gnupg apt-transport-https -y

## Team RabbitMQ's main signing key
curl -1sLf "https://keys.openpgp.org/vks/v1/by-fingerprint/0A9AF2115F4687BD29803A206B73A36E6026DFCA" | sudo gpg --dearmor | sudo tee /usr/share/keyrings/com.rabbitmq.team.gpg > /dev/null
## Community mirror of Cloudsmith: modern Erlang repository
curl -1sLf https://github.com/rabbitmq/signing-keys/releases/download/3.0/cloudsmith.rabbitmq-erlang.E495BB49CC4BBE5B.key | sudo gpg --dearmor | sudo tee /usr/share/keyrings/rabbitmq.E495BB49CC4BBE5B.gpg > /dev/null
## Community mirror of Cloudsmith: RabbitMQ repository
curl -1sLf https://github.com/rabbitmq/signing-keys/releases/download/3.0/cloudsmith.rabbitmq-server.9F4587F226208342.key | sudo gpg --dearmor | sudo tee /usr/share/keyrings/rabbitmq.9F4587F226208342.gpg > /dev/null

## Add apt repositories maintained by Team RabbitMQ
sudo tee /etc/apt/sources.list.d/rabbitmq.list <<EOF
## Provides modern Erlang/OTP releases
##
deb [arch=amd64 signed-by=/usr/share/keyrings/rabbitmq.E495BB49CC4BBE5B.gpg] https://ppa1.rabbitmq.com/rabbitmq/rabbitmq-erlang/deb/ubuntu noble main
deb-src [signed-by=/usr/share/keyrings/rabbitmq.E495BB49CC4BBE5B.gpg] https://ppa1.rabbitmq.com/rabbitmq/rabbitmq-erlang/deb/ubuntu noble main

# another mirror for redundancy
deb [arch=amd64 signed-by=/usr/share/keyrings/rabbitmq.E495BB49CC4BBE5B.gpg] https://ppa2.rabbitmq.com/rabbitmq/rabbitmq-erlang/deb/ubuntu noble main
deb-src [signed-by=/usr/share/keyrings/rabbitmq.E495BB49CC4BBE5B.gpg] https://ppa2.rabbitmq.com/rabbitmq/rabbitmq-erlang/deb/ubuntu noble main

## Provides RabbitMQ
##
deb [arch=amd64 signed-by=/usr/share/keyrings/rabbitmq.9F4587F226208342.gpg] https://ppa1.rabbitmq.com/rabbitmq/rabbitmq-server/deb/ubuntu noble main
deb-src [signed-by=/usr/share/keyrings/rabbitmq.9F4587F226208342.gpg] https://ppa1.rabbitmq.com/rabbitmq/rabbitmq-server/deb/ubuntu noble main

# another mirror for redundancy
deb [arch=amd64 signed-by=/usr/share/keyrings/rabbitmq.9F4587F226208342.gpg] https://ppa2.rabbitmq.com/rabbitmq/rabbitmq-server/deb/ubuntu noble main
deb-src [signed-by=/usr/share/keyrings/rabbitmq.9F4587F226208342.gpg] https://ppa2.rabbitmq.com/rabbitmq/rabbitmq-server/deb/ubuntu noble main
EOF

## Update package indices
sudo apt-get update -y

## Install Erlang packages
sudo apt-get install -y erlang-base \
                        erlang-asn1 erlang-crypto erlang-eldap erlang-ftp erlang-inets \
                        erlang-mnesia erlang-os-mon erlang-parsetools erlang-public-key \
                        erlang-runtime-tools erlang-snmp erlang-ssl \
                        erlang-syntax-tools erlang-tftp erlang-tools erlang-xmerl

## Install rabbitmq-server and its dependencies
sudo apt-get install rabbitmq-server -y --fix-missing

sudo rabbitmq-plugins enable rabbitmq_management

sudo rabbitmqctl add_user admin pass123
sudo rabbitmqctl set_user_tags admin administrator
sudo rabbitmqctl set_permissions -p / admin ".*" ".*" ".*"

sudo service rabbitmq-server start
sudo service rabbitmq-server restart

# Pausa de 4 segundos
sleep 4

# Etapa 8A: Instalação do Node.js via NVM
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
git clone -b main https://github.com/EvolutionAPI/evolution-api.git ~/Projetos/evolution-api
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

# Pausa de 4 segundos
sleep 4

pm2 stop all
pm2 start ApiEvolution --node-args="--max-old-space-size=3072"
pm2 startup
pm2 save --force
check_command "Configuração do PM2 para a API"

# Pausa de 4 segundos
sleep 4

# Etapa 15: Instalação do n8n
echo "Instalando o n8n..."
cd /
npm install n8n -g
check_command "Instalação do n8n"

echo "Iniciando o n8n com PM2..."
pm2 start n8n --node-args="--max-old-space-size=3072"
pm2 startup
pm2 save --force
check_command "Configuração do PM2 para o n8n"

# Pausa de 4 segundos
sleep 4

# Etapa 16: Instalação do MinIO
echo "Instalando o MinIO..."
cd /
wget https://dl.min.io/server/minio/release/linux-amd64/archive/minio_20241107005220.0.0_amd64.deb -O minio.deb

# Verificando se o download foi bem-sucedido
if [ ! -f "minio.deb" ]; then
    echo "Falha no download do MinIO. Verifique a URL e tente novamente."
    exit 1
fi

# Instalando o MinIO
sudo dpkg -i minio.deb

# Verificando se a instalação foi bem-sucedida
if [ $? -ne 0 ]; then
    echo "Erro na instalação do MinIO."
    exit 1
fi

# Confirmando que a instalação foi concluída
check_command "Instalação do MinIO"

echo "Iniciando o MinIO com PM2..."

# Aguardando a instalação para garantir que o MinIO foi instalado corretamente
if ! command -v minio &> /dev/null; then
    echo "MinIO não foi instalado corretamente. Verifique os logs de instalação."
    exit 1
fi

# Iniciando o MinIO com PM2
pm2 start /usr/local/bin/minio -- server ~/minio --console-address ":9001"

# Verificando se o PM2 iniciou corretamente
check_command "Configuração do MinIO com PM2"

# Pausa de 4 segundos
sleep 4

# Etapa 16: Instalação do MinIO
echo "Reboot final"

# Pausa de 4 segundos
sleep 4

reboot -n

echo "Script concluído com sucesso!"
