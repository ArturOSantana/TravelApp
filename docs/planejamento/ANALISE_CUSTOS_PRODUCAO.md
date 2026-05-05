# Análise de Custos para Lançamento em Produção - Travel App

## Cenários de Uso e Custos Estimados

**Data da Análise:** Maio 2026  
**Cotação do Dólar:** R$ 5,00 (estimativa conservadora)  
**Período de Análise:** 12 meses

---

## Cenário 1: Lançamento Inicial (0-1.000 usuários ativos)

### Firebase (Backend)

| Serviço | Limite Gratuito | Custo Adicional | Estimativa Mensal | Estimativa Anual |
|---------|----------------|-----------------|-------------------|------------------|
| **Cloud Firestore** | 50k leituras/dia<br>20k escritas/dia<br>1 GB armazenamento | $0.06 por 100k leituras<br>$0.18 por 100k escritas<br>$0.18/GB/mês | R$ 0,00 | R$ 0,00 |
| **Authentication** | Ilimitado gratuito | Gratuito | R$ 0,00 | R$ 0,00 |
| **Storage** | 5 GB armazenamento<br>1 GB download/dia | $0.026/GB armazenamento<br>$0.12/GB download | R$ 0,00 | R$ 0,00 |
| **Cloud Messaging** | Ilimitado gratuito | Gratuito | R$ 0,00 | R$ 0,00 |
| **Hosting** | 10 GB armazenamento<br>360 MB/dia | $0.026/GB armazenamento<br>$0.15/GB transferência | R$ 0,00 | R$ 0,00 |
| **TOTAL FIREBASE** | - | - | **R$ 0,00** | **R$ 0,00** |

### APIs Externas (Gratuitas)

| API | Limite Gratuito | Custo Adicional | Estimativa Mensal | Estimativa Anual |
|-----|----------------|-----------------|-------------------|------------------|
| **Geoapify** | 3.000 req/dia | $1/1.000 req extras | R$ 0,00 | R$ 0,00 |
| **OpenWeatherMap** | 1.000 req/dia | $0.0015/req extra | R$ 0,00 | R$ 0,00 |
| **REST Countries** | Ilimitado | Gratuito | R$ 0,00 | R$ 0,00 |
| **ExchangeRate** | 1.500 req/mês | $10/mês (plano básico) | R$ 0,00 | R$ 0,00 |
| **Nominatim** | 1 req/segundo | Gratuito | R$ 0,00 | R$ 0,00 |
| **TOTAL APIs** | - | - | **R$ 0,00** | **R$ 0,00** |

### Lojas de Aplicativos

| Serviço | Custo Único | Custo Anual | Observações |
|---------|-------------|-------------|-------------|
| **Google Play Store** | $25 (R$ 125) | - | Pagamento único vitalício |
| **Apple App Store** | $99/ano (R$ 495) | R$ 495,00 | Renovação anual obrigatória |
| **TOTAL LOJAS** | **R$ 125,00** | **R$ 495,00** | - |

### **TOTAL CENÁRIO 1**
- **Custo Inicial:** R$ 125,00 (Google Play)
- **Custo Mensal:** R$ 0,00
- **Custo Anual:** R$ 495,00 (apenas Apple App Store)

---

## Cenário 2: Crescimento Moderado (1.000-10.000 usuários ativos)

### Firebase (Backend)

| Serviço | Uso Estimado | Custo Mensal (USD) | Custo Mensal (BRL) | Custo Anual (BRL) |
|---------|--------------|-------------------|-------------------|-------------------|
| **Cloud Firestore** | 5M leituras/dia<br>1M escritas/dia<br>10 GB armazenamento | $18 + $54 + $1.80 = $73.80 | R$ 369,00 | R$ 4.428,00 |
| **Authentication** | Ilimitado | $0 | R$ 0,00 | R$ 0,00 |
| **Storage** | 50 GB armazenamento<br>100 GB download/mês | $1.30 + $12 = $13.30 | R$ 66,50 | R$ 798,00 |
| **Cloud Messaging** | Ilimitado | $0 | R$ 0,00 | R$ 0,00 |
| **Hosting** | 50 GB armazenamento<br>500 GB transferência | $1.30 + $75 = $76.30 | R$ 381,50 | R$ 4.578,00 |
| **TOTAL FIREBASE** | - | **$163.40** | **R$ 817,00** | **R$ 9.804,00** |

### APIs Externas

| API | Uso Estimado | Custo Mensal (USD) | Custo Mensal (BRL) | Custo Anual (BRL) |
|-----|--------------|-------------------|-------------------|-------------------|
| **Geoapify** | 150k req/dia (excede gratuito) | $50 (plano pago) | R$ 250,00 | R$ 3.000,00 |
| **OpenWeatherMap** | 50k req/dia (excede gratuito) | $40 (plano pago) | R$ 200,00 | R$ 2.400,00 |
| **REST Countries** | Ilimitado | $0 | R$ 0,00 | R$ 0,00 |
| **ExchangeRate** | 50k req/mês | $10 | R$ 50,00 | R$ 600,00 |
| **Nominatim** | Dentro do limite | $0 | R$ 0,00 | R$ 0,00 |
| **TOTAL APIs** | - | **$100** | **R$ 500,00** | **R$ 6.000,00** |

