### 🐳 Desafio 1 - Docker: API de Leitura de Arquivos
#### 📋 Descrição do Projeto

Este projeto consiste em uma aplicação desenvolvida em **Python** utilizando o microframework **Flask**. O objetivo é fornecer uma API REST que realiza a leitura de um diretório mapeado do host local para dentro do container e retorna a lista de arquivos encontrados via método HTTP GET.

A solução foi "dockerizada" para garantir portabilidade e facilidade de execução em qualquer ambiente que suporte containers.
___
#### 📂 Estrutura de Arquivos
Para executar o projeto, certifique-se de ter os seguintes arquivos na mesma pasta:
1. `app.py`: O código fonte da aplicação.
2. `Dockerfile`: As instruções para construção da imagem Docker.
3. `requirements.txt`: Lista de dependências do Python.
___
💻 Código Fonte

1. `app.py`
Aplicação Python que expõe a rota `/` na porta 5000. Ela lê estritamente o diretório `/dados` dentro do container.
```
import os
from flask import Flask, jsonify

app = Flask(__name__)

# Define o diretório fixo que será lido dentro do container (ponto de montagem)
DIRETORIO_ALVO = '/dados'

@app.route('/', methods=['GET'])
def listar_arquivos():
    try:
        # Verifica se o diretório existe antes de tentar ler
        if not os.path.exists(DIRETORIO_ALVO):
            return jsonify({"erro": "Diretório /dados não encontrado ou não mapeado"}), 404
        
        # Realiza a leitura dos arquivos
        arquivos = os.listdir(DIRETORIO_ALVO)
        
        # Retorna o JSON formatado
        return jsonify({
            "mensagem": "Leitura realizada com sucesso",
            "total_arquivos": len(arquivos),
            "arquivos": arquivos
        })
    except Exception as e:
        # Tratamento de erros genéricos
        return jsonify({"erro": str(e)}), 500

if __name__ == '__main__':
    # host='0.0.0.0' torna a aplicação visível fora do container
    app.run(host='0.0.0.0', port=5000)
```

2. `Dockerfile`
Utiliza uma imagem base `slim` para otimizar o tamanho final.
```
# Imagem base leve do Python 3.9
FROM python:3.9-slim

# Diretório de trabalho da aplicação
WORKDIR /app

# Instalação de dependências
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copia o código fonte
COPY app.py .

# Cria o diretório para o ponto de montagem do volume
RUN mkdir /dados

# Expõe a porta padrão do Flask
EXPOSE 5000

# Comando de inicialização
CMD ["python", "app.py"]
```

3. requirements.txt
```
flask==3.1.2
```
___

#### 🚀 Execução Rápida via Docker Hub
Se você já possui o Docker instalado e deseja pular a etapa de construção (`docker build`), você pode baixar a imagem diretamente do Docker Hub.

**Imagem no Docker Hub:** `viniciuscaol/desafio1ng`

**Passo 1: Puxar a Imagem (Pull)**
Utilize o comando `docker pull` para baixar a imagem para sua máquina:
```
docker pull viniciuscaol/desafio1ng
```
**Passo 2: Rodar o Container (Mapeando o Volume)**
O mapeamento de volume (`-v`) continua sendo essencial para que o container possa acessar a pasta do seu host.

**Comando para Linux / Mac / WSL:**
```
docker run -p 5000:5000 -v $(pwd):/dados viniciuscaol/desafio1ng
```
**Comando para Windows (PowerShell):**
```
docker run -p 5000:5000 -v ${PWD}:/dados viniciuscaol/desafio1ng
```

🔔 Lembrete: Após rodar, o teste é o mesmo: acesse `http://localhost:5000` no navegador.
___
#### 🚀 Guia de Execução
Siga os passos abaixo para construir e rodar a aplicação.

**Passo 1: Construir a Imagem**

No terminal, navegue até a pasta do projeto e execute:
```
docker build -t desafio-leitor-arquivos .
```
*Passo 2: Rodar o Container*

É crucial utilizar a flag `-v` (volume) para conectar uma pasta do seu computador à pasta `/dados` do container.

**Comando para Linux / Mac / WSL**: Este comando mapeia a pasta atual (`pwd`) para dentro do container.
```
docker run -p 5000:5000 -v $(pwd):/dados desafio-leitor-arquivos
```
**Comando para Windows (PowerShell)**:
```
docker run -p 5000:5000 -v ${PWD}:/dados desafio-leitor-arquivos
```
**Comando para Windows (CMD Clássico)**:
```
docker run -p 5000:5000 -v %cd%:/dados desafio-leitor-arquivos
```
___
#### 🧪 Como Testar
Após rodar o container, a API estará disponível em `http://localhost:5000`.

**Via Navegador ou Postman**: Acesse a URL acima. O retorno esperado é um JSON listando os arquivos da pasta onde você rodou o comando.

**Exemplo de Resposta (JSON):**
```
{
    "arquivos": [
        "Dockerfile",
        "app.py",
        "requirements.txt"
    ],
    "mensagem": "Leitura realizada com sucesso",
    "total_arquivos": 3
}
```
#### 📊 Estratégia de Monitoramento
Para garantir a estabilidade e saúde da aplicação em produção, recomenda-se o monitoramento dos **Quatro Sinais de Ouro (Golden Signals)**:

| Métrica | Descrição | Motivo / Ação |
| :--- | :--- | :--- |
| **1. Latência** | Tempo de resposta da requisição HTTP. | **Risco:** A leitura de diretórios com milhares de arquivos é uma operação de I/O bloqueante. Monitorar para identificar lentidão no disco. |
| **2. Saturação** | Uso de Memória RAM do container. | **Risco:** O método `os.listdir` carrega a lista na memória. Um diretório gigante pode causar estouro de memória (OOM Kill). |
| **3. Taxa de Erros** | Contagem de status HTTP 500. | Identificar falhas de permissão de leitura ou erros do script Python. |
| **4. Tráfego** | Requisições por segundo (RPS). | Acompanhar a demanda para decidir sobre a necessidade de escalar (mais réplicas). |

Além disso, recomenda-se um **Healthcheck** simples verificando se o volume `/dados` está montado corretamente, evitando que a aplicação rode "vazia".