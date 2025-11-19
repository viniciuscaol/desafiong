## 🐍 Desafio 2 - API Oracle Sequence ID e Notificação por E-mail

Este projeto consiste em um script Python que conecta-se a uma base de dados Oracle para obter o último ID de sequência utilizado em uma tabela de controle e, em seguida, envia essa informação por e-mail. A prioridade deste projeto é a **segurança** e a **separação de credenciais** do código-fonte.
___
### 🛡️ Estratégia de Segurança (Ponto Crítico)

Para garantir a segurança do acesso à base de dados e ao e-mail, as senhas e credenciais **não são hardcoded**. Elas são injetadas no script no momento da execução através de **Variáveis de Ambiente**.

#### Boas Práticas:
1.  **Variáveis de Ambiente:** O script utiliza `os.environ.get()` para carregar todas as credenciais sensíveis.
2.  **Arquivo .env:** Para testes locais, usamos a biblioteca `python-dotenv` para simular o ambiente de produção, lendo as variáveis de um arquivo `.env` (que deve ser **ignorado pelo Git**).
3.  **E-mail:** Recomenda-se usar uma **Senha de Aplicação (App Password)** dedicada para o envio de e-mails, e não a senha principal da conta.
___
### ⚙️ Pré-requisitos e Configuração

#### Dependências
```bash
pip install -r requirements.txt
```
#### Configuração do Arquivo `.env`
Crie este arquivo na raiz do seu projeto. **NUNCA comite este arquivo!**
```
# ORACLE CONNECTION
ORACLE_USER="seu_usuario_oracle"
ORACLE_PASS="sua_senha_secreta"
ORACLE_CONNECT_STRING="host_oracle:1521/SEU_SERVICE" 
CONTROL_TABLE="NOME_DA_SUA_TABELA" 

# EMAIL CONNECTION (Utilize App Password)
SMTP_SERVER="smtp.email.com"
SMTP_PORT=587
EMAIL_SENDER="seu_email_remetente@email.com"
EMAIL_PASS="sua_app_password_secreta" 
EMAIL_RECIPIENT="destinatario@email.com"
```
___
### 🐍 O Script Python (oracle_email.py)
```
import os
import oracledb
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from dotenv import load_dotenv

# Carrega as variáveis de ambiente (se existirem)
load_dotenv() 

# --- Variáveis Carregadas do Ambiente ---
DB_USER = os.environ.get('ORACLE_USER')
DB_PASS = os.environ.get('ORACLE_PASS')
DB_CONNECT_STRING = os.environ.get('ORACLE_CONNECT_STRING')
CONTROL_TABLE = os.environ.get('CONTROL_TABLE') 

SMTP_SERVER = os.environ.get('SMTP_SERVER')
SMTP_PORT = int(os.environ.get('SMTP_PORT', 587))
EMAIL_SENDER = os.environ.get('EMAIL_SENDER')
EMAIL_PASS = os.environ.get('EMAIL_PASS')
EMAIL_RECIPIENT = os.environ.get('EMAIL_RECIPIENT')

def get_last_sequence_id():
    """Conecta ao Oracle e obtém o ID máximo da tabela."""
    last_id = None
    
    # Validação mínima
    if not all([DB_USER, DB_PASS, DB_CONNECT_STRING, CONTROL_TABLE]):
        print("Erro: Credenciais Oracle incompletas.")
        return None

    try:
        connection = oracledb.connect(
            user=DB_USER, 
            password=DB_PASS, 
            dsn=DB_CONNECT_STRING
        )
        cursor = connection.cursor()

        sql_query = f"SELECT MAX(ID_SEQUENCIA) FROM {CONTROL_TABLE}"
        cursor.execute(sql_query)
        
        result = cursor.fetchone()
        if result:
            last_id = result[0]
            
        cursor.close()
        connection.close()
        
    except oracledb.Error as e:
        print(f"Erro ao conectar ou consultar o Oracle: {e}")
    
    return last_id

def send_email(sequence_id):
    """Envia o ID obtido por e-mail via SMTP."""
    if sequence_id is None:
        return

    if not all([SMTP_SERVER, EMAIL_SENDER, EMAIL_PASS, EMAIL_RECIPIENT]):
        print("Erro: Credenciais de E-mail incompletas.")
        return

    msg = MIMEMultipart()
    msg['From'] = EMAIL_SENDER
    msg['To'] = EMAIL_RECIPIENT
    msg['Subject'] = f"Relatório de Sequência: Último ID Obtido ({CONTROL_TABLE})"
    
    body = f"""
    O último ID de sequência utilizado na tabela '{CONTROL_TABLE}' é:
    ID: {sequence_id}
    """
    msg.attach(MIMEText(body, 'plain'))
    
    try:
        server = smtplib.SMTP(SMTP_SERVER, SMTP_PORT)
        server.starttls()
        server.login(EMAIL_SENDER, EMAIL_PASS)
        server.sendmail(EMAIL_SENDER, EMAIL_RECIPIENT, msg.as_string())
        server.quit()
        print(f"Sucesso! ID ({sequence_id}) enviado para {EMAIL_RECIPIENT}.")
        
    except Exception as e:
        print(f"Erro ao enviar e-mail: {e}")

if __name__ == '__main__':
    last_id = get_last_sequence_id()
    if last_id is not None:
        send_email(last_id)
    else:
        print("Execução finalizada com falha na obtenção do ID.")
```
___
### ▶️ Como Rodar o Script
1. Garanta que o arquivo `.env` esteja na pasta.

2. Execute o script Python no seu terminal:
```
python app.py
```