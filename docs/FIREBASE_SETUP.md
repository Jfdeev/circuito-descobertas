# Configuração do Firebase — passo a passo

Guia para quem vai ligar o projeto ao Firebase. O código já está pronto. Falta
criar o projeto no console, gerar os arquivos de configuração e publicar.
Tudo funciona no **plano Spark** (gratuito, sem cartão).

> Use apenas **dados fictícios** (estandes, e-mails de teste, nomes).

## 0. Pré-requisitos

- Flutter stable recente (testado com 3.47.2; rode `flutter upgrade` se der erro de versão) e Android SDK (`flutter doctor` sem erros no Android).
- Node 20+ (o Firebase CLI já vem como dependência em `firebase/`):
  ```bash
  cd firebase
  npm install
  npx firebase login
  ```
- FlutterFire CLI:
  ```bash
  dart pub global activate flutterfire_cli
  ```

## 1. Criar o projeto

1. <https://console.firebase.google.com> → **Adicionar projeto**.
2. **Ative o Google Analytics** quando o assistente perguntar (crie uma conta GA
   se pedir). Sem isso não há relatório *Tempo real*.
3. Mantenha o plano **Spark**.

## 2. Authentication

Console → **Authentication** → *Começar* → **Método de login**. Ative:

- **E-mail/senha**, usado pela organização no painel.
- **Anônimo**, usado pelo visitante no app.

## 3. Cloud Firestore e regras

1. Console → **Firestore Database** → *Criar banco de dados*. Escolha o modo
   produção e a região `southamerica-east1`.
2. Publique as regras que estão em [`firebase/firestore.rules`](../firebase/firestore.rules):
   ```bash
   cd firebase
   npx firebase use --add          # escolha o projeto e dê o alias "default"
   npx firebase deploy --only firestore:rules
   ```
   Se preferir, cole o conteúdo do arquivo em *Firestore → Regras → Publicar*.

## 4. Administrador do painel

1. **Authentication → Usuários → Adicionar usuário**, com um e-mail e senha de
   teste (ex.: `organizacao@circuito.test`).
2. Copie o **UID** do usuário criado.
3. **Firestore → Iniciar coleção** `admins` → **ID do documento = UID copiado** →
   campo `email` (string) com o e-mail. Sem esse documento o painel mostra
   "não é administradora", porque as regras só deixam admins alterar estandes.

## 5. Ligar os apps ao projeto (FlutterFire)

Os arquivos `lib/firebase_options.dart` de cada app são **provisórios**. Gere os
definitivos:

```bash
cd apps/visitante
flutterfire configure --platforms=android --android-package-name=br.cesupa.circuitodescobertas

cd ../painel
flutterfire configure --platforms=web
```

- O *package name* do Android **precisa** ser `br.cesupa.circuitodescobertas`.
- O comando também cria o `google-services.json` e ajusta o Gradle. Pode
  commitar esses arquivos, pois não são segredos.

## 6. Remote Config (missão surpresa)

Crie os parâmetros no console (**Remote Config → Criar configuração**):

| Parâmetro         | Tipo     | Valor padrão | Uso                                                           |
|-------------------|----------|--------------|---------------------------------------------------------------|
| `missao_ativa`    | Booleano | `false`      | Liga/desliga a missão                                         |
| `missao_estandes` | String   | *(vazio)*    | IDs dos estandes destacados, separados por vírgula            |

Se preferir, publique o modelo pelo CLI: `npx firebase deploy --only remoteconfig`
(arquivo [`firebase/remoteconfig.template.json`](../firebase/remoteconfig.template.json)).

- **IDs dos estandes:** no painel, clique em "ID: … (copiar)" em cada estande e
  cole em `missao_estandes`, por exemplo `aB3dE9,Xy7Kq2`.
- **Ligar a missão:** mude `missao_ativa` para `true` e clique em **Publicar
  alterações**. O app aberto atualiza em segundos, sem reinstalar, porque
  escuta `onConfigUpdated`.
- **Desligar a missão:** volte para `false` e publique de novo.

