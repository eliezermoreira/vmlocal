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

# Função para pausa entre as etapas
pause_script() {
    echo -e "\033[1;33mAguarde 4 segundos...\033[0m"
    sleep 4
}

# Função para verificação de sucesso de comando
check_command() {
    if [ $? -ne 0 ]; then
        echo "Erro ao executar o comando. Abortando o script." >&2
        exit 1
    fi
}

# Limpar a tela
clear
echo -e "\033[1;32m"
echo "############# +PRIME STREAM ACADEMY+ #################"
echo "# Bem-vindo ao script de configuração!    #"
echo "# Este script irá configurar sua máquina  #"
echo "# com os pacotes necessários e serviços! #"
echo "###########################################"
echo -e "\033[0m"
echo ""

# Iniciar o processo de verificação de progresso
check_progress

# Controle de Pausa para Etapa 1
if [ $STEP -lt 1 ]; then
    # Primeira etapa: Configuração inicial
    echo "Configurando fuso horário para America/Sao_Paulo..."
    sudo timedatectl set-timezone America/Sao_Paulo
    check_command

    echo "Atualizando pacotes..."
    sudo apt update
    check_command

    echo "Aplicando upgrades..."
    sudo apt upgrade -y
    check_command

    # Salvar progresso
    save_progress 1
    pause_script
fi

# Controle de Pausa para Etapa 2
if [ $STEP -lt 2 ]; then
    # Segunda etapa: Instalação de pacotes necessários
    echo -e "\033[1;34mInstalando pacotes necessários... Aguarde...\033[0m"
    sudo apt install -y curl wget git vim build-essential
    check_command

    # Salvar progresso
    save_progress 2
    pause_script
fi

# Controle de Pausa para Etapa 3
if [ $STEP -lt 3 ]; then
    # Terceira etapa: Instalação do Glances
    echo "Instalando o Glances para monitoramento do sistema..."
    sudo apt install -y glances
    check_command

    # Salvar progresso
    save_progress 3
    pause_script
fi

# Controle de Pausa para Etapa 4
if [ $STEP -lt 4 ]; then
    # Quarta etapa: Configuração do túnel Cloudflare
    echo "Criando túnel Cloudflare..."

    read -p "Deseja atualizar o comando do Cloudflare Tunnel? (s/n): " update_command
    if [[ "$update_command" == "s" || "$update_command" == "S" ]]; then
        read -p "Insira o novo comando completo: " cloudflare_command
    else
        cloudflare_command="curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb && sudo dpkg -i cloudflared.deb && sudo cloudflared service install eyJhIjoiZjMwNjRjN2NiOTcxMDIwNmIwOTcyZDljYWU2NGViMWYiLCJ0IjoiYTZkYjM5ZTMtMzJmMi00YzEwLTkxN2UtN2U5ZWJkNzZkNzBkIiwicyI6Ik1tUTVNRFUwWm1VdE1tRXlaUzAwWVRVeExUbG1NekF0TURObU1XSmhZMlJtTXpjMSJ9"
    fi

    # Validação do comando
    if ! eval $cloudflare_command; then
        echo "Erro ao executar o comando do Cloudflare Tunnel. Verifique e tente novamente." >&2
        exit 1
    fi

    echo "Túnel Cloudflare configurado com sucesso!"

    # Salvar progresso
    save_progress 4
    pause_script
fi

# Controle de Pausa para Etapa 5
if [ $STEP -lt 5 ]; then
    # Quinta etapa: Instalação do PostgreSQL
    echo "Instalando o PostgreSQL..."
    sudo apt-get update
    check_command
    sudo apt-get install -y postgresql postgresql-contrib
    check_command

    echo "Iniciando o serviço do PostgreSQL..."
    sudo service postgresql start
    check_command

    # Salvar progresso
    save_progress 5
    pause_script
fi

# Controle de Pausa para Etapa 6
if [ $STEP -lt 6 ]; then
    # Sexta etapa: Configuração do PostgreSQL
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
    check_command

    # Salvar progresso
    save_progress 6
    pause_script
fi

# Controle de Pausa para Etapa 7
if [ $STEP -lt 7 ]; then
    # Sétima etapa: Instalação do Redis
    echo "Instalando o Redis..."
    sudo apt-get install -y redis-server
    check_command

    echo "Iniciando o serviço do Redis..."
    sudo service redis-server start
    check_command

    echo "Verificando o status do Redis..."
    if redis-cli ping | grep -q "PONG"; then
        echo "Redis está rodando corretamente!"
    else
        echo "Houve um problema ao iniciar o Redis. Verifique as configurações."
    fi

    # Salvar progresso
    save_progress 7
    pause_script
fi

