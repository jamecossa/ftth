# Registo FTTH - relatorio de seguranca

Resumo: foram encontrados e corrigidos 1 problema grave, 6 medios e varios menores no codigo.
Alem disso, ha 6 definicoes no Supabase/GitHub que so tu podes ativar (secao 3).

## 1. O que foi encontrado e corrigido

### Grave
**Injecao de HTML/JavaScript (XSS).** Nomes de servicos, nome da pessoa, campos de pesquisa e mensagens de erro entravam no HTML sem proteccao. Um nome como `<img src=x onerror=...>` executava codigo dentro da pagina e podia roubar a sessao (guardada no navegador).
Havia tambem um cenario pior: alguem que registasse a conta com o email de outra pessoa (sem confirmacao de email) podia deixar dados maliciosos na conta e esperar que a vitima a recuperasse.
- Correcao: tudo o que vem de dados e escapado antes de entrar no HTML (funcao `esc`), incluindo valores de campos, mensagens e a foto.
- Verificado com testes: a versao anterior deixava passar o codigo; a nova mostra-o como texto.

### Medio
1. **Passwords antigas em texto simples.** A primeira versao da app guardava contas e passwords no `localStorage` do telemovel/navegador. As contas agora estao no Supabase e a app apaga as passwords antigas que encontre no dispositivo.
2. **Dados da base de dados aceites sem validacao.** Categorias invalidas, quantidades negativas, ids estranhos (`__proto__`), datas invalidas ou totais adulterados podiam estragar a app ou os calculos. Agora tudo e validado e limpo ao carregar (tipos, limites, ids seguros, totais recalculados).
3. **Sem Content-Security-Policy.** Foi adicionada uma CSP que so deixa correr o script da propria pagina (por hash), so permite ligacoes ao teu Supabase, bloqueia iframes/objetos/formularios externos e define `no-referrer`.
4. **Password fraca (minimo 4/6).** Agora: 8 a 72 caracteres, com letras e numeros (registo, recuperacao e mudanca de password).
5. **Copias de seguranca Android com a sessao.** O Android pode copiar os dados da app para a nuvem (`allowBackup`). O workflow desliga isto; tambem ficam desligados o debug do WebView e o trafego sem HTTPS.
6. **Fontes do Google.** A pagina carregava fontes de servidores da Google (dependencia externa e problema de privacidade/RGPD). Foram removidas; a app usa as fontes do sistema (tambem funciona offline).

### Menor
- **Terminar sessao** termina so neste dispositivo (antes podia terminar em todos).
- **Fotografia:** so aceita imagens ate 10 MB; e reconvertida para JPEG pequeno e so e mostrada se for um JPEG valido gerado pela app.
- **Tema e idioma** guardados no dispositivo sao validados (valores adulterados sao ignorados).
- **Quantidades e precos** limitados e validados; maximo de 500 servicos e 50 000 registos.
- **Clickjacking:** a app nao corre dentro de iframes de outros sites.
- **Base de dados:** limites de tamanho e tipo no SQL, e acesso removido ao papel `anon` (visitantes sem conta).
- **GitHub Actions:** permissoes minimas (`contents: read`), so corre manualmente e o APK expira em 7 dias.

## 2. O que ja estava certo
- A chave usada na pagina e a `publishable` (publica por desenho); nao ha chave secreta no ficheiro.
- Seguranca por linha (RLS): cada conta so le e escreve os seus dados.
- Login com mensagem igual para email inexistente e password errada; recuperacao nao revela se o email existe.
- O link de recuperacao so aponta para o endereco fixo da app; o token e retirado do endereco assim que a pagina abre.
- Sem `eval`, sem `document.write`, sem scripts externos, sem handlers inline.

## 3. O que tens de fazer tu (Supabase e GitHub)
1. **Correr o `supabase_app_data.sql`** (versao nova) no SQL Editor.
2. **Authentication > Sign In / Providers > Email:** ativar **Confirm email**. E a defesa contra registos com o email de outra pessoa.
3. **Authentication > Password** (ou Settings): minimo **8** caracteres e, se existir, exigir letras e numeros; ativar "Prevent use of leaked passwords" se o teu plano o permitir.
4. **Authentication > URL Configuration:** Site URL e Redirect URLs com o endereco exato `https://jamecossa.github.io/ftth/` (sem `*` e sem `localhost`).
5. **Authentication > SMTP Settings:** configurar o teu servico de email (o envio por defeito tem limite muito baixo e pior entrega).
6. **Contas pessoais:** ativar verificacao em 2 passos no Supabase e no GitHub.
7. Se so tu usas a app: depois de criares as contas, desativa **Allow new users to sign up**.
8. **Database > Advisors > Security Advisor:** deve estar sem avisos para a tabela `app_data`.

Nao ativar ainda o CAPTCHA do Supabase: a app ainda nao envia o codigo do CAPTCHA e o login deixaria de funcionar. Posso integra-lo se quiseres.

## 4. Riscos que ficam
- A sessao fica no `localStorage` (normal numa pagina web); por isso e que a protecao contra XSS e a CSP importam.
- A CSP permite estilos inline (`style-src 'unsafe-inline'`), necessario para o CSS atual.
- Os dados nao estao cifrados de ponta a ponta: quem administra o projeto Supabase (tu) consegue ve-los.
- O APK gerado e "debug" (assinado com chave de teste). Serve para instalares tu; para distribuir ou publicar na Google Play e preciso assinar uma versao "release".
- Os ficheiros `npm install` do workflow nao estao fixados a versoes exatas; para maior controlo, adiciona um `package-lock.json` ao repositorio.

## 5. Como a CSP afeta as alteracoes
A CSP so deixa correr o script cujo hash esta no `index.html`. Depois de qualquer alteracao ao JavaScript, corre:

    python3 atualizar-csp.py index.html

Sem isso, o navegador bloqueia a pagina e ela fica em branco.

## 6. Como foi verificado
Testes automaticos com um servidor Supabase simulado (59 verificacoes: login, gravacao, recuperacao, dados hostis, XSS, validacao, CSP, limpeza de dados antigos). Nao foi possivel testar contra o teu projeto Supabase real nem num navegador real a partir deste ambiente: faz o teste do passo a passo no endereco do GitHub Pages.
