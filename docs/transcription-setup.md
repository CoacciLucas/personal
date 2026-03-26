# Configuração de Transcrição (Speech-to-Text)

O Perssua suporta múltiplos backends de transcrição. Aqui está um comparativo:

## Comparativo de Opções

| Backend | Custo | Offline | Qualidade | Latência | Configuração |
|---------|-------|---------|-----------|----------|--------------|
| **Whisper Local** | ✅ Grátis | ✅ Sim | ⭐⭐⭐⭐⭐ | ~1-3s | Moderada |
| **Vosk** | ✅ Grátis | ✅ Sim | ⭐⭐⭐ | ~0.5s | Fácil |
| **Azure Speech** | 5h/mês grátis | ❌ Não | ⭐⭐⭐⭐⭐ | ~300ms | Fácil |
| **OpenAI Whisper** | $0.006/min | ❌ Não | ⭐⭐⭐⭐⭐ | ~2s | Fácil |

---

## 1. Whisper Local (Recomendado) 🏆

**Melhor opção gratuita com excelente qualidade.**

### Pré-requisitos

1. **Baixar whisper.cpp**
   - Releases: https://github.com/ggerganov/whisper.cpp/releases
   - Baixe `whisper-xxx-bin-x64.zip`
   - Extraia para: `%LOCALAPPDATA%\Perssua\whisper\`

2. **Baixar modelo**
   - Modelos: https://huggingface.co/ggerganov/whisper.cpp/tree/main
   - Recomendado: `ggml-base.bin` (142MB) ou `ggml-small.bin` (466MB)
   - Coloque em: `%LOCALAPPDATA%\Perssua\whisper\models\`

### Estrutura de Pastas

```
%LOCALAPPDATA%\Perssua\whisper\
├── main.exe              # whisper.cpp executable
├── ggml-base.bin         # Model (or ggml-small.bin, etc.)
└── models\
    ├── ggml-tiny.bin
    ├── ggml-base.bin     # Recommended
    ├── ggml-small.bin
    └── ggml-medium.bin
```

### Modelos Disponíveis

| Modelo | Tamanho | RAM | Velocidade | Qualidade |
|--------|---------|-----|------------|-----------|
| tiny | 75 MB | ~390 MB | Muito rápido | Baixa |
| base | 142 MB | ~500 MB | Rápido | Boa |
| small | 466 MB | ~1.0 GB | Médio | Muito boa |
| medium | 1.5 GB | ~2.6 GB | Lento | Excelente |
| large-v3 | 2.9 GB | ~4.7 GB | Muito lento | Melhor |

---

## 2. Azure Speech Services

**Serviço em nuvem da Microsoft com tier gratuito.**

### Configuração

1. Criar recurso no Azure Portal:
   - https://portal.azure.com/#create/Microsoft.CognitiveServicesSpeechServices

2. Obter credenciais:
   - Subscription Key
   - Region (ex: eastus, westus2, brazilsouth)

### Limites do Tier Gratuito

- **5 horas/mês** grátis
- Depois: **$1.00/hora**

---

## 3. OpenAI Whisper API

**API oficial do Whisper, pago mas com excelente qualidade.**

### Configuração

1. Criar conta: https://platform.openai.com/
2. Gerar API Key: https://platform.openai.com/api-keys

### Custos

- **$0.006 por minuto** de áudio
- ~$0.36 por hora

---

## 4. Vosk (Alternativa Gratuita)

**Open source, totalmente gratuito, qualidade inferior ao Whisper.**

### Configuração

1. Baixar modelo: https://alphacephei.com/vosk/models
   - Recomendado: `vosk-model-small-en-us-0.15` (inglês) ou `vosk-model-small-pt-0.3` (português)

2. Extrair para: `%LOCALAPPDATA%\Perssua\vosk\model\`

### Modelos Disponíveis

- `vosk-model-small-en-us-0.15` - Inglês, 40MB
- `vosk-model-small-pt-0.3` - Português, 50MB
- `vosk-model-en-us-0.22` - Inglês, 1.8GB (melhor qualidade)
- `vosk-model-pt-0.3` - Português, 1.4GB

---

## Recomendação

Para a maioria dos usuários:

1. **Whisper Local** com modelo `base` ou `small`
   - Gratuito, offline, excelente qualidade
   - Funciona sem internet
   - Privacidade total (áudio não sai do PC)

2. **Azure Speech** como backup
   - Use quando precisar de latência muito baixa
   - Tier gratuito de 5h/mês é suficiente para uso moderado
