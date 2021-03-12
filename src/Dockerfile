ARG SCONE_VERSION=5.2.1

FROM registry.scontain.com:5050/clenimar/azure-integration-demo:python3.7-scone${SCONE_VERSION}

WORKDIR /app

COPY requirements.txt requirements.txt

COPY rest_api.py rest_api.py

RUN pip install -r requirements.txt

ENTRYPOINT [ "python3", "/app/rest_api.py" ]