import os
from flask import Flask, jsonify

app = Flask(__name__)

# Define o diretório que será lido dentro do container
DIRETORIO_ALVO = '/dados'

@app.route('/', methods=['GET'])
def listar_arquivos():
    try:
        if not os.path.exists(DIRETORIO_ALVO):
            return jsonify({"erro": "Diretório não encontrado"}), 404
        arquivos = os.listdir(DIRETORIO_ALVO)
        return jsonify({
            "mensagem": "Leitura realizada com sucesso",
            "total_arquivos": len(arquivos),
            "arquivos": arquivos
        })
    except Exception as e:
        return jsonify({"erro": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)