# Controle de Pausa para Etapa 8
if [ $STEP -lt 8 ]; then
    # Oitava etapa: Instalação do NVM e Node.js
    echo "Instalando o NVM (Node Version Manager)..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    check_command

    echo "Carregando o NVM no ambiente atual..."
    source ~/.bashrc
    check_command

    echo "Instalando o Node.js v22.12.0..."
    nvm install v22.12.0 && nvm use v22.12.0
    check_command

    echo "Node.js v22.12.0 instalado e em uso!"

    # Salvar progresso
    save_progress 8
    pause_script
fi

# Controle de Pausa para Etapa 9
if [ $STEP -lt 9 ]; then
    # Nona etapa: Clone do repositório da Evolution API v2
    echo "Clonando o repositório Evolution API v2..."

    # Criar o diretório 'Projetos' caso não exista
    mkdir -p ~/Projetos
    git clone -b develop https://github.com/EvolutionAPI/evolution-api.git ~/Projetos/evolution-api
    check_command

    echo "Repositório clonado em: ~/Projetos/evolution-api"

    echo "Acessando o diretório do projeto e instalando dependências..."
    cd ~/Projetos/evolution-api
    npm install --force
    check_command

    # Salvar progresso
    save_progress 9
    pause_script
fi

# Controle de Pausa para Etapa 10
if [ $STEP -lt 10 ]; then
    # Décima etapa: Configuração do ambiente .env
    echo "Configurando o arquivo .env para Evolution API..."
    nano ./.env
    check_command

    # Salvar progresso
    save_progress 10
    pause_script
fi

# Controle de Pausa para Etapa 11
if [ $STEP -lt 11 ]; then
    # Décima primeira etapa: Gerar arquivos do cliente Prisma
    echo "Gerando arquivos do cliente Prisma..."
    npm run db:generate
    check_command

    # Salvar progresso
    save_progress 11
    pause_script
fi

# Controle de Pausa para Etapa 12
if [ $STEP -lt 12 ]; then
    # Décima segunda etapa: Deploy das migrations
    echo "Realizando o deploy das migrations..."
    npm run db:deploy
    check_command

    # Salvar progresso
    save_progress 12
    pause_script
fi

# Controle de Pausa para Etapa 13
if [ $STEP -lt 13 ]; then
    # Décima terceira etapa: Gerenciar a API com PM2
    echo "Instalando o PM2..."
    npm install pm2 -g
    check_command

    if ! pm2 list | grep -q ApiEvolution; then
        pm2 start 'npm run start:prod' --name ApiEvolution
        pm2 save
    fi

    # Salvar progresso
    save_progress 13
    pause_script
fi

# Controle de Pausa para Etapa 14
if [ $STEP -lt 14 ]; then
    # Décima quarta etapa: Instalar o n8n
    echo "Instalando o n8n..."
    cd ~
    npm install n8n -g
    check_command

    pm2 start n8n
    pm2 startup
    pm2 save --force

    # Salvar progresso
    save_progress 14
    pause_script
fi

# Controle de Pausa para Etapa 15
if [ $STEP -lt 15 ]; then
    # Décima quinta etapa: Alocação de memória para o n8n
    quantidade_ram=$(free -h | grep Mem | awk '{print $2}')
    echo "Sua VM tem cerca de $quantidade_ram de memória RAM disponível."

    read -p "Deseja atribuir mais memória para o n8n? (S/n): " atribuir_memoria
    if [[ "$atribuir_memoria" == "S" || "$atribuir_memoria" == "s" ]]; then
        read -p "Quanto deseja atribuir para o n8n? (Exemplo: 2G, 512M, etc.): " memoria_alocada
        # Ajustar a configuração do PM2 para alocar mais memória para o n8n
        pm2 start n8n --name n8n --max-memory-restart $memoria_alocada
        echo "Memória alocada para o n8n foi ajustada para $memoria_alocada."
    else
        echo "A memória não foi alterada para o n8n."
    fi

    # Salvar progresso
    save_progress 15
    pause_script
fi

# Controle de Pausa para Etapa 16
if [ $STEP -lt 16 ]; then
    # Décima sexta etapa: Instalação e inicialização do MinIO
    echo "Baixando e instalando o MinIO..."
    wget https://dl.min.io/server/minio/release/linux-amd64/archive/minio_20241107005220.0.0_amd64.deb -O minio.deb
    sudo dpkg -i minio.deb
    check_command

    # Iniciar MinIO
    mkdir ~/minio
    minio server ~/minio --console-address :9001
    check_command

    # Gerenciar o MinIO com PM2
    pm2 start /usr/local/bin/minio -- server ~/minio --console-address ":9001"
    check_command

    # Salvar progresso
    save_progress 16
    pause_script
fi

# Fim do script
echo -e "\033[1;32mScript concluído com sucesso! Tudo pronto para iniciar!\033[0m"
