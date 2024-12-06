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

# Função para verificar se o comando foi executado com sucesso
check_command() {
    if [ $? -ne 0 ]; then
        echo "Erro durante a execução do comando: $1. Abortando o script." >&2
        exit 1
    fi
}

# Limpar a tela
clear

# Tela de boas-vindas
echo -e "\033[1;32m"
echo "######## +PRIME STREAM ACADEMY+ ###########"
echo "# Bem-vindo ao script de configuração!    #"
echo "# Este script irá configurar sua máquina  #"
echo "# com os pacotes necessários e serviços! #"
echo "###########################################"
echo -e "\033[0m"
echo ""
echo "Pressione Enter para continuar..."
read

# 1ª Etapa: Configuração inicial
echo "Configurando fuso horário para America/Sao_Paulo..."
sudo timedatectl set-timezone America/Sao_Paulo
check_command "Configuração do fuso horário"

echo "Atualizando pacotes..."
sudo apt update
check_command "Atualização de pacotes"

echo "Aplicando upgrades..."
sudo apt upgrade -y
check_command "Aplicação de upgrades"

# Pausar entre as etapas
sleep 4

# 2ª Etapa: Instalação de pacotes necessários
echo -e "\033[1;34mInstalando pacotes necessários... Aguarde...\033[0m"
sudo apt install -y curl wget git vim build-essential
check_command "Instalação dos pacotes necessários"

# Pausar entre as etapas
sleep 4

# 3ª Etapa: Instalação do Glances
echo "Instalando o Glances para monitoramento do sistema..."
sudo apt install -y glances
check_command "Instalação do Glances"

# Pausar entre as etapas
sleep 4

# 4ª Etapa: Configuração do túnel Cloudflare
echo "Criando túnel Cloudflare..."

read -p "Deseja atualizar o comando do Cloudflare Tunnel? (s/n): " update_command
if [[ "$update_command" == "s" || "$update_command" == "S" ]]; then
    read -p "Insira o novo comando completo: " cloudflare_command
else
    cloudflare_command="curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb && sudo dpkg -i cloudflared.deb && sudo cloudflared service install eyJhIjoiZjMwNjRjN2NiOTcxMDIwNmIwOTcyZDljYWU2NGViMWYiLCJ0IjoiYTZkYjM5ZTMtMzJmMi00YzEwLTkxN2UtN2U5ZWJkNzZkNzBkIiwicyI6Ik1tUTVNRFUwWm1VdE1tRXlaUzAwWVRVeExUbG1NekF0TURObU1XSmhZMlJtTXpjMSJ9"
fi

echo "Executando o comando do Cloudflare Tunnel..."
if ! eval $cloudflare_command; then
    echo "Erro ao executar o comando do Cloudflare Tunnel. Verifique e tente novamente." >&2
    exit 1
fi

echo "Túnel Cloudflare configurado com sucesso!"

# Pausar entre as etapas
sleep 4

# 5ª Etapa: Instalação do PostgreSQL
echo "Instalando o PostgreSQL..."
sudo apt-get install -y postgresql postgresql-contrib
check_command "Instalação do PostgreSQL"

echo "Iniciando o serviço do PostgreSQL..."
sudo service postgresql start
check_command "Início do serviço do PostgreSQL"

# Pausar entre as etapas
sleep 4

# 6ª Etapa: Configuração do PostgreSQL
echo "Configurando o PostgreSQL..."

sudo -u postgres psql <<EOF
-- Configurações para Evolution
CREATE USER evolutionv2 WITH PASSWORD '142536';
ALTER USER evolutionv2 WITH SUPERUSER;
ALTER USER evolutionv2 CREATEDB;
CREATE DATABASE evolutionv2;

-- Configurações para n8n
CREATE USER n8n_users WITH PASSWORD '142536';
ALTER USER n8n_users WITH SUPERUSER;
ALTER USER n8n_users CREATEDB;
CREATE DATABASE n8n_usersdb;
EOF

echo "Configuração do PostgreSQL concluída!"

# Pausar entre as etapas
sleep 4

# 7ª Etapa: Instalação do Redis
echo "Instalando o Redis..."
sudo apt-get install -y redis-server
check_command "Instalação do Redis"

echo "Iniciando o serviço do Redis..."
sudo service redis-server start
check_command "Início do serviço do Redis"

