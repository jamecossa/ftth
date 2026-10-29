#!/usr/bin/env python3
"""Recalcula o hash do CSP no index.html.

A app usa uma Content-Security-Policy que so deixa correr o script cujo hash
esta indicado no ficheiro. Sempre que alterares o JavaScript do index.html
(a mao ou com ajuda), corre:

    python3 atualizar-csp.py index.html

Se nao o fizeres, o navegador bloqueia o script e a pagina fica em branco.
"""
import base64, hashlib, re, sys

path = sys.argv[1] if len(sys.argv) > 1 else "index.html"
with open(path, encoding="utf-8", newline="") as f:
    s = f.read()

m = re.search(r"<script>(.*?)</script>", s, re.S)
if not m or s.count("<script") != 1:
    sys.exit("Erro: o ficheiro deve ter exatamente um <script> inline.")

js = m.group(1).replace("\r\n", "\n")
h = base64.b64encode(hashlib.sha256(js.encode("utf-8")).digest()).decode()
novo, n = re.subn(r"script-src 'sha256-[^']*'", "script-src 'sha256-%s'" % h, s, count=1)
if n != 1:
    sys.exit("Erro: nao encontrei a regra script-src no CSP.")

with open(path, "w", encoding="utf-8", newline="") as f:
    f.write(novo)
print("CSP atualizado:", h)