### Lojas de Aplicativos

| Serviço | Custo Anual |
|---------|-------------|
| **Apple App Store** | R$ 495,00 |

### **TOTAL CENÁRIO 2**
- **Custo Mensal:** R$ 1.317,00
- **Custo Anual:** R$ 16.299,00

---

## Cenário 3: Escala Comercial (10.000-50.000 usuários ativos)

### Firebase (Backend)

| Serviço | Uso Estimado | Custo Mensal (USD) | Custo Mensal (BRL) | Custo Anual (BRL) |
|---------|--------------|-------------------|-------------------|-------------------|
| **Cloud Firestore** | 25M leituras/dia<br>5M escritas/dia<br>100 GB armazenamento | $90 + $270 + $18 = $378 | R$ 1.890,00 | R$ 22.680,00 |
| **Authentication** | Ilimitado | $0 | R$ 0,00 | R$ 0,00 |
| **Storage** | 500 GB armazenamento<br>1 TB download/mês | $13 + $120 = $133 | R$ 665,00 | R$ 7.980,00 |
| **Cloud Messaging** | Ilimitado | $0 | R$ 0,00 | R$ 0,00 |
| **Hosting** | 100 GB armazenamento<br>2 TB transferência | $2.60 + $300 = $302.60 | R$ 1.513,00 | R$ 18.156,00 |
| **TOTAL FIREBASE** | - | **$813.60** | **R$ 4.068,00** | **R$ 48.816,00** |

### APIs Externas

| API | Uso Estimado | Custo Mensal (USD) | Custo Mensal (BRL) | Custo Anual (BRL) |
|-----|--------------|-------------------|-------------------|-------------------|
| **Geoapify** | 500k req/dia | $200 (plano enterprise) | R$ 1.000,00 | R$ 12.000,00 |
| **OpenWeatherMap** | 200k req/dia | $180 (plano professional) | R$ 900,00 | R$ 10.800,00 |
| **REST Countries** | Ilimitado | $0 | R$ 0,00 | R$ 0,00 |
| **ExchangeRate** | 200k req/mês | $50 | R$ 250,00 | R$ 3.000,00 |
| **Nominatim** | Considerar servidor próprio | $50 (VPS) | R$ 250,00 | R$ 3.000,00 |
| **TOTAL APIs** | - | **$480** | **R$ 2.400,00** | **R$ 28.800,00** |

### Lojas de Aplicativos

| Serviço | Custo Anual |
|---------|-------------|
| **Apple App Store** | R$ 495,00 |

### **TOTAL CENÁRIO 3**
- **Custo Mensal:** R$ 6.468,00
- **Custo Anual:** R$ 78.111,00

---

## Alternativa: Google Maps Platform (Comparação)

### Cenário 2 com Google Maps

| Serviço Google | Uso Estimado | Custo Mensal (USD) | Custo Mensal (BRL) | Custo Anual (BRL) |
|----------------|--------------|-------------------|-------------------|-------------------|
| **Places API** | 50k req/mês | $350 ($7/1k req) | R$ 1.750,00 | R$ 21.000,00 |
| **Geocoding API** | 30k req/mês | $150 ($5/1k req) | R$ 750,00 | R$ 9.000,00 |
| **Directions API** | 20k req/mês | $140 ($7/1k req) | R$ 700,00 | R$ 8.400,00 |
| **Maps SDK** | Incluído | $0 (até 100k loads) | R$ 0,00 | R$ 0,00 |
| **TOTAL Google Maps** | - | **$640** | **R$ 3.200,00** | **R$ 38.400,00** |

**Comparação Cenário 2:**
- **Com APIs Gratuitas:** R$ 500,00/mês
- **Com Google Maps:** R$ 3.200,00/mês
- **Diferença:** R$ 2.700,00/mês (R$ 32.400,00/ano)

**Conclusão:** APIs gratuitas são **6,4x mais baratas** que Google Maps

---

## Resumo Comparativo - Tabela Consolidada

| Cenário | Usuários Ativos | Custo Mensal | Custo Anual | Custo por Usuário/Mês |
|---------|----------------|--------------|-------------|----------------------|
| **Cenário 1: MVP** | 0-1.000 | R$ 0,00 | R$ 495,00 | R$ 0,00 |
| **Cenário 2: Crescimento** | 1.000-10.000 | R$ 1.317,00 | R$ 16.299,00 | R$ 0,13 |
| **Cenário 3: Escala** | 10.000-50.000 | R$ 6.468,00 | R$ 78.111,00 | R$ 0,21 |
| **Cenário 2 + Google Maps** | 1.000-10.000 | R$ 4.017,00 | R$ 48.699,00 | R$ 0,40 |

