# YuMusic - Garmin Music App for Navidrome/Subsonic

Um aplicativo de música para smartwatches Garmin compatível com servidores Navidrome, Gonic, AirSonic e SubSonic.

## 🎵 Características

- **Download de música** - baixe músicas do servidor para reprodução offline (sem streaming)
- **Autenticação segura** usando token MD5
- **Configuração via Garmin Connect** - configure URL, usuário e senha pelo app móvel
- **Interface Pure Black Dark** com acentos laranja (#FF6600) - otimizada para AMOLED
- **Navegação de música** por artistas, álbuns, playlists e músicas aleatórias
- **Controles de reprodução** completos (play/pause, próxima, anterior)
- **Scrobbling automático** - marca músicas como reproduzidas no servidor
- **Favoritos** - adicione músicas aos favoritos com thumbs up/down
- **Modo shuffle** - reprodução aleatória
- **Interface otimizada** para telas redondas (416x416) sem texto cortado

## 📱 Dispositivos Compatíveis

Este aplicativo é compatível com smartwatches Garmin que suportam:
- API Level 5.0 ou superior
- Audio Content Provider Apps
- Especialmente otimizado para **Garmin Venu 2** (416x416 AMOLED)

### Dispositivos Testados
- Garmin Venu 2
- Garmin Venu 2S
- Garmin Venu 2 Plus
- Garmin Venu 3/3S
- Forerunner 965
- Fenix 7/7S/7X
- E muitos outros...

## 🚀 Como Usar

### 1. Configuração Inicial

**IMPORTANTE**: A configuração do servidor DEVE ser feita através do aplicativo Garmin Connect Mobile no seu smartphone.

1. Instale o app YuMusic no seu smartwatch Garmin
2. Abra o aplicativo **Garmin Connect Mobile** no seu smartphone
3. Vá para **Dispositivos** → Seu smartwatch → **Atividades, Apps e Mais**
4. Encontre **YuMusic** na lista e toque nele
5. Toque em **Configurações** (ícone de engrenagem)
6. Configure os seguintes parâmetros:
   - **Server URL**: URL completo do seu servidor incluindo porta
     - Exemplo local: `http://192.168.1.100:4533`
     - Exemplo remoto: `https://music.seudominio.com`
     - NÃO adicione `/rest` ao final - apenas a URL base
   - **Username**: Seu nome de usuário do servidor
   - **Password**: Sua senha do servidor
7. Toque em **Salvar**

### 2. Testando a Conexão

1. No smartwatch, abra o app YuMusic
2. Navegue até **"Sync Settings"** (Configurações de Sincronização)
3. Pressione o botão **SELECT** para testar a conexão
4. Aguarde alguns segundos
5. Você verá:
   - **✓ Success!** (laranja) - Conexão bem-sucedida, pronto para sincronizar
   - **✗ Failed** (vermelho) - Falha na conexão, verifique as configurações

### 3. Baixar Músicas (Sync)

**Importante**: O app baixa músicas para o relógio, não faz streaming.

1. No smartwatch, abra o app YuMusic
2. Navegue até a opção **Sync**
3. O app iniciará o download de 20 músicas aleatórias
4. Aguarde o processo de sincronização completar
5. As músicas ficam armazenadas no relógio para reprodução offline

### 4. Reproduzindo Música

1. No app YuMusic, selecione **"Select Music"** (Selecionar Música)
2. Escolha uma fonte de música:
   - **Random Songs**: Músicas aleatórias baixadas
   - **Playlists**: Suas playlists do servidor
   - **Artists**: Navegar por artistas
   - **Albums**: Navegar por álbuns
   - **Search**: Buscar músicas (em desenvolvimento)
3. Use os botões do relógio para navegar (↑/↓) e selecionar
4. A reprodução iniciará automaticamente das músicas baixadas

### 4. Controles Durante a Reprodução

- **Botão SELECT**: Play/Pause
- **Swipe para cima**: Próxima música
- **Swipe para baixo**: Música anterior
- **Thumbs Up**: Adicionar aos favoritos
- **Thumbs Down**: Remover dos favoritos
- **Menu**: Ativar/desativar shuffle

## 🔧 Configuração do Servidor

### Navidrome

1. Certifique-se de que seu servidor Navidrome está acessível pela internet ou na mesma rede Wi-Fi
2. A URL deve incluir o protocolo: `http://` ou `https://`
3. Exemplo: `https://navidrome.exemplo.com`

### Subsonic/AirSonic/Gonic

Todos os servidores compatíveis com a API Subsonic v1.16.1 funcionam:
- Subsonic
- AirSonic
- AirSonic Advanced
- Gonic
- Navidrome

## 📡 Requisitos de Rede

- **Wi-Fi**: O smartwatch deve estar conectado ao Wi-Fi para streaming
- **Conexão com o smartphone**: Necessária para configuração inicial
- **Servidor acessível**: O servidor deve estar acessível pela rede do smartwatch

## 🔐 Segurança

- As senhas são armazenadas localmente no smartwatch de forma segura
- A autenticação usa token MD5 com salt aleatório (API Subsonic v1.13.0+)
- Nenhuma informação é enviada para servidores de terceiros

## 🎨 Interface

A interface foi completamente redesenhada para telas redondas AMOLED:
- **Tema Pure Black Dark** - fundo preto puro (#000000) para economia de bateria em AMOLED
- **Acentos Laranja** (#FF6600) - alta visibilidade e contraste
- **416x416 pixels** (Venu 2) - otimizado para displays redondos
- **Sem texto cortado** - todo o texto é totalmente visível
- **Espaçamento adequado** - elementos bem posicionados em telas circulares
- Texto grande e legível
- Navegação intuitiva com botões físicos
- Feedback visual claro com ícones ✓ e ✗

## 🛠️ Desenvolvimento

### Estrutura do Projeto

```
yumusic-garmin-music-app/
├── source/
│   ├── yumusicApp.mc              # Aplicativo principal
│   ├── SubsonicAPI.mc             # Cliente da API Subsonic
│   ├── SettingsManager.mc         # Gerenciador de configurações
│   ├── MusicLibrary.mc            # Biblioteca de músicas
│   ├── yumusicContentDelegate.mc  # Delegado de conteúdo
│   ├── yumusicContentIterator.mc  # Iterador de reprodução
│   ├── yumusicConfigurePlaybackView.mc    # View de configuração de reprodução
│   ├── yumusicConfigurePlaybackDelegate.mc # Delegate de reprodução
│   ├── yumusicConfigureSyncView.mc        # View de configuração de sync
│   ├── yumusicConfigureSyncDelegate.mc    # Delegate de sync
│   └── yumusicSyncDelegate.mc     # Delegado de sincronização
├── resources/
│   ├── drawables/
│   ├── layouts/
│   └── strings/
├── manifest.xml
└── monkey.jungle
```

### Compilação

1. Instale o [Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/)
2. Configure o SDK Manager com SDK 8.3.0
3. Compile o projeto:
   ```bash
   monkeyc -o yumusic.prg -f monkey.jungle -y developer_key.der
   ```

### API Subsonic Implementada

- ✅ `ping` - Teste de conexão
- ✅ `getArtists` - Listar artistas
- ✅ `getArtist` - Detalhes do artista
- ✅ `getAlbum` - Detalhes do álbum
- ✅ `search3` - Busca de músicas
- ✅ `getRandomSongs` - Músicas aleatórias
- ✅ `getPlaylists` - Listar playlists
- ✅ `getPlaylist` - Detalhes da playlist
- ✅ `stream` - Stream de música
- ✅ `getCoverArt` - Arte do álbum
- ✅ `scrobble` - Marcar como reproduzida
- ✅ `star/unstar` - Favoritar/desfavoritar

## 🐛 Solução de Problemas

### "Connection Failed"
- Verifique se a URL do servidor está correta
- Confirme que o servidor está acessível
- Verifique suas credenciais de login
- Certifique-se de que o smartwatch está conectado ao Wi-Fi

### "Not Configured"
- Configure o servidor através do app Garmin Connect Mobile
- Reinicie o app YuMusic após configurar

### Música não reproduz
- Verifique a conexão Wi-Fi do smartwatch
- Confirme que o servidor tem músicas disponíveis
- Tente selecionar "Random Songs" primeiro

### Sem arte de álbum
- A arte do álbum requer download adicional
- Funcionalidade em desenvolvimento

## 📝 Roadmap

- [x] Configuração via Garmin Connect Mobile (Properties API)
- [x] Download de músicas para reprodução offline
- [x] Interface Pure Black Dark com acentos laranja
- [x] Otimização para telas redondas sem texto cortado
- [ ] Otimização do processo de download de músicas
- [ ] Arte de álbum completa
- [ ] Busca de músicas
- [ ] Navegação completa por artistas/álbuns
- [ ] Seleção de playlists para download
- [ ] Gerenciamento de armazenamento
- [ ] Criação de playlists
- [ ] Equalizer
- [ ] Letras de músicas

## 📄 Licença

Este projeto é de código aberto. Sinta-se livre para usar, modificar e distribuir.

## 🤝 Contribuições

Contribuições são bem-vindas! Sinta-se à vontade para:
- Reportar bugs
- Sugerir novas funcionalidades
- Enviar pull requests
- Melhorar a documentação

## 📧 Suporte

Para suporte e dúvidas:
- Abra uma issue no GitHub
- Consulte a documentação da API Subsonic
- Verifique os logs do servidor Navidrome

## 🙏 Agradecimentos

- Garmin Connect IQ SDK
- Projeto Navidrome
- Comunidade Subsonic API
- Todos os contribuidores

---

**Desenvolvido com ❤️ para a comunidade Garmin e Navidrome**
