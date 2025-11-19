import os
import oracledb
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from dotenv import load_dotenv # Usada apenas para testes locais

# 1. CARREGANDO AS CREDENCIAIS DE FORMA SEGURA
# Em produção, as variáveis virão do ambiente (Docker/Servidor).
# Para testes locais, carregamos do .env:
load_dotenv() 

# Credenciais do Banco de Dados
DB_USER = os.environ.get('ORACLE_USER')
DB_PASS = os.environ.get('ORACLE_PASS')
DB_CONNECT_STRING = os.environ.get('ORACLE_CONNECT_STRING')
CONTROL_TABLE = 'SUA_TABELA_DE_CONTROLE' # Exemplo: 'AUDIT_LOG'

# Credenciais de Email
SMTP_SERVER = os.environ.get('SMTP_SERVER', 'smtp.gmail.com')
SMTP_PORT = os.environ.get('SMTP_PORT', 587)
EMAIL_SENDER = os.environ.get('EMAIL_SENDER')
EMAIL_PASS = os.environ.get('EMAIL_PASS') # Deve ser uma App Password
EMAIL_RECIPIENT = os.environ.get('EMAIL_RECIPIENT') # Exemplo: 'seu.gestor@empresa.com'

def get_last_sequence_id():
    """Conecta ao Oracle e obtém o ID máximo da tabela de controle."""
    last_id = None
    
    # 2. CONEXÃO COM O BANCO DE DADOS
    try:
        connection = oracledb.connect(
            user=DB_USER, 
            password=DB_PASS, 
            dsn=DB_CONNECT_STRING
        )
        cursor = connection.cursor()

        # 3. CONSULTA SQL
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
    """Envia o ID obtido por e-mail."""
    if sequence_id is None:
        print("Não foi possível obter o ID para enviar o e-mail.")
        return

    msg = MIMEMultipart()
    msg['From'] = EMAIL_SENDER
    msg['To'] = EMAIL_RECIPIENT
    msg['Subject'] = f"Relatório de Sequência: Último ID Obtido ({CONTROL_TABLE})"
    
    body = f"""
    Prezado(a),

    O último ID de sequência utilizado na tabela de controle '{CONTROL_TABLE}' é:

    ID: {sequence_id}

    Atenciosamente,
    Script de Monitoramento
    """
    msg.attach(MIMEText(body, 'plain'))
    
    # 4. ENVIO DE E-MAIL
    try:
        server = smtplib.SMTP(SMTP_SERVER, SMTP_PORT)
        server.starttls() # Inicia criptografia TLS
        server.login(EMAIL_SENDER, EMAIL_PASS)
        text = msg.as_string()
        server.sendmail(EMAIL_SENDER, EMAIL_RECIPIENT, text)
        server.quit()
        print(f"Sucesso! ID ({sequence_id}) enviado para {EMAIL_RECIPIENT}.")
        
    except Exception as e:
        print(f"Erro ao enviar e-mail: {e}")

if __name__ == '__main__':
    last_id = get_last_sequence_id()
    if last_id is not None:
        send_email(last_id)
    else:
        print("Execução falhou. Verifique as credenciais e a conexão com o banco.")