> ⚠️ **A chamada só aparece se `missao_estandes` tiver o ID de pelo menos um
> estande ativo.** Com a lista vazia, um ID digitado errado ou só estandes
> inativos, o app fica igual e não mostra erro. Copie os IDs pelo link do
> painel e confira que os estandes estão ativos. Faça um ensaio antes de gravar.

## 7. Rodar o painel web

```bash
cd apps/painel
flutter run -d edge        # ou -d chrome
```

Para hospedar de graça no Firebase Hosting:

```bash
flutter build web
cd ../../firebase
npx firebase deploy --only hosting
```

No painel: entre com o admin. Se não houver estandes, use **Criar 3 estandes de
exemplo**, ou **Novo estande**. O botão de QR abre o código; **Abrir para
imprimir** abre a página do QR em outra aba, e lá é só usar Ctrl+P.

## 8. APK assinado

> ⚠️ **Gere o APK só depois do passo 5** (`flutterfire configure`). Um APK
> gerado antes disso usa a configuração provisória e abre apenas a tela
> "Firebase ainda não configurado". Não distribua esse APK.

1. Gere a chave de upload. O `keytool` vem com o Android Studio:
   ```bash
   "C:\Program Files\Android\Android Studio\jbr\bin\keytool" -genkey -v -keystore apps/visitante/android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Crie `apps/visitante/android/key.properties`:
   ```properties
   storePassword=<senha>
   keyPassword=<senha>
   keyAlias=upload
   storeFile=upload-keystore.jks
   ```
   **Nunca** commite `key.properties` nem o `.jks`. Os dois já estão no
   `.gitignore`. Guarde-os fora do repositório também.
3. Gere o APK:
   ```bash
   cd apps/visitante
   flutter build apk --release
   ```
   Saída: `build/app/outputs/flutter-apk/app-release.apk`.

## 9. Firebase App Distribution (1,0 pt)

1. Console → **App Distribution** → selecione o app Android → *Começar*.
2. Arraste o `app-release.apk`. Em **Testadores**, adicione o e-mail de quem vai
   instalar e clique em **Distribuir**.
3. O testador recebe o convite, aceita e instala pelo link (ou pelo app
   *Firebase App Tester*). Grave esse acesso no vídeo.

Pelo CLI:

```bash
npx firebase appdistribution:distribute ../apps/visitante/build/app/outputs/flutter-apk/app-release.apk --app <ID_DO_APP_ANDROID> --testers "testador@exemplo.com" --release-notes "Circuito de Descobertas v1"
```

O `<ID_DO_APP_ANDROID>` aparece em *Configurações do projeto → Seus apps*, no
formato `1:123:android:abc`.

## 10. Google Analytics (1,0 pt)

O app envia dois eventos:

| Evento              | Quando                                        | Parâmetros                      |
|---------------------|-----------------------------------------------|---------------------------------|
| `missao_aberta`     | Toque em **Abrir missão** na tela inicial     | `total_estandes`                |
| `checkin_concluido` | Depois que o check-in foi gravado no Firestore | `estande_id`, `estande_nome`    |

Para ver no console: **Analytics → Relatórios → Tempo real**. No cartão
*Contagem de eventos por Nome do evento*, clique em `checkin_concluido` e depois
em `estande_id` para ver o valor.

Os eventos podem levar alguns minutos para aparecer. Se quiser conferir na hora,
use o DebugView:

```bash
adb shell setprop debug.firebase.analytics.app br.cesupa.circuitodescobertas
```

Para desligar o DebugView depois:

```bash
adb shell setprop debug.firebase.analytics.app .none.
```

## 11. Checklist final

- [ ] Login anônimo e e-mail/senha ativados
- [ ] Regras publicadas
- [ ] `admins/{uid}` criado
- [ ] `flutterfire configure` rodado nos dois apps (e commitado)
- [ ] Parâmetros do Remote Config criados com `missao_ativa = false`
- [ ] Pelo menos 3 estandes fictícios no painel
- [ ] APK assinado enviado ao App Distribution com testador convidado
- [ ] Eventos `missao_aberta` e `checkin_concluido` aparecendo no Tempo real
