# YuMusic - Garmin Music App for Navidrome/SubSonic

YuMusic é um aplicativo de música para Garmin Smartwatches que permite baixar e reproduzir músicas de servidores compatíveis com SubSonic API, incluindo Navidrome, Gonic, AirSonic e SubSonic.

## 🎵 Características

- ✅ Compatível com Navidrome, Gonic, AirSonic e SubSonic
- ✅ Suporte para API SubSonic 1.16.1
- ✅ Download de músicas via Wi-Fi
- ✅ Reprodução offline
- ✅ Navegação por playlists
- ✅ Modo shuffle
- ✅ Scrobbling automático (marca músicas como reproduzidas)
- ✅ Suporte para thumbs up/down (favoritar/desfavoritar)
- ✅ Interface otimizada para telas redondas AMOLED (416x416)
- ✅ Compatível com Garmin Venu 2

## 📋 Requisitos

- **Garmin Smartwatch** compatível com música (ex: Venu 2, Venu 2 Plus, etc.)
- **Connect IQ SDK 8.3.0** ou superior
- **API Level 5.0** ou superior
- **Servidor SubSonic/Navidrome/Gonic** configurado e acessível
- **Conexão Wi-Fi** no smartwatch
- **Garmin Connect** app no smartphone

## 🚀 Instalação

### 1. Compilar o Aplicativo

```bash
# Clone o repositório
git clone https://github.com/seu-usuario/yumusic-garmin-music-app.git
cd yumusic-garmin-music-app

# Compile usando o Connect IQ SDK
# Certifique-se de ter o SDK instalado e configurado
```

### 2. Instalar no Smartwatch

1. Conecte seu Garmin Venu 2 ao computador via USB
2. Copie o arquivo `.prg` compilado para a pasta `GARMIN/APPS` do dispositivo
3. Ou use o Garmin Express/Connect IQ para instalar

## ⚙️ Configuração

### Passo 1: Configurar o Servidor

**IMPORTANTE**: A configuração do servidor deve ser feita através do aplicativo **Garmin Connect** no smartphone, não diretamente no relógio.

1. Abra o **Garmin Connect** no seu smartphone
2. Vá para **Dispositivos** → Selecione seu **Venu 2**
3. Vá para **Aplicativos Connect IQ** → **YuMusic**
4. Configure as seguintes informações:
   - **Server URL**: URL completo do seu servidor (ex: `https://music.example.com`)
   - **Username**: Seu nome de usuário
   - **Password**: Sua senha

**Exemplo de configuração:**
```
Server URL: https://navidrome.meuservidor.com
Username: meu_usuario
Password: minha_senha_segura
```

### Passo 2: Selecionar Músicas para Sincronizar

1. No seu **Venu 2**, pressione e segure o botão inferior para acessar o menu
2. Vá para **Configurações** → **Música** → **Provedores de Música**
3. Selecione **YuMusic**
4. Escolha **Adicionar Música e Podcasts**
5. Selecione as playlists que deseja sincronizar
6. O relógio irá se conectar ao Wi-Fi e começar a baixar as músicas

### Passo 3: Sincronizar Músicas

1. Certifique-se de que seu relógio está conectado ao Wi-Fi
2. Conecte o relógio ao carregador (recomendado para downloads longos)
3. O processo de sincronização começará automaticamente
4. Aguarde até que todas as músicas sejam baixadas

## 🎧 Como Usar

### Reproduzir Músicas

1. Pressione e segure o botão inferior
2. Vá para **Música**
3. Selecione **YuMusic** como provedor
4. Use os controles de música do relógio para:
   - ▶️ Play/Pause
   - ⏭️ Próxima música
   - ⏮️ Música anterior
   - 👍 Thumbs up (favoritar)
   - 👎 Thumbs down (desfavoritar)

### Ativar/Desativar Shuffle

1. Vá para **Configurações de Reprodução** no menu do YuMusic
2. Pressione o botão de seleção
3. Escolha **Ativar Shuffle** ou **Desativar Shuffle**

### Limpar Biblioteca

1. Vá para **Configurações de Reprodução**
2. Selecione **Limpar Biblioteca**
3. Confirme a ação

## 🏗️ Arquitetura do Projeto

