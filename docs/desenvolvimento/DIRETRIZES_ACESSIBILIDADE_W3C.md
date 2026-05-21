# Diretrizes de Acessibilidade W3C/WCAG 2.1

## Princípios POUR

### 1. Perceptível
Informações e componentes da interface devem ser apresentados de forma que os usuários possam percebê-los.

#### 1.1 Alternativas em Texto
- **Regra:** Todo conteúdo não textual deve ter alternativa em texto
- **Implementação Flutter:**
  - Usar `Semantics` widget com `label` descritivo
  - Propriedade `semanticsLabel` em Images
  - Evitar ícones sem texto alternativo

#### 1.2 Mídias Temporais
- Fornecer legendas e descrições de áudio

#### 1.3 Adaptável
- **Regra:** Conteúdo deve ser apresentado de diferentes formas sem perder informação
- **Implementação Flutter:**
  - Usar `MediaQuery` para layouts responsivos
  - Suportar orientação portrait e landscape
  - Texto escalável com `textScaleFactor`

#### 1.4 Distinguível
- **Contraste mínimo:** 4.5:1 para texto normal, 3:1 para texto grande
- **Redimensionamento:** Texto até 200% sem perda de funcionalidade
- **Implementação Flutter:**
  - Cores com contraste adequado no tema
  - Usar `Theme.of(context).textTheme` para escalabilidade

### 2. Operável
Componentes da interface e navegação devem ser operáveis.

#### 2.1 Acessível por Teclado
- **Regra:** Toda funcionalidade disponível via teclado
- **Implementação Flutter:**
  - `FocusNode` para navegação por teclado
  - `Shortcuts` e `Actions` para atalhos
  - Ordem de foco lógica com `FocusTraversalGroup`

#### 2.2 Tempo Suficiente
- Usuários devem ter tempo suficiente para ler e usar o conteúdo
- Evitar timeouts automáticos ou permitir extensão

#### 2.3 Convulsões
- Não usar conteúdo que pisca mais de 3 vezes por segundo

#### 2.4 Navegável
- **Regra:** Formas de ajudar usuários a navegar e encontrar conteúdo
- **Implementação Flutter:**
  - Títulos de página descritivos (`AppBar.title`)
  - Ordem de foco lógica
  - Links com propósito claro
  - Breadcrumbs quando apropriado

### 3. Compreensível
Informações e operação da interface devem ser compreensíveis.

#### 3.1 Legível
- **Regra:** Texto legível e compreensível
- **Implementação Flutter:**
  - Linguagem clara e simples
  - Definir idioma com `Localizations`
  - Explicar termos técnicos

#### 3.2 Previsível
- **Regra:** Páginas devem aparecer e operar de forma previsível
- **Implementação Flutter:**
  - Navegação consistente
  - Identificação consistente de componentes
  - Mudanças de contexto apenas quando esperado

#### 3.3 Assistência de Entrada
- **Regra:** Ajudar usuários a evitar e corrigir erros
- **Implementação Flutter:**
  - Validação de formulários com mensagens claras
  - Labels descritivos em campos
  - Sugestões de correção em erros
  - Confirmação antes de ações destrutivas

### 4. Robusto
Conteúdo deve ser robusto o suficiente para ser interpretado por diversos agentes.

#### 4.1 Compatível
- **Regra:** Maximizar compatibilidade com tecnologias assistivas
- **Implementação Flutter:**
  - Usar widgets nativos quando possível
  - `Semantics` para widgets customizados
  - Testar com TalkBack (Android) e VoiceOver (iOS)

## Checklist de Implementação

### Componentes de UI

#### Botões
```dart
// ❌ Ruim - sem semântica
IconButton(
  icon: Icon(Icons.delete),
  onPressed: () {},
)

// ✅ Bom - com semântica clara
IconButton(
  icon: Icon(Icons.delete),
  tooltip: 'Excluir item',
  onPressed: () {},
)

// ✅ Melhor - semântica explícita
Semantics(
  label: 'Excluir viagem para Paris',
  button: true,
  child: IconButton(
    icon: Icon(Icons.delete),
    tooltip: 'Excluir',
    onPressed: () {},
  ),
)
```

#### Imagens
```dart
// ❌ Ruim
Image.network(url)

// ✅ Bom
Image.network(
  url,
  semanticLabel: 'Foto da Torre Eiffel em Paris',
  errorBuilder: (context, error, stackTrace) {
    return Text('Erro ao carregar imagem');
  },
)
```

#### Formulários
```dart
// ✅ Bom
TextFormField(
  decoration: InputDecoration(
    labelText: 'Email',
    hintText: 'exemplo@email.com',
    helperText: 'Usaremos para recuperação de senha',
    errorText: emailError,
  ),
  keyboardType: TextInputType.emailAddress,
  textInputAction: TextInputAction.next,
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, insira seu email';
    }
    if (!value.contains('@')) {
      return 'Email inválido. Deve conter @';
    }
    return null;
  },
)
```

#### Navegação
```dart
// ✅ Bom - AppBar com título claro
AppBar(
  title: Text('Minhas Viagens'),
  leading: IconButton(
    icon: Icon(Icons.arrow_back),
    tooltip: 'Voltar',
    onPressed: () => Navigator.pop(context),
  ),
)
```

### Contraste de Cores

#### Verificação
- Usar ferramentas como [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)
- Texto normal: mínimo 4.5:1
- Texto grande (18pt+): mínimo 3:1
- Componentes UI: mínimo 3:1

#### Implementação
```dart
// Definir cores com contraste adequado
static const Color primaryText = Color(0xFF212121); // #212121
static const Color background = Color(0xFFFFFFFF); // #FFFFFF
// Contraste: 16.1:1 ✅

static const Color secondaryText = Color(0xFF757575); // #757575
static const Color background = Color(0xFFFFFFFF); // #FFFFFF
// Contraste: 4.6:1 ✅
```

### Tamanho de Toque

- **Mínimo:** 44x44 pixels (iOS) ou 48x48 dp (Android)
- **Espaçamento:** 8dp entre elementos tocáveis

```dart
// ✅ Bom
SizedBox(
  width: 48,
  height: 48,
  child: IconButton(
    icon: Icon(Icons.favorite),
    onPressed: () {},
  ),
)
```

### Feedback Visual e Sonoro

```dart
// ✅ Bom - feedback ao usuário
ElevatedButton(
  onPressed: () async {
    // Feedback visual
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Salvando...')),
    );
    
    await salvar();
    
    // Feedback de sucesso
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Salvo com sucesso!'),
        backgroundColor: Colors.green,
      ),
    );
    
    // Feedback sonoro (opcional)
    SystemSound.play(SystemSoundType.click);
  },
  child: Text('Salvar'),
)
```

## Testes de Acessibilidade

### Ferramentas
1. **Flutter DevTools** - Inspetor de semântica
2. **TalkBack** (Android) - Leitor de tela
3. **VoiceOver** (iOS) - Leitor de tela
4. **Accessibility Scanner** (Android)

### Checklist de Testes
- [ ] Navegar pelo app apenas com teclado
- [ ] Testar com TalkBack/VoiceOver ativado
- [ ] Verificar contraste de cores
- [ ] Testar com `textScaleFactor` aumentado
- [ ] Verificar ordem de foco
- [ ] Testar em modo escuro
- [ ] Verificar mensagens de erro

## Referências

- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [Flutter Accessibility](https://docs.flutter.dev/development/accessibility-and-localization/accessibility)
- [Material Design Accessibility](https://material.io/design/usability/accessibility.html)