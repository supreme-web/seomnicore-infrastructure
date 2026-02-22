# Arquitetura Oficial de Domínios – SEOmniCore

Documento técnico oficial que define a arquitetura de domínios, subdomínios e responsabilidades de cada ambiente no ecossistema SEOmniCore.

Última atualização: 2026-02-22


---

# 1. VISÃO GERAL DO ECOSSISTEMA

O ecossistema SEOmniCore é dividido em:

- MASTER (Governança)
- Regional (emcuritiba.dev.br)
- Global (x-index.com)

Cada domínio possui função estratégica específica.


---

# 2. REGIONAL – emcuritiba.dev.br

## 2.1 Domínio Editorial (Autoridade)

www.emcuritiba.dev.br  
→ Plataforma WordPress  
→ Função: Guestposts, conteúdo editorial, autoridade regional  
→ Linguagem: PHP  
→ Servidor: WordPress independente  

Observação:
O domínio raiz redireciona para www.


## 2.2 Motor Programático SEOmniCore Regional

*.emcuritiba.dev.br  
Exemplos:
- serralheria.emcuritiba.dev.br
- odontologia.emcuritiba.dev.br
- advocacia.emcuritiba.dev.br

→ Plataforma: Next.js
→ Gerenciado por PM2
→ Local VPS: /srv/apps/emcuritiba
→ Função: Motor SEO programático por nicho
→ Arquitetura: Subdomínios dinâmicos por categoria


Separação Estratégica:
WordPress = Autoridade  
Subdomínios = Performance programática e escala


---

# 3. GLOBAL – x-index.com

## 3.1 Domínio Principal

x-index.com  
→ Resolve para DEFAULT_COUNTRY (br)

www.x-index.com  
→ Alias principal


## 3.2 Subdomínios por País

Estrutura suportada atualmente:

- br.x-index.com
- us.x-index.com
- pt.x-index.com
- uk.x-index.com
- fr.x-index.com
- it.x-index.com
- es.x-index.com

→ Plataforma: Next.js
→ Gerenciado por PM2
→ Local VPS: /srv/apps/x-index
→ Middleware com:
   - Allowlist de hosts
   - Bloqueio de hosts inválidos (404)
   - Injeção de header x-country
   - Normalização de hostname


---

# 4. VPS – ESTRUTURA OFICIAL

Diretório base:

/srv/

Estrutura:

/srv/apps/emcuritiba
/srv/apps/x-index
/srv/infrastructure
/srv/logs
/srv/backups

Gerenciamento de processos:

PM2:
- emcuritiba
- x-index


---

# 5. REGRAS SUPREMAS DE PRODUÇÃO

1. Nunca alterar código diretamente na VPS sem versionar.
2. Toda alteração deve virar branch.
3. Toda branch deve virar Pull Request.
4. A branch main é a fonte oficial de produção.
5. VPS deve sempre rodar a main sincronizada com origin/main.
6. Backups devem ser criados antes de qualquer alteração estrutural.


---

# 6. FLUXO OFICIAL DE DEPLOY

PC Local → GitHub (PR) → Merge em main → VPS git pull → PM2 restart

Nunca fazer deploy manual sem Git.


---

# 7. GOVERNANÇA

Este documento faz parte do repositório:

SEOmniCore-MASTER

Local:
/home/alvaro/SEOmniCore-MASTER/docs/architecture/domains.md

Esse arquivo é a fonte oficial da arquitetura de domínios do sistema.