```
yumusic-garmin-music-app/
├── source/
│   ├── YuMusicApp.mc                      # Aplicativo principal
│   ├── YuMusicSubsonicAPI.mc              # Cliente API SubSonic
│   ├── YuMusicServerConfig.mc             # Gerenciamento de configuração
│   ├── YuMusicLibrary.mc                  # Gerenciamento de biblioteca
│   ├── YuMusicContentDelegate.mc          # Delegado de conteúdo de mídia
│   ├── YuMusicContentIterator.mc          # Iterador de músicas
│   ├── YuMusicSyncDelegate.mc             # Delegado de sincronização
│   ├── YuMusicConfigurePlaybackView.mc    # View de configuração de reprodução
│   ├── YuMusicConfigurePlaybackDelegate.mc # Delegate de reprodução
│   ├── YuMusicConfigureSyncView.mc        # View de configuração de sync
│   ├── YuMusicConfigureSyncDelegate.mc    # Delegate de sync
│   ├── YuMusicPlaylistMenuDelegate.mc     # Delegate de menu de playlists
│   ├── YuMusicPlaybackMenuDelegate.mc     # Delegate de menu de reprodução
│   ├── YuMusicServerConfigView.mc         # View de configuração do servidor
│   ├── YuMusicServerConfigDelegate.mc     # Delegate de configuração
│   ├── YuMusicLoadingView.mc              # View de carregamento
│   ├── YuMusicConfirmView.mc              # View de confirmação
│   └── YuMusicConfirmDelegate.mc          # Delegate de confirmação
├── resources/
│   ├── drawables/
│   ├── layouts/
│   │   ├── configurePlaybackLayout.xml
│   │   └── configureSyncLayout.xml
│   └── strings/
│       └── strings.xml
└── manifest.xml
```

## 🔧 Desenvolvimento

### Requisitos de Desenvolvimento

- **Connect IQ SDK 8.3.0+**
- **Visual Studio Code** com extensão Monkey C
- **Java** (para o SDK)

### Compilar

```bash
# Usando o SDK Manager
monkeyc -d venu2 -f monkey.jungle -o bin/YuMusic.prg -y developer_key
```

### Testar no Simulador

```bash
# Iniciar simulador
connectiq

# Executar app
monkeydo bin/YuMusic.prg venu2
```

## 📱 Dispositivos Compatíveis

Este aplicativo foi desenvolvido e testado para:
- **Garmin Venu 2** (416x416, AMOLED, round)

Pode funcionar em outros dispositivos Garmin com suporte a música e API Level 5.0+, mas pode requerer ajustes na interface.

## 🔐 Segurança

- As credenciais são armazenadas de forma segura no dispositivo usando `Application.Storage`
- A autenticação usa MD5 hash com salt aleatório (conforme especificação SubSonic API 1.13.0+)
- As senhas nunca são enviadas em texto plano

## 🐛 Solução de Problemas

### Servidor não conecta
- Verifique se a URL do servidor está correta e acessível
- Certifique-se de que o servidor usa HTTPS (recomendado)
- Verifique suas credenciais de login

### Músicas não sincronizam
- Certifique-se de que o relógio está conectado ao Wi-Fi
- Verifique se há espaço suficiente no dispositivo
- Conecte o relógio ao carregador durante a sincronização

### Músicas não aparecem
- Verifique se a sincronização foi concluída
- Tente limpar a biblioteca e sincronizar novamente
- Verifique se as playlists têm músicas no servidor

## 📝 API SubSonic Suportada

O YuMusic implementa os seguintes endpoints da API SubSonic:

- `ping` - Testar conexão
- `getPlaylists` - Listar playlists
- `getPlaylist` - Obter detalhes da playlist
- `getRandomSongs` - Obter músicas aleatórias
- `getArtists` - Listar artistas
- `getArtist` - Obter detalhes do artista
- `getAlbum` - Obter detalhes do álbum
- `search3` - Buscar músicas, álbuns e artistas
- `download` - Baixar música
- `stream` - Stream de música
- `getCoverArt` - Obter capa do álbum
- `scrobble` - Marcar música como reproduzida
- `star` - Favoritar
- `unstar` - Desfavoritar

## 🤝 Contribuindo

Contribuições são bem-vindas! Por favor:

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/MinhaFeature`)
3. Commit suas mudanças (`git commit -m 'Adiciona MinhaFeature'`)
4. Push para a branch (`git push origin feature/MinhaFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.

## 🙏 Agradecimentos

- Garmin por fornecer o Connect IQ SDK
- Comunidade Navidrome
- Projeto SubSonic API

## 📧 Suporte

Para problemas, sugestões ou dúvidas:
- Abra uma issue no GitHub
- Entre em contato através do Garmin Connect IQ Store

---

**Nota**: Este é um projeto independente e não é oficialmente afiliado com Garmin, Navidrome, Gonic, AirSonic ou SubSonic.
