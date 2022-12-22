FROM python:3.10

LABEL envs='[{"name":"PPRL_RESOLVER_PROXY_URL","type":"string","required":true},{"name":"PPRL_SESSION_SECRET","type":"string","required":true},{"name":"PPRL_DATA_DOMAIN","type":"string","required":true},{"name":"PPRL_PHASE","type":"string","required":true},{"name":"PPRL_PSEUDONYM_LIST_URL","type":"string","required":true}]'

WORKDIR /home

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD python main.py