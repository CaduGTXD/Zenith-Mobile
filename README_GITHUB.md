# Zenith Mobile — distribuição pelo GitHub

Repositório configurado:

`CaduGTXD/Zenith-Mobile`

Coloque estes dois arquivos na raiz da branch `main`:

- `install.lua`
- `ZenithMobile.zip`

No console Lua do OTClient Redemption, execute a linha disponível em `COMANDO_CONSOLE.txt`.

O repositório é público, portanto não é necessário login, token ou autenticação.

O instalador:

1. baixa o pacote diretamente do GitHub;
2. extrai dentro de `/bot/Zenith Mobile` no diretório gravável do app;
3. preserva configurações pessoais e rotas criadas pelo jogador;
4. seleciona o perfil `Zenith Mobile`;
5. ativa e recarrega o módulo `game_bot`.

Para publicar uma atualização, substitua `ZenithMobile.zip` na branch `main` e execute novamente o mesmo comando no cliente.
