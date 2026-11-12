# Circuito de Descobertas

Atividade prática do Laboratório de Programação Mobile (CESUPA). O sistema
incentiva a circulação dos visitantes entre os estandes do Amazon Hacking:

- **Painel web**, em Flutter Web: a organização cadastra os estandes, gera os QR
  codes e acompanha os check-ins.
- **App Android**, em Flutter: o visitante vê os estandes, recebe a missão
  surpresa pelo Remote Config e registra visitas lendo o QR code.

Serviços usados: Cloud Firestore, Firebase Authentication, Remote Config
(com atualização em tempo real), Google Analytics e App Distribution. Tudo
cabe no plano Spark.

> **Configuração do Firebase:** siga [docs/FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md).

## Estrutura

```
apps/
  visitante/        App Android do visitante (Flutter)
  painel/           Painel web da organização (Flutter Web)
packages/
  circuito_comum/   Modelos, formato do QR, missão e repositórios Firestore
                    (compartilhado pelos dois apps)
firebase/
  firestore.rules   Regras de acesso, com testes em firebase/tests
  remoteconfig.template.json
  firebase.json     Deploy de regras, Remote Config e Hosting
docs/
  FIREBASE_SETUP.md Passo a passo do console
```

## Dados no Firestore

| Coleção                          | Campos                                              | Quem escreve                                |
|----------------------------------|-----------------------------------------------------|---------------------------------------------|
| `estandes/{auto-id}`             | `nome`, `descricao`, `localizacao`, `ativo`         | Somente admins                              |
| `checkins/{uid}_{estandeId}`     | `visitanteId`, `estandeId`, `criadoEm` (servidor)   | O próprio visitante, uma vez por estande    |
| `admins/{uid}`                   | `email`                                             | Manual, pelo console                        |

O conteúdo do QR é `circuito-descobertas:estande:<id>`, gerado e lido pelo
pacote `circuito_comum`. A chave composta do check-in evita duplicatas, e as
regras proíbem sobrescrever ou apagar um check-in.

## Requisitos × implementação

| Requisito                                                      | Onde                                                                                    |
|----------------------------------------------------------------|-----------------------------------------------------------------------------------------|
| Autenticar administrador                                       | `apps/painel/lib/acesso_admin.dart`, `PortaoAdmin` em `main.dart`                       |
| Cadastrar/editar estande (nome, descrição, localização, ativo) | `apps/painel/lib/telas/painel_tela.dart`, `estande_form.dart`                           |
| 3 estandes fictícios                                           | Botão **Criar 3 estandes de exemplo** no painel                                         |
| QR por estande, abrir em outra tela e imprimir                 | Diálogo de QR + rota pública `/#/qr/<id>` (`telas/qr_tela.dart`)                        |
| Total de check-ins por estande em tempo real                   | `CheckinRepositorio.observarTotais()` (stream do Firestore)                             |
| Listar estandes ativos (funciona com a missão desligada)       | `apps/visitante/lib/telas/inicio_tela.dart`                                             |
| Ler QR pela câmera e validar antes de gravar                   | `telas/scanner_tela.dart` → `RegistroCheckin`                                           |
| Retorno para QR inválido, estande inativo e visita repetida    | `mensagemCheckin` em `servicos/fluxo_checkin.dart`                                      |
| Uma visita por visitante e estande                             | Chave `uid_estandeId` + regras do Firestore                                             |
| Missão via Remote Config, padrão desligada, tempo real         | `servicos/missao_remota.dart` (`setDefaults` + `onConfigUpdated`)                       |
| Chamada na tela inicial, destaques, tela da missão             | `inicio_tela.dart`, `missao_tela.dart`                                                  |
| Eventos `missao_aberta` e `checkin_concluido` (`estande_id`)   | `servicos/eventos_analytics.dart`                                                       |
| Regras de acesso                                               | `firebase/firestore.rules`                                                              |
| APK assinado                                                   | `android/app/build.gradle.kts` lê `key.properties`                                      |

## Testes

```bash
cd packages/circuito_comum && flutter test
cd apps/visitante && flutter test
cd apps/painel && flutter test

# Regras do Firestore no emulador (precisa de Java; o do Android Studio serve)
cd firebase && npm install && npm run test:rules
```

## Rodando

```bash
# Painel
cd apps/painel
flutter run -d edge

# App (com o celular conectado)
cd apps/visitante
flutter run
```

Enquanto o `flutterfire configure` não for executado, os dois apps abrem uma
tela avisando que o Firebase ainda não foi configurado.

## Roteiro do vídeo

1. Apresentar os integrantes. Mostrar o app sendo acessado e instalado pelo
   **App Distribution** (convite do testador).
2. No **painel**, cadastrar um estande e mostrar que ele aparece no app.
   Mostrar o QR gerado e abrir a página de impressão.
3. No console do **Remote Config**, colocar os IDs em `missao_estandes`,
   mudar `missao_ativa = true` e publicar. No app, mostrar a chamada e os
   destaques, abrir a missão e fazer o check-in lendo o QR. No painel,
   conferir o total. Publicar `missao_ativa = false` e mostrar a chamada
   sumindo no mesmo app.
   **Atenção:** `missao_estandes` precisa ter IDs de estandes **ativos**,
   copiados pelo link "ID (copiar)" do painel. Com a lista vazia ou errada, a
   chamada não aparece e nenhum erro é mostrado.
4. No **GA4**: Relatórios → Tempo real → cartão de eventos. Mostrar
   `missao_aberta` e `checkin_concluido`, abrir o check-in e mostrar
   `estande_id`.
