# Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

## [1.0.0] - 2025-10-01

### ✨ Adicionado

#### Core Features
- **Subsonic API Client** completo com autenticação MD5
- **Streaming de música** direto do servidor Navidrome/Subsonic
- **Navegação de música** por:
  - Músicas aleatórias
  - Playlists
  - Artistas
  - Álbuns
- **Controles de reprodução**:
  - Play/Pause
  - Próxima música
  - Música anterior
  - Shuffle mode

#### Funcionalidades
- **Scrobbling automático** - marca músicas como reproduzidas no servidor
- **Sistema de favoritos** - thumbs up/down para star/unstar músicas
- **Gerenciamento de configurações** - armazenamento seguro de credenciais
- **Biblioteca de músicas** - gerenciamento local de queue e playlists
- **Teste de conexão** - verificação de conectividade com o servidor

#### Interface
- **UI otimizada para telas redondas** (416x416 AMOLED)
- **View de configuração de sync** - setup do servidor
- **View de configuração de playback** - seleção de fonte de música
- **Navegação intuitiva** com botões físicos do smartwatch

#### Documentação
- README completo em português
- Guia de configuração rápida (SETUP.md)
- Guia de contribuição (CONTRIBUTING.md)
- Changelog

### 🔧 Técnico

#### Arquitetura
- **SubsonicAPI.mc** - Cliente da API Subsonic v1.16.1
- **SettingsManager.mc** - Gerenciador de configurações persistentes
- **MusicLibrary.mc** - Biblioteca e queue de músicas
- **yumusicContentDelegate.mc** - Delegado de eventos de mídia
- **yumusicContentIterator.mc** - Iterator para reprodução
- **yumusicApp.mc** - Aplicativo principal AudioContentProviderApp

#### API Subsonic Implementada
- `ping` - Teste de conexão
- `getArtists` - Listar artistas
- `getArtist` - Detalhes do artista
- `getAlbum` - Detalhes do álbum
- `search3` - Busca de músicas
- `getRandomSongs` - Músicas aleatórias
- `getPlaylists` - Listar playlists
- `getPlaylist` - Detalhes da playlist
- `stream` - Stream de música
- `getCoverArt` - URL da arte do álbum
- `scrobble` - Marcar como reproduzida
- `star/unstar` - Favoritar/desfavoritar

#### Segurança
- Autenticação MD5 com salt aleatório
- Armazenamento seguro de credenciais
- Suporte a HTTPS

### 📱 Compatibilidade

- **API Level**: 5.0.0+
- **SDK**: Connect IQ 8.3.0
- **Dispositivos**: Todos os smartwatches Garmin com suporte a Audio Content Provider
- **Testado em**: Garmin Venu 2 (416x416 AMOLED)

### 🎯 Roadmap Futuro

#### Planejado para v1.1.0
- [ ] Download de músicas para reprodução offline
- [ ] Cache de arte de álbum
- [ ] Busca de músicas funcional
- [ ] Navegação completa por artistas/álbuns
- [ ] Melhorias de performance

#### Planejado para v1.2.0
- [ ] Criação e edição de playlists
- [ ] Equalizer
- [ ] Letras de músicas
- [ ] Estatísticas de reprodução
- [ ] Temas personalizáveis

### 🐛 Problemas Conhecidos

- Arte de álbum não é exibida (requer download separado)
- Busca de músicas ainda não implementada
- Navegação de artistas/álbuns limitada
- Sem suporte para reprodução offline ainda

### 📝 Notas

- Primeira versão pública
- Requer configuração via Garmin Connect Mobile
- Necessita conexão Wi-Fi para streaming
- Compatível com Navidrome, Gonic, AirSonic e SubSonic

---

## Formato

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Semantic Versioning](https://semver.org/lang/pt-BR/).

### Tipos de Mudanças

- **Adicionado** para novas funcionalidades
- **Modificado** para mudanças em funcionalidades existentes
- **Descontinuado** para funcionalidades que serão removidas
- **Removido** para funcionalidades removidas
- **Corrigido** para correção de bugs
- **Segurança** para vulnerabilidades
