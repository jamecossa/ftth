# Registo FTTH - criar a app Android

Este projeto usa o Capacitor para transformar o `www/index.html` numa app Android (APK).

## O que precisas de instalar (uma vez)
1. **Node.js** (versao LTS): https://nodejs.org
2. **Android Studio**: https://developer.android.com/studio
   (ao instalar, deixa instalar o Android SDK e o JDK que vem com ele)

## Passos

Abre um terminal dentro desta pasta (`ftth-android`) e corre:

```bash
npm install
npm install @capacitor/core @capacitor/cli @capacitor/android
npx cap add android
npx cap sync android
npx cap open android
```

O ultimo comando abre o projeto no Android Studio.

## Gerar o APK para instalar no telemovel
No Android Studio:
1. Espera que o Gradle termine de sincronizar (barra no fundo).
2. Menu **Build > Build Bundle(s) / APK(s) > Build APK(s)**.
3. Quando terminar, clica em **locate** na notificacao. O ficheiro e `app-debug.apk`.
4. Passa o APK para o telemovel e instala (pode ser preciso permitir "instalar de fontes desconhecidas").

Para testar sem gerar APK: liga o telemovel por USB (com "Depuracao USB" ativa) e carrega no botao verde **Run**.

## Para publicar na Google Play
Em vez de APK debug, usa **Build > Generate Signed Bundle / APK** e cria uma chave de assinatura (guarda-a bem, sem ela nao consegues atualizar a app).

## Atualizar a app depois de mudares o index.html
1. Substitui `www/index.html` pelo ficheiro novo.
2. Corre `npx cap sync android`.
3. Gera o APK outra vez no Android Studio.

## Nome e icone
- O nome ("Registo FTTH") e o `appName` no `capacitor.config.json`.
- O icone: no Android Studio, botao direito em `app/res` > **New > Image Asset**.

## Notas importantes
- **Fontes:** a pagina carrega as fontes do Google Fonts. Sem internet, a app usa fontes do sistema (funciona na mesma, so muda o aspeto das letras).
- **Dados:** ficam guardados no proprio telemovel (localStorage). Se desinstalares a app ou limpares os dados, perdes tudo. Cada telemovel tem os seus dados.
- **Passwords:** as passwords ficam guardadas em texto simples no telemovel. Serve para uso pessoal, nao para dados sensiveis.
- **Atualizar o Capacitor:** se algum comando der erro por versoes, consulta https://capacitorjs.com/docs/getting-started

---

# Alternativa: gerar o APK online (sem instalar nada)

Usa o GitHub Actions, que e gratuito e corre no teu repositorio.

1. No repositorio `ftth`, garante que o `index.html` esta na raiz.
2. Adiciona ao repositorio (botao **Add file > Create new file**):
   - `capacitor.config.json` (conteudo deste projeto)
   - `.github/workflows/build-apk.yml` (conteudo deste projeto; escreve o caminho completo no nome do ficheiro)
3. Vai ao separador **Actions**, escolhe **Build APK** e clica em **Run workflow**.
4. Espera cerca de 5 a 10 minutos. Quando ficar verde, abre a execucao e, em **Artifacts**, descarrega `registo-ftth-apk`.
5. Descomprime o zip: la dentro esta o `app-debug.apk`. Instala-o no telemovel.

Se der erro, abre a execucao com a cruz vermelha e copia a mensagem do passo que falhou.

---

# Supabase (contas e base de dados online)

A app usa o Supabase para contas (email + password), recuperacao de password por email e para guardar os dados.

- Project URL e chave publica: estao no inicio do script do `index.html` (SUPABASE_URL e SUPABASE_KEY). A chave `sb_publishable_...` e publica por desenho; nunca coloques a chave `secret` / `service_role` no ficheiro.
- SITE_URL (tambem no `index.html`) e o endereco onde a pagina esta publicada, usado no link do email de recuperacao. Tem de ser igual ao "Site URL" e estar nos "Redirect URLs" em Authentication > URL Configuration.
- Tabela `app_data` com seguranca por linha (RLS): cada pessoa so ve os seus dados. O SQL esta na conversa e tem de estar executado no SQL Editor do Supabase.
- Palavra-passe: minimo de 6 caracteres (regra do Supabase).
- O APK precisa de internet para entrar e guardar dados.

---

# Seguranca

Le o ficheiro `SEGURANCA.md` (o que foi corrigido e o que tens de configurar no Supabase e no GitHub).
Se alterares o JavaScript do `index.html`, corre `python3 atualizar-csp.py index.html` para atualizar a politica de seguranca (CSP); sem isso o navegador bloqueia o script e a pagina fica em branco.
Usa o ficheiro `supabase_app_data.sql` (versao reforcada) no SQL Editor do Supabase.
