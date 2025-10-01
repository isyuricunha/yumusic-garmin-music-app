# Contribuindo para YuMusic

Obrigado por considerar contribuir para o YuMusic! Este documento fornece diretrizes para contribuir com o projeto.

## 🚀 Como Contribuir

### Reportando Bugs

Se você encontrou um bug, por favor abra uma issue incluindo:

1. **Descrição clara** do problema
2. **Passos para reproduzir** o bug
3. **Comportamento esperado** vs **comportamento atual**
4. **Informações do dispositivo**:
   - Modelo do smartwatch Garmin
   - Versão do firmware
   - Versão do app YuMusic
5. **Servidor usado** (Navidrome, Subsonic, etc.)
6. **Logs** se disponíveis

### Sugerindo Melhorias

Para sugerir novas funcionalidades:

1. Verifique se já não existe uma issue similar
2. Descreva claramente a funcionalidade desejada
3. Explique por que seria útil
4. Se possível, sugira como implementar

### Pull Requests

1. **Fork** o repositório
2. Crie uma **branch** para sua feature (`git checkout -b feature/MinhaFeature`)
3. **Commit** suas mudanças (`git commit -m 'Adiciona MinhaFeature'`)
4. **Push** para a branch (`git push origin feature/MinhaFeature`)
5. Abra um **Pull Request**

## 💻 Configuração do Ambiente de Desenvolvimento

### Requisitos

- [Connect IQ SDK 8.3.0+](https://developer.garmin.com/connect-iq/sdk/)
- Visual Studio Code com extensão Monkey C
- Simulador Garmin Connect IQ

### Instalação

1. Clone o repositório:
   ```bash
   git clone https://github.com/seu-usuario/yumusic-garmin-music-app.git
   cd yumusic-garmin-music-app
   ```

2. Instale o Connect IQ SDK

3. Configure o SDK no VS Code

4. Abra o projeto no VS Code

### Compilação

```bash
monkeyc -o bin/yumusic.prg -f monkey.jungle -y developer_key.der
```

### Testando no Simulador

1. Abra o Connect IQ Simulator
2. Selecione o dispositivo (ex: Venu 2)
3. Carregue o arquivo `.prg` gerado
4. Configure as settings do app no simulador

## 📝 Padrões de Código

### Monkey C

- Use **4 espaços** para indentação
- Nomes de classes em **PascalCase**
- Nomes de funções e variáveis em **camelCase**
- Variáveis privadas começam com **underscore** (`_variavel`)
- Sempre adicione **comentários** explicativos
- Use **type hints** sempre que possível

### Exemplo:

```monkeyc
class MinhaClasse {
    private var _minhaVariavel as String;
    
    // Descrição da função
    function minhaFuncao(parametro as Number) as String {
        return parametro.toString();
    }
}
```

## 🏗️ Estrutura do Projeto

```
source/
├── yumusicApp.mc              # App principal
├── SubsonicAPI.mc             # Cliente API
├── SettingsManager.mc         # Configurações
├── MusicLibrary.mc            # Biblioteca
├── yumusicContentDelegate.mc  # Delegate de conteúdo
├── yumusicContentIterator.mc  # Iterator de reprodução
└── ...
```

## 🧪 Testes

Antes de submeter um PR:

1. Teste no simulador
2. Teste em dispositivo real se possível
3. Verifique diferentes cenários:
   - Servidor não disponível
   - Sem conexão Wi-Fi
   - Sem músicas
   - Playlists vazias

## 📚 Recursos Úteis

- [Connect IQ Documentation](https://developer.garmin.com/connect-iq/)
- [Subsonic API Documentation](http://www.subsonic.org/pages/api.jsp)
- [Navidrome Documentation](https://www.navidrome.org/docs/)

## 🎯 Áreas que Precisam de Ajuda

- [ ] Download de músicas para offline
- [ ] Busca de músicas
- [ ] Interface de navegação de artistas/álbuns
- [ ] Arte de álbum
- [ ] Testes automatizados
- [ ] Documentação
- [ ] Traduções

## 📄 Licença

Ao contribuir, você concorda que suas contribuições serão licenciadas sob a mesma licença do projeto.

## 💬 Comunicação

- **Issues**: Para bugs e features
- **Discussions**: Para perguntas e discussões gerais
- **Pull Requests**: Para contribuições de código

## 🙏 Agradecimentos

Obrigado por contribuir para tornar o YuMusic melhor!
