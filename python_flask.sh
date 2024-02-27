#!/bin/bash

# Caminho absoluto do script
SCRIPT_PATH=$(readlink -f "$0")

# Verifica se o nome do projeto foi fornecido
if [ "$#" -ne 1 ]; then
    echo "Uso: $0 nome_do_projeto"
    exit 1
fi

# Define o nome do projeto com o argumento fornecido
PROJECT_NAME=$1

# Cria um diretório para o projeto
mkdir $PROJECT_NAME

# Muda para o diretório do projeto
cd $PROJECT_NAME

# Cria o arquivo requirements.txt com as dependências
cat << EOF > requirements.txt
Flask
Flask-RESTX
python-dotenv
EOF

cat << EOF > .env
FLASK_APP=app.py
FLASK_ENV=development
FLASK_DEBUG=1
EOF

# Instala as dependências
pip install -r requirements.txt

# Cria a estrutura de diretórios da arquitetura Onion com __init__.py
declare -a layers=("presentation" "services" "repositories" "infrastructure" "domain" "static/css" "static/js" "templates" "static/images")

for layer in "${layers[@]}"; do
    mkdir -p $layer
    touch $layer/__init__.py
    # Caminho relativo do arquivo criado
    FILE_PATH="$PROJECT_NAME/$layer/__init__.py"
    echo "# $FILE_PATH" | cat - $layer/__init__.py > temp && mv temp $layer/__init__.py
done

# Remove __init__.py dos diretórios que não devem contê-los
rm static/css/__init__.py static/js/__init__.py templates/__init__.py static/images/__init__.py

# Cria o arquivo app.py na raiz do projeto
cat << EOF > app.py
# $PROJECT_NAME/app.py
from flask import Flask, render_template
from flask_restx import Api
from infrastructure.logging_config import setup_logging
import logging
from presentation.routes import init_api


def create_app():
    """Função de fábrica para criar e configurar o aplicativo Flask."""
    app = Flask(__name__)

    setup_logging()
    configure_api(app)
    register_routes(app)

    app.logger.info('Aplicativo $PROJECT_NAME iniciado com sucesso.')
    return app


def configure_api(app):
    """Configurar a API Flask-RESTx."""
    api = Api(app, version='1.0', title='$PROJECT_NAME API',
              description='Uma API de demonstração simples', doc='/swagger/')
    init_api(api)


def register_routes(app):
    """Registrar rotas do Flask."""
    @app.route('/home')
    def home():
        # Tratamento de erro simplificado para legibilidade
        return render_template('index.html')


if __name__ == '__main__':
    app = create_app()
    app.run(host='0.0.0.0', port=5000, debug=True)

EOF

# Cria um arquivo de rotas dentro de presentation
cat << EOF > presentation/routes.py
# $PROJECT_NAME/presentation/routes.py
from flask_restx import Resource, Namespace

api_ns = Namespace('api', description='API operations')


@api_ns.route('/helloworld')
class HelloWorld(Resource):
    def get(self):
        return {'message': 'Hello, World from API!'}


def init_api(api):
    """Inicializar a API."""
    api.add_namespace(api_ns)
EOF

# Ajusta a configuração de logs na camada de infraestrutura para criar a pasta de logs na raiz
cat << EOF > infrastructure/logging_config.py
# $PROJECT_NAME/infrastructure/logging_config.py

import logging
from logging.handlers import RotatingFileHandler
import os


def setup_logging():
    """Configuração do sistema de log."""
    logs_path = os.path.join(os.path.dirname(
        os.path.dirname(__file__)), 'logs')
    if not os.path.exists(logs_path):
        os.mkdir(logs_path)

    # Configuração do RotatingFileHandler
    file_handler = RotatingFileHandler(os.path.join(
        logs_path, '$PROJECT_NAME.log'), maxBytes=10240, backupCount=10)
    file_handler.setFormatter(logging.Formatter(
        '%(asctime)s %(levelname)s: %(message)s [in %(pathname)s:%(lineno)d]'))
    file_handler.setLevel(logging.INFO)

    # Configuração do StreamHandler para saída no console
    stream_handler = logging.StreamHandler()
    stream_handler.setFormatter(logging.Formatter(
        '%(asctime)s %(levelname)s: %(message)s'))
    # Pode ser ajustado para ERROR em produção
    stream_handler.setLevel(logging.INFO)

    # Verifica se o handler já foi adicionado para evitar duplicação
    logger = logging.getLogger()
    if not logger.handlers:
        logger.addHandler(file_handler)
        logger.addHandler(stream_handler)
    logger.setLevel(logging.INFO)

    logging.info('Inicialização do $PROJECT_NAME')