---

## Custos Adicionais Recomendados

### Infraestrutura Complementar

| Item | Custo Mensal (BRL) | Custo Anual (BRL) | Observações |
|------|-------------------|-------------------|-------------|
| **Domínio (.com.br)** | R$ 3,33 | R$ 40,00 | Registro.br |
| **Email Profissional** | R$ 25,00 | R$ 300,00 | Google Workspace |
| **Monitoramento (Sentry)** | R$ 130,00 | R$ 1.560,00 | Plano Team |
| **Analytics (Mixpanel)** | R$ 0,00 | R$ 0,00 | Plano gratuito até 100k usuários |
| **CDN (Cloudflare)** | R$ 0,00 | R$ 0,00 | Plano gratuito |
| **TOTAL COMPLEMENTAR** | **R$ 158,33** | **R$ 1.900,00** | - |

### Custos de Marketing (Opcional)

| Item | Custo Mensal (BRL) | Custo Anual (BRL) |
|------|-------------------|-------------------|
| **Google Ads** | R$ 500,00 - R$ 2.000,00 | R$ 6.000,00 - R$ 24.000,00 |
| **Facebook/Instagram Ads** | R$ 300,00 - R$ 1.500,00 | R$ 3.600,00 - R$ 18.000,00 |
| **Influenciadores** | R$ 1.000,00 - R$ 5.000,00 | R$ 12.000,00 - R$ 60.000,00 |

---

## Recomendações Estratégicas

### Fase 1: Lançamento (Meses 1-6)
**Objetivo:** 0-1.000 usuários  
**Custo Estimado:** R$ 495,00/ano + R$ 1.900,00 (infraestrutura) = **R$ 2.395,00/ano**  
**Estratégia:** Usar apenas planos gratuitos, focar em crescimento orgânico

### Fase 2: Crescimento (Meses 7-18)
**Objetivo:** 1.000-10.000 usuários  
**Custo Estimado:** R$ 16.299,00 + R$ 1.900,00 = **R$ 18.199,00/ano**  
**Estratégia:** Investir em marketing digital, manter APIs gratuitas

### Fase 3: Escala (Meses 19+)
**Objetivo:** 10.000-50.000 usuários  
**Custo Estimado:** R$ 78.111,00 + R$ 1.900,00 = **R$ 80.011,00/ano**  
**Estratégia:** Considerar migração para Google Maps se necessário, buscar investimento

---

## Modelo de Receita Sugerido

### Plano Freemium

| Plano | Preço Mensal | Recursos | Conversão Esperada |
|-------|--------------|----------|-------------------|
| **Gratuito** | R$ 0,00 | Viagens ilimitadas, 5 membros/grupo | 90% dos usuários |
| **Premium** | R$ 19,90 | 20 membros/grupo, relatórios avançados, sem anúncios | 8% dos usuários |
| **Business** | R$ 49,90 | Grupos ilimitados, API access, suporte prioritário | 2% dos usuários |

### Projeção de Receita (Cenário 2: 10.000 usuários)

| Plano | Usuários | Receita Mensal | Receita Anual |
|-------|----------|----------------|---------------|
| **Gratuito** | 9.000 | R$ 0,00 | R$ 0,00 |
| **Premium** | 800 | R$ 15.920,00 | R$ 191.040,00 |
| **Business** | 200 | R$ 9.980,00 | R$ 119.760,00 |
| **TOTAL** | 10.000 | **R$ 25.900,00** | **R$ 310.800,00** |

**Lucro Líquido Estimado (Cenário 2):**
- Receita Anual: R$ 310.800,00
- Custos Operacionais: R$ 18.199,00
- **Lucro:** R$ 292.601,00/ano (margem de 94%)

---

## Conclusões

### Vantagens das APIs Gratuitas
1. **Custo Zero** nos primeiros 1.000 usuários
2. **6,4x mais barato** que Google Maps em escala
3. **Escalabilidade gradual** - paga conforme cresce
4. **Viabilidade financeira** para projeto acadêmico

### Quando Considerar Google Maps
- Acima de 50.000 usuários ativos
- Necessidade de recursos avançados (Street View, rotas complexas)
- Orçamento de marketing robusto
- Investimento externo garantido

### Recomendação Final
**Manter APIs gratuitas** (Geoapify, OpenWeatherMap, etc.) até atingir 50.000 usuários ativos. Nesse ponto, avaliar migração para Google Maps baseado em:
- Receita recorrente consolidada
- Feedback dos usuários sobre funcionalidades
- Necessidade de recursos avançados
- Disponibilidade de capital

---

**Preparado por:** Equipe Travel App  
**Data:** Maio 2026  
**Próxima Revisão:** Após 6 meses de operação