# Verificando o status do Redis
echo "Verificando o status do Redis..."
if redis-cli ping | grep -q "PONG"; then
    echo "Redis está rodando corretamente!"
else
    echo "Houve um problema ao iniciar o Redis. Verifique as configurações."
fi

# Pausar entre as etapas
sleep 4

# 8ª Etapa: Instalação do NVM e Node.js
echo "Instalando o NVM (Node Version Manager)..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
source ~/.bashrc
check_command "Instalação do NVM"

echo "Instalando o Node.js v22.12.0..."
nvm install v22.12.0 && nvm use v22.12.0
check_command "Instalação do Node.js"

# Pausar entre as etapas
sleep 4

# 9ª Etapa: Clone do repositório da Evolution API v2
echo "Clonando o repositório Evolution API v2..."
mkdir -p ~/Projetos
git clone -b develop https://github.com/EvolutionAPI/evolution-api.git ~/Projetos/evolution-api
check_command "Clonagem do repositório Evolution API v2"

echo "Repositório clonado em: ~/Projetos/evolution-api"

# Pausar entre as etapas
sleep 4

# 10ª Etapa: Copiar o arquivo .env.example para .env
echo "Configurando variáveis de ambiente..."
cp ~/Projetos/evolution-api/.env.example ~/Projetos/evolution-api/.env
check_command "Configuração do arquivo .env"

# Pausar entre as etapas
sleep 4

# 11ª Etapa: Editar o arquivo .env com o nano
echo "Vamos configurar sua Evolution API?"
echo "Pressione Enter para configurar."
read

nano ~/Projetos/evolution-api/.env

# Pausar entre as etapas
sleep 4

# 12ª Etapa: Gerar os arquivos do cliente Prisma e deploy das migrations
echo "Gerando arquivos do cliente Prisma..."
cd ~/Projetos/evolution-api
npm run db:generate
check_command "Geração dos arquivos do cliente Prisma"

echo "Realizando o deploy das migrations..."
npm run db:deploy
check_command "Deploy das migrations"

# Pausar entre as etapas
sleep 4

# 13ª Etapa: Usar PM2 para gerenciar o processo da API
echo "Instalando o PM2..."
npm install pm2 -g
check_command "Instalação do PM2"

echo "Iniciando a API com PM2..."
pm2 start 'npm run start:prod' --name ApiEvolution
pm2 startup
pm2 save --force
check_command "Configuração do PM2 para a API"

# Pausar entre as etapas
sleep 4

# 14ª Etapa: Instalar o n8n
echo "Instalando o n8n..."
npm install n8n -g
check_command "Instalação do n8n"

# Usar PM2 para gerenciar o processo do n8n
echo "Iniciando o n8n com PM2..."
pm2 start n8n
pm2 startup
pm2 save --force
check_command "Configuração do PM2 para o n8n"

# Pausar entre as etapas
sleep 4

# 15ª Etapa: Atribuição de memória para o n8n
echo "Sua VM tem cerca de $(free -h | grep Mem | awk '{print $2}') de memória RAM disponível."
read -p "Deseja atribuir mais memória para o n8n? (S/n): " atribuir_memoria
if [[ "$atribuir_memoria" == "S" || "$atribuir_memoria" == "s" ]]; then
    read -p "Quanto deseja atribuir para o n8n? (Exemplo: 2G, 512M, etc.): " memoria_alocada
    pm2 start n8n --name n8n --max-memory-restart $memoria_alocada
    echo "Memória alocada para o n8n foi ajustada para $memoria_alocada."
else
    echo "A memória não foi alterada para o n8n."
fi

# Pausar entre as etapas
sleep 4

# 16ª Etapa: Instalar o MinIO
echo "Instalando o MinIO..."
wget https://dl.min.io/server/minio/release/linux-amd64/archive/minio_20241107005220.0.0_amd64.deb -O minio.deb
sudo dpkg -i minio.deb
check_command "Instalação do MinIO"

echo "Iniciando o MinIO..."
mkdir ~/minio
minio server ~/minio --console-address :9001
check_command "Início do MinIO"

echo "Iniciando o MinIO com PM2..."
pm2 start /usr/local/bin/minio -- server ~/minio --console-address ":9001"
check_command "Configuração do MinIO com PM2"

echo -e "\033[1;32mConfiguração finalizada com sucesso! Seu servidor está pronto!\033[0m"