EOF

# Adiciona a importação e carregamento das variáveis de ambiente
cat << EOF >> infrastructure/config.py
# $PROJECT_NAME/infrastructure/config.py
import os
from dotenv import load_dotenv

# Carrega variáveis de ambiente do arquivo .env
load_dotenv()

def get_env_variable(name, default=None):
    """Recupera uma variável de ambiente pelo nome ou retorna um valor padrão."""
    return os.getenv(name, default)
EOF

# Cria os arquivos CSS e JavaScript padrões
cat << EOF > static/css/style.css
/* $PROJECT_NAME/static/css/style.css */

/* Estilos gerais para o corpo do documento */
body {
  font-family: "Poppins", sans-serif;
  margin: 0;
  padding: 0;
  background: linear-gradient(135deg, #6e8efb, #88d3ce);
  display: flex;
  justify-content: center;
  align-items: center;
  height: 100vh;
  color: #333;
}

/* Estilos para o contêiner principal */
.container {
  max-width: 600px;
  width: 90%;
  margin: 20px;
  padding: 20px;
  background-color: #ffffff;
  box-shadow: 0 4px 14px 0 rgba(0, 0, 0, 0.2);
  border-radius: 12px;
  text-align: center;
  transition: transform 0.3s ease-in-out;
  overflow: hidden;
}

.gif-container {
  width: 100%;
  overflow: hidden;
}

/* Estilos para o iframe do GIPHY */
.giphy-embed {
  display: block;
  width: 100%;
  height: auto;
  max-height: 400px;
  border: none;
  background: transparent;
}

/* Efeito de levantamento suave ao passar o mouse sobre o contêiner */
.container:hover {
  transform: translateY(-5px);
}

/* Estilos para o título h1 */
h1 {
  font-size: 2.5rem;
  color: #333;
  margin-top: 20px; /* Adicionado margem no topo para espaçar do GIF */
  transition: color 0.3s ease;
}

/* Efeito de mudança de cor ao passar o mouse sobre o título */
h1:hover {
  color: #6e8efb;
}

/* Estilos para dispositivos de tela menores que 768px */
@media (max-width: 768px) {
  .container {
    width: 90%;
    padding: 10px; /* Padding reduzido para dispositivos menores */
  }

  h1 {
    font-size: 2rem;
  }
}
EOF

cat << EOF > static/js/script.js
// $PROJECT_NAME/static/js/script.js

// Aguarda o carregamento completo do DOM antes de executar o código
document.addEventListener("DOMContentLoaded", function () {
  // Seleciona o elemento h1 para exibir a mensagem de boas-vindas dinâmica
  const welcomeMessage = document.querySelector("h1");
  // Obtém a hora atual
  const currentTime = new Date().getHours();
  let greeting;

  // Define a mensagem de boas-vindas com base na hora do dia
  if (currentTime < 12) {
    greeting = "Bom dia e bem-vindo ao $PROJECT_NAME!";
  } else if (currentTime < 18) {
    greeting = "Boa tarde e bem-vindo ao $PROJECT_NAME!";
  } else {
    greeting = "Boa noite e bem-vindo ao $PROJECT_NAME!";
  }

  // Define o texto do elemento h1 como a mensagem de boas-vindas
  welcomeMessage.textContent = greeting;

  // Aplica uma transição de opacidade suave ao corpo do documento
  document.body.style.opacity = 0;
  document.body.style.transition = "opacity 2s";
  document.body.style.opacity = 1;

  // Registra no console que o documento foi carregado e está pronto
  console.log("Documento carregado e pronto!");
});
EOF

# Cria um arquivo HTML padrão
cat << EOF > templates/index.html
<!DOCTYPE html>
<!-- $PROJECT_NAME/templates/index.html -->
<html lang="pt-BR">
  <head>
    <!-- Definição do conjunto de caracteres e da viewport -->
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <!-- Título da página -->
    <title>$PROJECT_NAME - Bem-vindo</title>
    <!-- Importação do arquivo CSS -->
    <link rel="stylesheet" href="/static/css/style.css" />
    <!-- Ícone da página -->
    <link rel="icon" type="image/png" href="/static/images/favicon.png" />
    <!-- Importação da fonte Google Poppins -->
    <link
      href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;600&display=swap"
      rel="stylesheet"
    />
  </head>
  <body>
    <div class="container">
      <h1>Bem-vindo ao $PROJECT_NAME!</h1>
      <!-- Ícone animado do GIPHY -->
      <div class="gif-container">
        <iframe
          src="https://giphy.com/embed/UVRnoEraX4ZyehWJLb"
          title="GIPHY Embed"
          style="border: 0"
          class="giphy-embed"
          allowfullscreen
        ></iframe>
      </div>
    </div>
    <!-- Importação do arquivo JavaScript -->
    <script src="/static/js/script.js"></script>
  </body>
</html>

EOF

# Cria uma imagem favicon padrão
touch static/images/favicon.png


# Cria o arquivo .gitignore
cat << EOF > .gitignore
# $PROJECT_NAME/.gitignore
venv/
*.pyc
__pycache__/
instance/
.webassets-cache
logs
EOF

# Cria o Dockerfile
cat << EOF > Dockerfile
# $PROJECT_NAME/Dockerfile
# Define a imagem base
FROM python:3.9-slim

# Define o diretório de trabalho no contêiner
WORKDIR /app

# Cria um ambiente virtual
RUN python -m venv /venv

# Atualiza o pip dentro do ambiente virtual e instala as dependências principais
COPY requirements.txt .
RUN . /venv/bin/activate && \
    pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Cria um usuário não root e muda para ele antes de copiar os arquivos
RUN adduser --disabled-password --gecos '' appuser

# Cria o diretório de logs e ajusta as permissões antes de mudar para o usuário não root
RUN mkdir -p /app/logs && chown -R appuser:appuser /app/logs

# Muda para o usuário não root
USER appuser

# Copia o restante dos arquivos do projeto para o contêiner, garantindo que o usuário não root seja o proprietário
COPY --chown=appuser:appuser . .

# Expõe a porta em que a aplicação estará ouvindo
EXPOSE 5000

# Ativa o ambiente virtual e executa a aplicação
CMD ["/venv/bin/python", "app.py"]
EOF

# Cria o arquivo .dockerignore
cat << EOF > .dockerignore
# $PROJECT_NAME/.dockerignore
venv/
*.pyc
__pycache__/
.git
.gitignore
Dockerfile
.dockerignore
EOF

# Cria a pasta .vscode e o arquivo launch.json para configuração do VS Code
mkdir -p .vscode
cat << EOF > .vscode/launch.json
# $PROJECT_NAME/.vscode/launch.json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Python: Flask",
            "type": "debugpy",
            "request": "launch",
            "module": "flask",
            "env": {
                "FLASK_APP": "app.py",
                "FLASK_ENV": "development",
                "FLASK_DEBUG": "1"
            },
            "args": [
                "run",
                "--no-debugger",
                "--no-reload"
            ],
            "jinja": true
        }
    ]
}
EOF

# Inicializa o repositório Git e faz o primeiro commit
git init
git add .
git commit -m "Projeto Flask $PROJECT_NAME inicializado."

echo "Projeto Flask $PROJECT_NAME configurado com sucesso."
echo "Dependências instaladas."
echo "Para executar seu projeto, use: python app.py"
echo "Para construir e rodar com Docker, use: docker build -t $PROJECT_NAME . && docker run -p 5000:5000 $PROJECT_NAME"
