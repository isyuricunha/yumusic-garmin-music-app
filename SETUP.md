# Guia de Configuração Rápida - YuMusic

## 📋 Pré-requisitos

1. **Smartwatch Garmin** compatível (Venu 2, Venu 3, Fenix 7, etc.)
2. **Servidor Navidrome/Subsonic** rodando e acessível
3. **Aplicativo Garmin Connect Mobile** instalado no smartphone
4. **Conexão Wi-Fi** configurada no smartwatch

## 🔧 Passo a Passo

### 1. Instalar o App no Smartwatch

1. Abra o **Garmin Connect Mobile** no smartphone
2. Vá para **Mais** → **Connect IQ Store**
3. Procure por **"yumusic"**
4. Toque em **Instalar**
5. Aguarde a sincronização com o smartwatch

### 2. Configurar o Servidor

**⚠️ IMPORTANTE**: Esta etapa DEVE ser feita pelo smartphone!

1. No **Garmin Connect Mobile**, vá para:
   - **Dispositivos** → [Seu Smartwatch] → **Apps**
   
2. Encontre **YuMusic** na lista e toque nele

3. Toque em **Configurações** (ícone de engrenagem)

4. Preencha os campos:

   ```
   Server URL: https://seu-servidor.com
   Username: seu_usuario
   Password: sua_senha
   ```

   **Exemplos de Server URL:**
   - `https://navidrome.exemplo.com`
   - `http://192.168.1.100:4533`
   - `https://music.meudominio.com.br`

5. Toque em **Salvar**

### 3. Testar a Conexão

1. No **smartwatch**, abra o app **YuMusic**

2. Navegue até **"Configure Sync"** usando os botões ↑/↓

3. Pressione o botão **SELECT** (botão central/superior direito)

4. Aguarde alguns segundos

5. Se aparecer **"Connected! Ready to sync"** → ✅ Sucesso!

6. Se aparecer **"Connection failed"** → ❌ Veja a seção de problemas abaixo

### 4. Começar a Ouvir Música

1. No app YuMusic, navegue até **"Configure Playback"**

2. Pressione **SELECT**

3. Escolha uma opção:
   - **Random Songs** (recomendado para primeiro teste)
   - **Playlists**
   - **Artists**
   - **Albums**

4. Pressione **SELECT** novamente

5. Aguarde o carregamento (alguns segundos)

6. A música começará a tocar automaticamente! 🎵

## 🎮 Controles Básicos

Durante a reprodução:

| Ação | Botão/Gesto |
|------|-------------|
| Play/Pause | SELECT |
| Próxima música | Swipe ↑ ou botão UP |
| Música anterior | Swipe ↓ ou botão DOWN |
| Favoritar | Thumbs Up (se disponível) |
| Menu | Botão MENU |
| Voltar | Botão BACK |

## ❌ Problemas Comuns

### "Connection failed"

**Possíveis causas:**

1. **URL incorreta**
   - ✅ Correto: `https://music.exemplo.com`
   - ❌ Errado: `music.exemplo.com` (falta http/https)
   - ❌ Errado: `https://music.exemplo.com/` (barra no final)

2. **Servidor não acessível**
   - Teste no navegador do smartphone
   - Verifique se está na mesma rede Wi-Fi
   - Confirme que o servidor está rodando

3. **Credenciais incorretas**
   - Verifique usuário e senha
   - Teste fazendo login no navegador

4. **Smartwatch sem Wi-Fi**
   - Vá em Configurações → Wi-Fi
   - Conecte a uma rede
   - Tente novamente

### "Not Configured"

**Solução:**
- Configure através do Garmin Connect Mobile (passo 2)
- Reinicie o app YuMusic
- Sincronize o smartwatch com o smartphone

### Música não carrega

**Soluções:**
1. Verifique conexão Wi-Fi do smartwatch
2. Teste com "Random Songs" primeiro
3. Confirme que há músicas no servidor
4. Reinicie o app

### App não aparece no smartwatch

**Soluções:**
1. Force sincronização no Garmin Connect Mobile
2. Reinicie o smartwatch
3. Reinstale o app
4. Verifique se o smartwatch é compatível

## 📱 Configuração do Servidor Navidrome

Se você ainda não tem um servidor Navidrome:

### Opção 1: Docker (Recomendado)

```bash
docker run -d \
  --name navidrome \
  -p 4533:4533 \
  -v /path/to/music:/music \
  -v /path/to/data:/data \
  deluan/navidrome:latest
```

### Opção 2: Instalação Manual

Veja: https://www.navidrome.org/docs/installation/

### Configuração Importante

No arquivo `navidrome.toml`:

```toml
# Permitir acesso externo
Address = "0.0.0.0"
Port = 4533

# Habilitar HTTPS (recomendado)
# Use um reverse proxy como Nginx ou Caddy
```

## 🌐 Acesso Externo

Para acessar seu servidor fora de casa:

### Opção 1: Cloudflare Tunnel (Grátis)
- Seguro e fácil
- Não precisa abrir portas
- Tutorial: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/

### Opção 2: VPN
- Use Tailscale ou WireGuard
- Acesso seguro à rede doméstica

### Opção 3: Port Forwarding
- Configure no roteador
- ⚠️ Use HTTPS obrigatoriamente
- Não recomendado para iniciantes

## ✅ Checklist de Configuração

- [ ] Servidor Navidrome/Subsonic rodando
- [ ] Servidor acessível pela rede
- [ ] URL do servidor anotada (com http/https)
- [ ] Usuário e senha criados no servidor
- [ ] App YuMusic instalado no smartwatch
- [ ] Smartwatch conectado ao Wi-Fi
- [ ] Configurações salvas no Garmin Connect Mobile
- [ ] Conexão testada com sucesso
- [ ] Primeira música reproduzida

## 🎯 Dicas de Uso

1. **Primeira vez**: Use "Random Songs" para testar
2. **Playlists**: Crie playlists no servidor para acesso rápido
3. **Wi-Fi**: Conecte o smartwatch ao Wi-Fi antes de sair de casa
4. **Bateria**: Streaming consome bateria, carregue antes de atividades longas
5. **Offline**: Funcionalidade de download em desenvolvimento

## 📞 Precisa de Ajuda?

1. Consulte o [README.md](README.md) completo
2. Verifique os logs do servidor Navidrome
3. Teste a conexão no navegador primeiro
4. Abra uma issue no GitHub com detalhes do problema

---

**Pronto! Agora você pode ouvir suas músicas favoritas no seu Garmin! 🎉**
