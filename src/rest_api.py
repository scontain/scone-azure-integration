from flask import Flask, request, jsonify, Response
from flask_restful import Resource, Api
import json
import os
import random
import time


app = Flask(__name__)
api = Api(app)


class Secret(Resource):
    def get(self):
        s = os.environ.get("AKV_SECRET")
        if s is not None:
            return jsonify({"secret": s, "access_timestamp": time.time()})
        return Response({"error": "secret not found"}, status=404, mimetype='application/json')


api.add_resource(Secret, '/secret')


if __name__ == '__main__':
    app.debug = False
    app.run(host='0.0.0.0', port=4996, threaded=True, ssl_context=(("/tls/flask.crt", "/tls/flask.key")))
