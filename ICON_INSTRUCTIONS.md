# Instruções para Criar o Ícone do Launcher

O arquivo `launcher_icon.png` precisa ser criado manualmente com as seguintes especificações:

## Especificações do Ícone

- **Tamanho**: 70x70 pixels (para Venu 2)
- **Formato**: PNG com transparência
- **Fundo**: Transparente ou colorido (recomendado: fundo colorido)
- **Design**: Ícone de música (nota musical, fones de ouvido, etc.)

## Como Criar

### Opção 1: Usando um Editor de Imagens

1. Abra um editor de imagens (Photoshop, GIMP, Figma, etc.)
2. Crie uma nova imagem de 70x70 pixels
3. Desenhe ou importe um ícone de música
4. Salve como PNG em: `resources/drawables/launcher_icon.png`

### Opção 2: Usando um Gerador Online

1. Acesse: https://www.favicon-generator.org/ ou similar
2. Faça upload de uma imagem de música
3. Gere um ícone de 70x70 pixels
4. Baixe e salve em: `resources/drawables/launcher_icon.png`

### Opção 3: Usando Emoji/Ícone Simples

1. Use um editor simples como Paint.NET ou GIMP
2. Crie um canvas de 70x70 pixels
3. Adicione um fundo colorido (ex: azul #1E88E5)
4. Adicione um emoji de música 🎵 ou símbolo ♪
5. Salve como PNG

## Sugestões de Design

- **Cores**: Azul (#1E88E5), Verde (#4CAF50), Roxo (#9C27B0)
- **Símbolos**: 🎵 🎶 🎧 ♪ ♫
- **Estilo**: Flat design, minimalista
- **Contraste**: Certifique-se de que o ícone seja visível em fundos claros e escuros

## Exemplo Rápido com ImageMagick

Se você tem ImageMagick instalado:

```bash
convert -size 70x70 xc:#1E88E5 \
  -gravity center \
  -pointsize 40 \
  -fill white \
  -annotate +0+0 "♪" \
  resources/drawables/launcher_icon.png
```

## Nota

Por enquanto, o arquivo PNG vazio foi criado. Você precisa substituí-lo por um ícone real de 70x70 pixels antes de compilar o aplicativo para produção.

Para desenvolvimento/teste, você pode usar o monkey.png existente temporariamente.
