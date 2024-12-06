#!/bin/bash

# Configuração inicial
echo "Configurando fuso horário para America/Sao_Paulo..."
sudo timedatectl set-timezone America/Sao_Paulo

echo "Atualizando pacotes..."
sudo apt update

echo "Aplicando upgrades..."
sudo apt upgrade -y

# Instalação de pacotes necessários
echo "Instalando pacotes necessários..."
sudo apt install -y curl wget git vim build-essential

# Instalação do Glances
echo "Instalando o Glances para monitoramento do sistema..."
sudo apt install -y glances

# Configuração do túnel Cloudflare
echo "Criando túnel Cloudflare..."

read -p "Deseja atualizar o comando do Cloudflare Tunnel? (s/n): " update_command
if [[ "$update_command" == "s" || "$update_command" == "S" ]]; then
    read -p "Insira o novo comando completo: " cloudflare_command
else
    cloudflare_command="curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb && sudo dpkg -i cloudflared.deb && sudo cloudflared service install eyJhIjoiZjMwNjRjN2NiOTcxMDIwNmIwOTcyZDljYWU2NGViMWYiLCJ0IjoiYTZkYjM5ZTMtMzJmMi00YzEwLTkxN2UtN2U5ZWJkNzZkNzBkIiwicyI6Ik1tUTVNRFUwWm1VdE1tRXlaUzAwWVRVeExUbG1NekF0TURObU1XSmhZMlJtTXpjMSJ9"
fi

echo "Executando o comando do Cloudflare Tunnel..."
eval $cloudflare_command

echo "Túnel Cloudflare configurado com sucesso!"

# Instalação do PostgreSQL
echo "Instalando o PostgreSQL..."
sudo apt-get update
sudo apt-get install -y postgresql postgresql-contrib

echo "Iniciando o serviço do PostgreSQL..."
sudo service postgresql start

# Configuração do PostgreSQL
echo "Configurando o PostgreSQL..."

# Criação de usuários, privilégios e bancos de dados
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

# Instalação do Redis
echo "Instalando o Redis..."
sudo apt-get install -y redis-server

echo "Iniciando o serviço do Redis..."
sudo service redis-server start

# Verificando o status do Redis
echo "Verificando o status do Redis..."
if redis-cli ping | grep -q "PONG"; then
    echo "Redis está rodando corretamente!"
else
    echo "Houve um problema ao iniciar o Redis. Verifique as configurações."
fi

# Instalação do NVM e Node.js
echo "Instalando o NVM (Node Version Manager)..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

echo "Carregando o NVM no ambiente atual..."
source ~/.bashrc

echo "Instalando o Node.js v22.12.0..."
nvm install v22.12.0 && nvm use v22.12.0

echo "Node.js v22.12.0 instalado e em uso!"

# Clone do repositório da Evolution API v2
echo "Clonando o repositório Evolution API v2..."

# Criar o diretório 'Projetos' caso não exista
mkdir -p ~/Projetos

# Clonando o repositório na branch 'develop'
git clone -b develop https://github.com/EvolutionAPI/evolution-api.git ~/Projetos/evolution-api

echo "Repositório clonado em: ~/Projetos/evolution-api"

# Acesse o diretório do projeto e instale as dependências
echo "Acessando o diretório do projeto e instalando dependências..."

cd ~/Projetos/evolution-api
npm install --force

echo "Dependências instaladas com sucesso!"

# Copiar o arquivo .env.example para .env
echo "Configurando variáveis de ambiente..."

cp ./.env.example ./.env

echo "Arquivo .env configurado com sucesso!"

# Configuração do arquivo .env
echo "Bem-vindo à configuração do arquivo .env! Vamos configurar as variáveis."

# Solicitar o IP local
echo "Por favor, insira o IP local da sua máquina (exemplo: 192.168.0.10):"
read SERVER_IP
SERVER_URL="http://$SERVER_IP:8080"
echo "SERVER_URL=$SERVER_URL" >> .env
echo "SERVER_URL configurado para: $SERVER_URL"

# Solicitar o usuário e senha do banco de dados
echo "Por favor, insira o nome de usuário do banco de dados (exemplo: evolutionv2):"
read DB_USER
echo "Por favor, insira a senha do banco de dados (exemplo: 142536):"
read DB_PASS
echo "Por favor, insira o IP local para o banco de dados (exemplo: 192.168.0.10):"
read DB_HOST
DATABASE_CONNECTION_URI="postgresql://$DB_USER:$DB_PASS@$DB_HOST:5432/evolution?schema=public"
echo "DATABASE_CONNECTION_URI=$DATABASE_CONNECTION_URI" >> .env
echo "DATABASE_CONNECTION_URI configurado para: $DATABASE_CONNECTION_URI"

