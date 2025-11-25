# 🌐 Deploy Web - Gerenciamento de Gado

## 📦 Build de Produção

O build Web está em: `build/web/`

### Comandos de Build

```bash
# Build de produção otimizado
flutter build web --release

# Build com CanvasKit (melhor performance, maior tamanho)
flutter build web --release --web-renderer canvaskit

# Build com HTML (menor tamanho, compatibilidade ampla)
flutter build web --release --web-renderer html
```

## 🚀 Opções de Deploy

### 1. **GitHub Pages** (Grátis)

```bash
# Instalar gh-pages (se ainda não tiver)
# npm install -g gh-pages

# Deploy
cd build/web
git init
git add .
git commit -m "Deploy Web App"
git branch -M gh-pages
git remote add origin https://github.com/gustavorodrigues45/FlutterProject.git
git push -f origin gh-pages
```

Acesse em: `https://gustavorodrigues45.github.io/FlutterProject/`

**Configuração adicional:**
- Vá em Settings → Pages → Source: gh-pages branch

### 2. **Firebase Hosting** (Grátis)

```bash
# Instalar Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Inicializar projeto
firebase init hosting

# Quando perguntar "public directory", digite: build/web
# Quando perguntar "single-page app", responda: Yes

# Deploy
firebase deploy --only hosting
```

### 3. **Vercel** (Grátis)

```bash
# Instalar Vercel CLI
npm install -g vercel

# Deploy
cd build/web
vercel
```

### 4. **Netlify** (Grátis)

- Arraste a pasta `build/web` para https://app.netlify.com/drop
- Ou use CLI:

```bash
# Instalar Netlify CLI
npm install -g netlify-cli

# Deploy
cd build/web
netlify deploy --prod
```

### 5. **Servidor Local/Apache/Nginx**

Copie a pasta `build/web` para o diretório público do servidor:

```bash
# Exemplo Apache (Linux)
cp -r build/web/* /var/www/html/gado/

# Exemplo Nginx
cp -r build/web/* /usr/share/nginx/html/gado/
```

**Configuração Nginx** (`/etc/nginx/sites-available/default`):
```nginx
location /gado/ {
    alias /usr/share/nginx/html/gado/;
    try_files $uri $uri/ /gado/index.html;
}
```

**Configuração Apache** (`.htaccess` na pasta):
```apache
<IfModule mod_rewrite.c>
  RewriteEngine On
  RewriteBase /gado/
  RewriteCond %{REQUEST_FILENAME} !-f
  RewriteCond %{REQUEST_FILENAME} !-d
  RewriteRule ^(.*)$ index.html [QSA,L]
</IfModule>
```

## 🔧 Configurações Importantes

### Base URL (para subpastas)

Se hospedar em `seusite.com/gado/`, edite `web/index.html`:

```html
<base href="/gado/">
```

### PWA (Progressive Web App)

O app já está configurado como PWA! Arquivos importantes:
- `web/manifest.json` - Configurações do app
- `web/icons/` - Ícones para telas iniciais

### SQLite no Web

⚠️ **Importante:** SQLite não funciona nativamente no Web. O banco usa IndexedDB automaticamente através do `sqflite_common_ffi_web`.

Se houver problemas, adicione em `pubspec.yaml`:
```yaml
dependencies:
  sqflite_common_ffi_web: ^0.4.0
```

## 📊 Performance

### Tamanhos Típicos
- **HTML renderer**: ~2-3 MB
- **CanvasKit renderer**: ~5-7 MB (melhor qualidade gráfica)

### Otimizações
```bash
# Minificar assets
flutter build web --release --tree-shake-icons

# Analisar tamanho do bundle
flutter build web --release --analyze-size
```

## 🔐 Segurança

### HTTPS
- Sempre use HTTPS em produção
- GitHub Pages, Firebase, Vercel e Netlify fornecem HTTPS automático

### CORS
Se usar APIs externas, configure CORS no servidor backend.

## 🧪 Testar Localmente

```bash
# Servir build de produção localmente
cd build/web
python -m http.server 8000
# Acesse: http://localhost:8000

# Ou com Node.js
npx serve -s build/web -p 8000
```

## 📝 Credenciais Padrão

- **Email:** `admin@gado.com`
- **Senha:** `admin123`

## ✅ Checklist de Deploy

- [ ] `flutter build web --release` executado sem erros
- [ ] Testar build local em `build/web/index.html`
- [ ] Verificar `<base href="/">` em `web/index.html`
- [ ] Configurar domínio/SSL (se necessário)
- [ ] Upload dos arquivos para servidor
- [ ] Testar em diferentes navegadores (Chrome, Firefox, Safari, Edge)
- [ ] Verificar console do navegador (F12) para erros
- [ ] Testar funcionalidades: Login, Cadastro, Fotos, Banco de Dados

## 🐛 Troubleshooting

### Tela em branco
1. Abra DevTools (F12) → Console
2. Verifique erros de carregamento
3. Confirme que `<base href="/">` está correto
4. Limpe cache (Ctrl+Shift+Delete)

### Erros de importação
- Verifique se todos os pacotes são compatíveis com Web
- Plugins nativos (`camera`, `notifications`) não funcionam no Web

### Performance ruim
- Use `--web-renderer html` para dispositivos mais antigos
- Habilite compressão gzip no servidor
- Use CDN para assets estáticos

## 🔗 Links Úteis

- [Flutter Web Docs](https://docs.flutter.dev/platform-integration/web)
- [Deploy no Firebase](https://firebase.google.com/docs/hosting)
- [Deploy no GitHub Pages](https://docs.github.com/pages)
- [Deploy no Vercel](https://vercel.com/docs)
- [Deploy no Netlify](https://docs.netlify.com/)