# Solicitar o nome do cliente de conexão do banco de dados
echo "Por favor, insira o nome do cliente de conexão (exemplo: Evolution API):"
read DB_CLIENT_NAME
echo "DATABASE_CONNECTION_CLIENT_NAME=$DB_CLIENT_NAME" >> .env
echo "DATABASE_CONNECTION_CLIENT_NAME configurado para: $DB_CLIENT_NAME"

# Ativar webhook global
echo "Deseja ativar o webhook global? (true/false)"
read WEBHOOK_GLOBAL_ENABLED
WEBHOOK_GLOBAL_ENABLED=${WEBHOOK_GLOBAL_ENABLED:-true}  # Caso não insira nada, o valor padrão será "true"
echo "WEBHOOK_GLOBAL_ENABLED=$WEBHOOK_GLOBAL_ENABLED" >> .env
echo "WEBHOOK_GLOBAL_ENABLED configurado para: $WEBHOOK_GLOBAL_ENABLED"

# Ativar webhook por eventos
echo "Deseja ativar o webhook por eventos? (true/false)"
read WEBHOOK_GLOBAL_WEBHOOK_BY_EVENTS
WEBHOOK_GLOBAL_WEBHOOK_BY_EVENTS=${WEBHOOK_GLOBAL_WEBHOOK_BY_EVENTS:-true}  # Caso não insira nada, o valor padrão será "true"
echo "WEBHOOK_GLOBAL_WEBHOOK_BY_EVENTS=$WEBHOOK_GLOBAL_WEBHOOK_BY_EVENTS" >> .env
echo "WEBHOOK_GLOBAL_WEBHOOK_BY_EVENTS configurado para: $WEBHOOK_GLOBAL_WEBHOOK_BY_EVENTS"

# Solicitar a chave de autenticação
echo "Por favor, insira a chave de autenticação (pode gerar uma chave no site https://www.lastpass.com/pt/features/password-generator):"
read AUTHENTICATION_API_KEY
echo "AUTHENTICATION_API_KEY=$AUTHENTICATION_API_KEY" >> .env
echo "AUTHENTICATION_API_KEY configurado para: $AUTHENTICATION_API_KEY"

# Definir idioma
echo "Deseja definir o idioma como pt_BR? (digite 'sim' ou 'não')"
read LANGUAGE_INPUT
if [ "$LANGUAGE_INPUT" == "sim" ]; then
    LANGUAGE="pt_BR"
else
    LANGUAGE="em"
fi
echo "LANGUAGE=$LANGUAGE" >> .env
echo "LANGUAGE configurado para: $LANGUAGE"

# Menu de revisão do .env
echo "A configuração do arquivo .env foi concluída. Pressione Ctrl + X para sair e salvar."
echo "Lembre-se de verificar o arquivo .env para garantir que tudo foi configurado corretamente."

# Perguntar se deseja revisar o arquivo .env
read -p "Deseja revisar o arquivo .env antes de continuar? (S/n): " review_choice

if [[ "$review_choice" == "S" || "$review_choice" == "s" ]]; then
    # Abrir o arquivo .env para revisão
    nano .env
fi

# Após revisar e fechar o .env, gerar os arquivos do cliente Prisma
echo "Gerando os arquivos do cliente Prisma..."
npm run db:generate

echo "Arquivos do cliente Prisma gerados com sucesso!"

# Realizar o deploy das migrations:
echo "Realizando o deploy das migrations..."
npm run db:deploy

echo "Deploy das migrations realizado com sucesso!"

# Após a configuração, você pode iniciar a Evolution API com o seguinte comando:
echo "Construindo a Evolution API..."
npm run build

echo "Evolution API construída com sucesso!"

# Instalar PM2 para gerenciar o processo da API
echo "Instalando o PM2..."
npm install pm2 -g

# Iniciar a Evolution API com PM2
echo "Iniciando a Evolution API com PM2..."
pm2 start dist/main.js --name evolution-api

echo "Evolution API iniciada com PM2 com o nome 'evolution-api'."

# Perguntar sobre alocação de memória para o n8n
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

echo "Processo concluído!"
