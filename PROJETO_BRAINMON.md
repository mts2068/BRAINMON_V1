# BRAINMON — Documento do projeto

> **Estado em 01/10/2026.** Este documento descreve (1) o que o jogo é, (2) tudo que já foi feito neste repositório, (3) como rodar e testar, (4) o que **não** foi verificado e (5) os próximos passos, em ordem.
>
> **Leia antes:** existem **dois projetos** BRAINMON no computador. Este repositório (`C:\Users\Matth\BRAINMON`) é o **projeto novo, com Rojo**, que começou do zero nesta etapa. O **projeto antigo** (`C:\Users\Matth\Downloads\BRAINMON`, place `BRAIMON.rbxl`) tem as fases F0.2–F0.5 prontas (captura, Braindex, loja, traps) mas o código vive só dentro do `.rbxl`. Esses sistemas ainda **não** foram trazidos para cá — ver [§8](#8-próximos-passos).
>
> Marcações usadas: **[feito]** implementado e conferido; **[escrito, não testado]** código escrito mas ainda não rodou no Studio; **[decisão minha]** escolha que fiz sem você ter definido (fácil de mudar, ver §6); **[pendente]** não feito.

---

## Sumário

1. [O jogo](#1-o-jogo)
2. [Linha do tempo e estado das fases](#2-linha-do-tempo-e-estado-das-fases)
3. [Estrutura do repositório](#3-estrutura-do-repositório)
4. [Pipeline de modelos 3D (Blender)](#4-pipeline-de-modelos-3d-blender)
5. [O mapa dos 8 mundos](#5-o-mapa-dos-8-mundos)
6. [Decisões tomadas e premissas](#6-decisões-tomadas-e-premissas)
7. [Como rodar, testar e calibrar](#7-como-rodar-testar-e-calibrar)
8. [Próximos passos](#8-próximos-passos)
9. [O que não foi verificado / limitações](#9-o-que-não-foi-verificado--limitações)
10. [Apêndice A — As 88 espécies](#apêndice-a--as-88-espécies)
11. [Apêndice B — Referência rápida de código](#apêndice-b--referência-rápida-de-código)

---

## 1. O jogo

**BRAINMON** é um jogo de Roblox de captura de "Brainmons" com estética *brainrot italiano*. Junta:

- **Steal a Brainrot** → coleção que gera renda passiva, loja com tiers exponenciais, bases e roubo entre jogadores.
- **Pokémon** → criaturas selvagens em biomas, captura, pokédex, nível/XP por criatura, time e batalha.

### Loop principal

1. Brainmons **selvagens** aparecem no mundo atual, na **raridade nativa** daquele mundo.
2. O jogador usa uma **trap** (aparelho CUBE) → **minigame dos anéis** de captura.
3. Sucesso → o bicho vira um **indivíduo** no **Braindex** (`Species`, `Shyne`, `Level`, `Xp`, `Biome`, `InSquad`).
4. O **squad** (`InSquad`) gera **BrainCoins (BC)** por segundo.
5. BC compra traps/upgrades na loja (`ShopService` = única autoridade de preço).
6. **Gate do próximo mundo:** espécies pedidas + BC → o jogador viaja.
7. Depois: **batalha** (F0.6) e **roubo** entre jogadores (F0.8).

### Classificação

| Eixo | Valores |
|---|---|
| **Tipo** (fixo por espécie) | Fogo, Água, Magia, Terra, Gelo, Raio, Sombra, Planta, Metal |
| **Raridade** (vem do mundo nativo) | Common → Rare → Epic → Mystic |
| **Shyne ★** | variante "brilhante" do **indivíduo** (qualquer espécie, qualquer raridade). Extremamente rara; **não** conta como slot extra no gate de mundo. |

Eventos globais para Mystic e Shyne (nome, raridade, mundo, tempo restante; só **um** jogador captura) estão na ideia do jogo e **ainda não existem** em código.

### Decisões de arquitetura já tomadas (não reabrir)

Herdadas do projeto antigo e do guia técnico:

- **Braindex = indivíduos**, não contador: cada captura é uma `Configuration` sob `player.Braindex`, com atributos. O cliente lê por replicação de atributo (sem remote de leitura). Conta espécie × shyne.
- **Toda renda** passa por `BraindexService.GetRecordIncome`; **toda compra** por `ShopService`.
- **Servidor é a autoridade**; o cliente só pede e exibe.
- **Traps CUBE** (10 tiers: ScrapCube → CosmicCube) com visual retrô estilo Ghostbusters; cor do tier em **geometria real**, nunca em `MeshPart.Color` (a engine ignora a cor em mesh com textura; `Highlight` foi descartado).
- **Escala:** `Model:ScaleTo` é absoluta → sempre `m:ScaleTo(m:GetScale() * alvo / atual)`; normalizar pela **maior dimensão**.
- **Mapa gerado no boot**, nada "salvo à mão" dentro das pastas geradas.
- **Iluminação:** faixa segura brilho 1.0–2.8, glare ≤ 0.55, haze ≤ 2.0, bloomThreshold ≥ 0.8; chão nunca preto/branco puro.
- Glifo do Shyne = **★ (U+2605)** (a fonte do Roblox não tem U+2726).

---

## 2. Linha do tempo e estado das fases

| Fase | O quê | Onde está | Estado |
|---|---|---|---|
| F0.2 | Minigame das bolinhas (captura) | projeto **antigo** (`BRAIMON.rbxl`; fonte parcial em `Downloads\BRAINMON\src`) | feito lá, **não portado** |
| F0.3 | Spawner de selvagens + captura no mundo | projeto antigo | feito lá, **não portado** |
| F0.4 | Braindex + renda passiva | projeto antigo (só no `.rbxl`) | feito lá, **não portado** |
| F0.5 | Loja de traps + upgrades | projeto antigo (só no `.rbxl`) | feito lá, **não portado** |
| — | **88 modelos 3D dos Brainmons** (Blender) | este repo: `assets/brainmon`, `blender/` | **[feito]** |
| — | **Mapa (hub + 8 mundos) + viagem + selvagens + UI de mundos** | este repo: `src/` | **[escrito, não testado]** |
| — | **Upload dos modelos para o Roblox** | `tools/upload_models.py` | script **[escrito]**; upload **[pendente]** (precisa da sua chave) |
| F0.6 | Batalha | — | **[pendente]** |
| F0.7 | Persistência (DataStore) | — | **[pendente]** — hoje **nada persiste** |
| F0.8 | Bases + roubo | — | **[pendente]** |
| F0.9 | Polimento visual e mapa | começou (mapa) | **parcial** |

> **Ordem diferente do guia:** o guia sugere F0.6 → F0.7 → F0.8 → F0.9. Você pediu para **começar pelo mapa** ("é a base do projeto"), então parte da F0.9 (mapa, portais, atmosfera por mundo) foi antecipada. Isso não conflita com o resto: o mapa não depende de Braindex/BC (ver `DevUnlockAll`, §7).

### Histórico de commits (neste repo)

| Commit | Conteúdo |
|---|---|
| `a7f703b` | Pipeline Blender + piloto (Brainmon 01) + 4 modelos de teste |
| `eca5095` | Os 88 modelos com textura de tijolo e animação `Idle` |
| *(não commitado)* | Todo o `src/` do Roblox (mapa, portais, selvagens, UI), `tools/upload_models.py`, `default.project.json` novo e este documento |

---

## 3. Estrutura do repositório

```
BRAINMON/
├─ default.project.json        Rojo: mapeia src/ -> Studio e cria ReplicatedStorage.Remotes
├─ PROJETO_BRAINMON.md         este documento
├─ BRAINMONGAMEV1.rbxl         place do Studio (scaffold; o código vem do Rojo)
│
├─ src/                        ── JOGO (Roblox, Luau) ──
│  ├─ shared/   (ReplicatedStorage)
│  │   ├─ BrainmonData.luau      raridades, tipos, 8 mundos (estilo+atmosfera+gate), layout, índices
│  │   ├─ Species.luau           as 88 espécies (id, nome, tipo, mundo) — editável à mão
│  │   ├─ BrainmonAssets.luau    [n] = assetId  (GERADO pelo upload; hoje vazio)
│  │   └─ BrainmonFactory.luau   biblioteca BrainmonModels + clone normalizado (+ placeholder)
│  ├─ server/   (ServerScriptService)
│  │   ├─ Bootstrap.server.luau  ordem de inicialização
│  │   ├─ BiomeBuilder.luau      gera hub + 8 mundos em Workspace.Map
│  │   ├─ PortalService.luau     viagem hub↔mundos (prompts, menu, requisitos, cobrança)
│  │   └─ WildSpawner.luau       selvagens andando nas zonas + idle em Luau
│  └─ client/   (StarterPlayerScripts)
│      └─ WorldClient.client.luau  atmosfera por mundo, menu M, fade, banner
│
├─ tools/
│  └─ upload_models.py         envia os 88 GLB (Open Cloud) e gera BrainmonAssets.luau
│
├─ blender/                    ── PIPELINE 3D (Python/bpy) ──
│  ├─ bm_lib.py                atlas de textura, caixas/segmentos, idle, export, render
│  ├─ bm_arch.py               arquétipos: quad, biped, serpent, blob, fish, custom
│  ├─ cbase.py                 registro de specs + helpers decorativos
│  ├─ chars_a.py … chars_d.py  specs dos Brainmons 2–88
│  ├─ brainmon_01.py           o piloto (cão-guerreiro), feito à mão
│  ├─ characters.py, run.py    registro e runner (`blender -b --python blender/run.py -- all`)
│  └─ sheet.py                 contact sheet de previews para revisão
│
└─ assets/brainmon/NN_slug/    por Brainmon: brainmon_NN.glb, .blend, tex_NN.png, preview_*.png
```

**Convenção de trabalho:** neste projeto novo o código vive **no disco** e vai para o Studio via **Rojo** (`rojo serve`). Isso é o oposto do projeto antigo (que pedia edição só pelo MCP do Studio, sem tocar no disco) — ver pergunta de projeto alvo em §6.

**Tamanhos:** `assets/` ≈ 106 MB no repositório (88 GLB somam 4,5 MB; o resto são `.blend`, texturas e previews). Vale decidir depois se `.blend`/previews saem do git.

---

## 4. Pipeline de modelos 3D (Blender)

### Resultado

- **88 modelos** em `assets/brainmon/NN_slug/`, numerados pelo **número da imagem de referência** (1–88).
- Estilo: **blocky** (caixas e pirâmides), com **textura de tijolo/pedra** em todas as cores e **rosto pintado na textura** (olhos, boca, marcas) — o mesmo conceito do GLB de referência que você mandou.
- Cada modelo: **uma malha**, **uma textura 1024²**, no máximo **744 triângulos**, GLB de 28–77 KB, **animação `Idle`** (respiração + balanço; sobe/desce nos que flutuam; 48 frames @24 fps, loop sem salto).
- Todos foram reimportados e conferidos: 88/88 com malha única, textura e `Idle`.

### Como foi feito

1. **Referências:** o zip tinha **88 imagens** (o nome diz "200", mas só 88 vieram). Fiz contact sheets para classificar os desenhos.
2. **Piloto à mão** (Brainmon 1, cão-guerreiro azul/preto) para validar o estilo — você aprovou com "mais blocky".
3. **Gerador por arquétipos** (`bm_arch.py`): `quad`, `biped`, `serpent`, `blob`, `fish`, `custom`. Cada Brainmon é uma **spec** (paleta tirada da imagem, proporções, cabeça, cauda, asas, espinhos, `extra()` para detalhes únicos).
4. **Textura:** atlas com **paleta de swatches** (cada cor é uma célula com juntas de tijolo) + **regiões pintadas por script** (rosto, espirais, discos). O "texture painting" é feito desenhando direto no mapa UV por código.
5. **Idle** adicionado no export (`bm_lib.add_idle`).

### Regenerar

```bash
# um ou mais
"C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b --python blender/run.py -- 6 7 20
# todos (≈25 min)
"C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b --python blender/run.py -- all
# piloto
"C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b --python blender/brainmon_01.py
```
Editar um Brainmon = editar a spec dele em `blender/chars_*.py` e rodar o número dele.

### Limitações honestas dos modelos

- São **mais simples** que as imagens: sem músculos esculpidos, sem pelagem detalhada; pose rígida.
- **Piores:** as **serpentes** (20, 43, 48, 51, 67, 80) ainda embolam em anéis; **humanoides magros** (ex.: 5, 74, 82) ficam frágeis.
- **Não revisei os 88 um a um** contra as referências (só por contact sheets). A passada fina por personagem é trabalho pendente.
- **Sem rig:** a animação é do **corpo inteiro** (escala/rotação do objeto). Nada de asas batendo ou cauda mexendo.
- **Roblox não lê essa animação** de GLB. No jogo, o idle é refeito em Luau (`WildSpawner`, ver §5.6). Para animação de verdade seria preciso rig por personagem.
- Alguns "Brainmons" são **cenários**, não criaturas: 31 (fazenda com trator), 60 (casa-caldeirão), 62 (templo do raio), 65 (câmara de laboratório), 72 (totem de um olho). Ver pergunta em §8.

---

## 5. O mapa dos 8 mundos

Reproduz a imagem de referência ("Mapa dos Oito Mundos"): **rio central** de norte a sul, **praça com cristal** no meio, **2 colunas × 4 linhas** de mundos, **portões** voltados para as margens. Tudo é **gerado no boot** por `BiomeBuilder` em `Workspace.Map` (a pasta é destruída e recriada a cada boot — nada pode ser salvo à mão ali).

### Planta (unidades em studs; não está em escala exata)

```
                         NORTE (-Z)
        ┌───────────────────────┬─┬───────────────────────┐   z = -470
        │ 2. BANQUETE DE        │ │ 5. PARQUE NEON DO     │
        │    CARAMELO E NEVE    │R│    CAOS DIGITAL       │
        ├───────────────────────┤I├───────────────────────┤   z = -190
        │ 1. SELVA DOS TOTENS   │O│ 7. REINO DOS CRISTAIS │
        │    PERDIDOS  (início) │ │    ETÉREOS            │
        ├───────────────────────┴─┴───────────────────────┤
        │  jardins   ( )  PRAÇA + CRISTAL  ( )  jardins   │   z =  0   (faixa do hub: 120)
        ├───────────────────────┬─┬───────────────────────┤
        │ 3. PÂNTANO TÓXICO     │ │ 6. FORJA DE MAGMA     │   z = +190
        │                       │ │    E CAOS             │
        ├───────────────────────┤ ├───────────────────────┤
        │ 4. CIDADE ABISSAL     │ │ 8. ARENA DAS SOMBRAS  │   z = +470
        │    DOS SUSSURROS      │ │    ETERNA             │
        └───────────────────────┴─┴───────────────────────┘
             x = -160 (coluna 1)   x = +160 (coluna 2)
                         SUL (+Z)
```

| Medida | Valor |
|---|---|
| Cada mundo (plot) | **260 × 260** st, centro em x = ±160; z = ±190 e ±470 |
| Rio | **36** st de largura (x −18 a 18), vidro azul 0.4 st, meio-fio de pedra nas margens, cachoeiras nas pontas N/S |
| Calçada (cada margem) | 10 st (x 20 a 30) |
| Faixa do hub | **120** st entre as linhas 2 e 3; praça de **104** st de diâmetro **cobrindo o rio** (vira ponte) |
| Vão entre mundos (mesma coluna) | 20 st |
| Laje-base do mapa | **600 × 1260** st (espessura 3) — o "bloco de diorama" da imagem |
| Cerca de cada mundo | 6 st de altura, 4 lados; lado do rio com **vão de 16 st** (o portão) |
| Zona de selvagens | plot menos 24 st de cada lado; evita 52 st em volta do marco central |

### Os 8 mundos

Ordem de progressão = ordem da tabela (mundo 1 livre; cada próximo exige o gate). Raridade segue a ideia (Common → Rare → Epic → Mystic). Custos e quantidades de espécies do gate são **[decisão minha]** (curva exponencial, estilo Steal a Brainrot) — todos editáveis em `BrainmonData.Worlds[i].gate`.

| # | Mundo (nome da imagem) | Id | Posição | Raridade nativa | Gate (espécies do mundo anterior · BC) | Marco central |
|---|---|---|---|---|---|---|
| 1 | A Selva dos Totens Perdidos | `SelvaTotens` | col. 1, linha 2 | Common | livre | zigurate musgoso + farol verde |
| 2 | O Banquete de Caramelo e Neve | `Banquete` | col. 1, linha 1 | Common | 3 · 2.500 | montanha de chocolate/caramelo/neve + cereja |
| 3 | O Pântano Tóxico | `Pantano` | col. 1, linha 3 | Rare | 3 · 15.000 | torre arruinada roxa + brilho tóxico |
| 4 | A Cidade Abissal dos Sussurros | `Abissal` | col. 1, linha 4 | Rare | 4 · 80.000 | pirâmide em 5 degraus azul-esverdeada |
| 5 | O Parque Neon do Caos Digital | `NeonPark` | col. 2, linha 1 | Epic | 4 · 400.000 | 5 arranha-céus com faixas neon + orbe roxa |
| 6 | A Forja de Magma e Caos | `Forja` | col. 2, linha 3 | Epic | 5 · 2.000.000 | vulcão em 4 degraus + lava no topo |
| 7 | O Reino dos Cristais Etéreos | `Cristais` | col. 2, linha 2 | Mystic | 5 · 10.000.000 | templo escalonado roxo/dourado |
| 8 | A Arena das Sombras Eterna | `Arena` | col. 2, linha 4 | Mystic | 6 · 50.000.000 | estádio com arquibancadas, rachaduras e refletores |

Espécies por mundo (de [Apêndice A](#apêndice-a--as-88-espécies)): **15 · 14 · 11 · 13 · 9 · 8 · 11 · 7** = 88.

### 5.1 Hub (praça central)

Praça em 3 discos de pedra + bacia com água neon + **cristal ciano** (1 central + 4 fragmentos) com `PointLight`; ruas para os jardins E/W e 4 diagonais; **8 postes** (a luz quente do hub vem só deles) e ~40 árvores agrupadas nos jardins; `SpawnLocation` `HubSpawn` na frente do cristal. Atmosfera do hub = **hora azul calibrada** do projeto antigo (`clockTime 18.4`, brilho 2.0, ar 150,172,214, haze 1.2, densidade 0.30, ambiente externo 96,112,160).

### 5.2 Mundos (gerador)

Cada mundo é construído por `buildWorld(i)`: chão quadriculado (tiles de 20 st, **13×13**, duas cores por mundo), cerca + postes, **portão**, marco central, e **170 tentativas de decoração** deterministicamente semeadas (`Random.new(7000+i)`), com a regra do projeto antigo: **~62% agrupada perto do item anterior** (evita "campo de golfe"), nunca dentro do marco nem do corredor do portão. Tipos de decoração: `tree`, `stack`, `pillar`, `mound` (esfera achatada meio enterrada), `crystal`, `pool`, `lamp`; cada mundo escolhe e pesa os seus.

### 5.3 Portão e viagem (`PortalService`)

Cada mundo tem um **Gate House** na cerca voltada ao rio: 2 pilares + dintel com **placa** (nome + "N BRAINMONS · X BC") + **porta sólida neon** (a passagem é por **teleporte validado**, não por caminhar). Dois pads com `ProximityPrompt`:

- **EnterPad** (na calçada): "Entrar".
- **ExitPad** (dentro do mundo): "Voltar ao Hub".

Também pelo **menu Worlds (tecla M)**: linha do Hub + 8 mundos, cada uma com **IR** / **LIBERAR** (mostra `3 / 3 BRAINMONS · 2500 / 2500 BC`) / **BLOQUEADO**.

Regras no **servidor** (`PortalService.Travel`):

1. Valida tipo/faixa do índice (`0` = hub, `1..8`); **debounce de 2 s** por jogador (vídeo B#10 do guia).
2. Mundo ≤ liberado → viaja de graça. Mundo = liberado+1 → exige **espécies do mundo anterior** (contadas nas `Configuration` de `player.Braindex`) **e** BC; **cobra** e libera. Pulou mundo → aviso.
3. `FadeOut` → espera 0,45 s → `PivotTo` no ponto do mundo → atributos `World` e `WorldsUnlocked` → `FadeIn` + **banner** com o nome da área → empurra `WorldState`.
4. Respawn volta ao **mesmo mundo** (`CharacterAdded`).

Remotes (todos em `ReplicatedStorage.Remotes`, um por intenção, como o guia recomenda): `WorldTravel` (C→S), `WorldState` (S→C), `WorldBanner` (S→C: `FadeOut`/`FadeIn`/`Notice`).

Atributos do jogador: `World` (0 = hub), `WorldsUnlocked` (maior mundo liberado), `BC` (lido; futuro dono = ShopService).

### 5.4 Atmosfera por mundo (cliente)

`WorldClient` aplica `Lighting` + `Atmosphere` + `BloomEffect` com tween de 1,5 s ao mudar `World`. Todos os valores passam por `BrainmonData.SafeAtmosphere`, que **força a faixa segura** (brilho 1.0–2.8, glare ≤ 0.55, haze ≤ 2.0, bloomThreshold ≥ 0.8) — mesmo que alguém digite um valor fora. A iluminação é local ao jogador, então jogadores em mundos diferentes veem climas diferentes sem custo no servidor.

### 5.5 Brainmons no jogo (`BrainmonFactory`)

- No boot, `Factory.Preload()` cria `ReplicatedStorage.BrainmonModels` com **1 modelo por espécie** (nome = id PascalCase, ex. `AvocadoDeer`): tudo `Anchored`, sem colisão, **sem scripts de terceiros**, `Root` invisível (bounding box) como `PrimaryPart`.
- Fonte: `InsertService:LoadAsset(assetId)` (ids de `BrainmonAssets`). **Sem id → placeholder** (bloco colorido pelo **tipo**, com cabeça e olhos), então o jogo funciona antes do upload.
- `Factory.Create(id, shyne)` clona e normaliza pela **maior dimensão**: Common **4,5** st · Rare **6,5** · Epic **9** · Mystic **12,3** (×1,15 se Shyne). `ScaleTo` sempre como `GetScale() * alvo / atual`.

### 5.6 Selvagens (`WildSpawner`)

6 por mundo (48 no total) sorteados entre as espécies **do mundo**, com chance de **Shyne 1/200** (★ dourada no nome). Andam por alvos aleatórios dentro da zona, com as regras do projeto antigo: passo limitado ao que falta e a `dt ≤ 0.1`; **clamp pela bounding box** (não pelo pivô). Cada um tem um rótulo `Nome` + `Tipo · Raridade` colorido. **Idle em Luau** (sobe/desce ±0,12 st e inclina ±1,5°), que equivale ao `Idle` dos GLBs. Ainda **não há captura** — é só a vitrine dos modelos.

---

## 6. Decisões tomadas e premissas

| # | Decisão | Por quê / como mudar |
|---|---|---|
| 1 | **Projeto novo com Rojo** (você escolheu) | Código no disco, versionado. O projeto antigo continua como fonte da lógica F0.2–F0.5 a portar. |
| 2 | **Upload por script com sua chave Open Cloud** (você escolheu) | Roblox só usa mesh na nuvem; eu não posso usar sua chave. A chave fica só em variável de ambiente. |
| 3 | **8 mundos** (da imagem), não 15 (da ideia) | A imagem define 8. `BrainmonData.Worlds` é uma lista: adicionar mundos = adicionar entradas + posição na grade (`OriginOf` já calcula pelo layout). **Pergunta aberta:** os outros 7 mundos virão como expansão? |
| 4 | **Raridade vem do mundo** (todo bicho do mundo tem a raridade nativa dele) | Segue "cada mundo tem raridade nativa". Muda se você quiser raridade por espécie (trocar `RarityOf`). |
| 5 | **Distribuição dos 88 por mundo e por tipo** | Escolhi pela temática/cores (ex.: radioativos → Pântano; cafés/doces → Banquete). **Totalmente editável** em `src/shared/Species.luau`. Contagens desiguais (7 a 15) são consequência disso. |
| 6 | **Tipos só os 9 do doc** | Os "radioativos" viraram `Metal`/`Terra`; não criei tipo novo (Veneno etc.). |
| 7 | **Ordem de progressão** Selva → Banquete → Pântano → Abissal → Neon → Forja → Cristais → Arena | A imagem não define ordem. É a ordem do array `Worlds`. |
| 8 | **Custos/gates** (3, 3, 4, 4, 5, 5, 6 espécies; 2,5k → 50M BC) | Curva exponencial estilo Steal a Brainrot; ajustar com o balanceamento. |
| 9 | **`DevUnlockAll = true`** | Como ainda não há BC nem Braindex neste projeto, sem isso só o mundo 1 seria alcançável. É um **flag explícito** (não um bypass escondido). **Desligar** quando BC/Braindex existirem. |
| 10 | **Hub = praça central do mapa** (não "bases") | O guia (§7.2) previa um hub de bases fora dos biomas. Aqui o hub é a praça da imagem. As **bases de roubo (F0.8)** ficarão **fora da caixa do mapa** (ver §8 passo 7). |
| 11 | **Portão por teleporte**, não por corredor caminhável | Mantém a regra "servidor decide" e evita contornar o gate andando. O desenho (porta sólida + pads) lembra o "corredor + trigger" da ideia. |
| 12 | **Selvagens sem captura ainda** | O pedido foi mapa + personagens no jogo; captura/trap vêm do porte da F0.2/F0.3. |

**Divergências do guia técnico (conscientes):** (a) ordem das fases (mapa primeiro); (b) 8 mundos em vez de 15; (c) sem `Services/` por enquanto — `BiomeBuilder`/`PortalService`/`WildSpawner` ficam na raiz de `ServerScriptService`, como o guia lista; `Services/` entra com Braindex/Shop/Data/Battle/Steal.

---

## 7. Como rodar, testar e calibrar

### 7.1 Rodar o jogo

```bash
cd C:\Users\Matth\BRAINMON
rojo serve                       # e no Studio: plugin Rojo > Connect
# (ou) rojo build -o BRAINMON.rbxlx   -> abrir o arquivo
```
Aperte **Play**. No **Output** devem aparecer, nesta ordem:

```
[Bootstrap] modelos: 0 reais, 88 placeholders
[BiomeBuilder] mapa gerado: <N> instancias em <T>s
[WildSpawner] 48 selvagens (6 por mundo)
[Bootstrap] BRAINMON pronto
```
O Bootstrap remove `Workspace.Baseplate` e a `SpawnLocation` de template (sobras do place antigo) porque o mapa é todo gerado.

**Teste manual:** nasce na praça → andar até uma calçada → prompt **"Entrar"** no pad do portão → fade + banner do nome → atmosfera muda → **M** abre o menu → **"Voltar ao Hub"** pelo pad interno ou botão do hub.

### 7.2 Enviar os 88 modelos para o Roblox

1. Em create.roblox.com → **Credentials** → crie uma **API key** com permissão **assets: Read + Write**. Pegue seu **userId** (ou groupId).
2. No PowerShell **(não cole a chave em chats nem commite)**:
```powershell
$env:ROBLOX_API_KEY = "<sua chave>"
$env:ROBLOX_USER_ID = "<seu userId>"      # ou ROBLOX_GROUP_ID
python tools\upload_models.py --dry-run   # confere a lista
python tools\upload_models.py             # envia os 88; retoma se cair; grava src/shared/BrainmonAssets.luau
```
3. Com o Rojo conectado, os ids chegam ao Studio e os placeholders somem sozinhos no próximo Play.

API usada (conferida na documentação oficial): `POST https://apis.roblox.com/assets/v1/assets` (multipart `request` + `fileContent`, `model/gltf-binary`) e `GET .../operations/{id}` até `done`.

### 7.3 Calibrações que dependem de ver o modelo no Studio

| Item | Onde | O que fazer |
|---|---|---|
| **Frente do modelo** | `BrainmonFactory.FacingFix` | O GLB sai com a frente em **+Z**; o Roblox usa **−Z**. O valor padrão (giro de 180°) é um palpite. Se o bicho andar de costas, trocar para `CFrame.identity`. |
| **Escala** | `BrainmonData.RarityInfo[*].scale` | 4,5 / 6,5 / 9 / 12,3 st (maior dimensão). Conferir contra o personagem (~5 st). |
| **Cores/textura importadas** | — | Conferir se a textura de tijolo chegou no `MeshPart` (o Open Cloud converte o GLB). |
| **Gates / custos** | `Worlds[i].gate` | Balancear depois. |
| **Atmosfera** | `Worlds[i].atmosphere` | Ajustar olhando cada mundo; o clamp mantém a faixa segura. |

### 7.4 Para mudar o jogo sem mexer em código

- **Espécie ↔ mundo/tipo:** `src/shared/Species.luau`.
- **Mundo (nome, cores, decoração, marco, atmosfera, gate):** `BrainmonData.Worlds`.
- **Layout (tamanho do plot, rio, hub):** `BrainmonData.Layout`.
- **Quantos selvagens, chance de Shyne, debounce:** `BrainmonData.Config`.

---

## 8. Próximos passos

Ordem recomendada. Cada passo tem **critério de pronto**. Referências `Guia §X` = `BRAINMON_guia_tecnico.md`.

### Passo 0 — Validar o que já foi escrito (**imediato, com você**)

1. `rojo serve` + Play (§7.1). Ler o Output e me mandar erros, se houver.
2. Rodar `upload_models.py` (§7.2) e calibrar `FacingFix` e escala (§7.3).
3. Comparar o mapa gerado com a imagem de referência (prints) e listar o que destoa.

**Pronto quando:** mapa gera sem erro, viagem funciona nos 2 sentidos, os 88 modelos aparecem (com textura) andando nas zonas e de frente para onde andam.

### Passo 1 — Polimento do mapa contra a imagem

Ajustar proporções dos marcos (montanha de doce, torres neon, vulcão, pirâmides), água/cachoeiras (hoje vidro estático), densidade de decoração (~600 peças/mundo é estimativa **não medida**; o boot imprime a contagem real), iluminação de cada mundo. Avaliar `StreamingEnabled` (Guia F0.9) se o total de peças pesar.
**Pronto:** parecido com a imagem, FPS estável, boot rápido (referência do projeto antigo: ~0,08 s por bioma completo).

### Passo 2 — Trazer o loop principal para o projeto novo (F0.2 → F0.5)

Hoje **não existem** aqui: captura, Braindex, renda, loja, traps. Fonte: projeto antigo. Ordem sugerida:

1. **`BraindexService`** (indivíduos como `Configuration` sob `player.Braindex`; `GetRecordIncome`; 38→88 entradas × shyne) e renda passiva (1 tick/s somando `GetRecordIncome` ao BC, **sem** loop por bicho — Guia §3.5; offline com teto, ex. 8 h).
2. **`ShopService`** (única autoridade de preço; BC como atributo/`leaderstats` somente leitura) + traps CUBE e upgrades.
3. **Captura** (anéis; reserva do alvo no servidor; "trap engole o modelo"; teto de trap por raridade — a captura **nem começa** se o CUBE for fraco). Reaproveitar `CaptureRing.luau`, `CaptureController`, `WildSpawner` do projeto antigo.
4. **Desligar `DevUnlockAll`** e ligar o gate real (já lê `player.Braindex` e `BC`).

**Pronto:** capturar um bicho no mundo 1 gera um indivíduo, rende BC, e juntar espécies + BC libera o mundo 2 de verdade.

> **Decisão necessária:** o projeto antigo tem **19 espécies** do pack BRAINROT PACK 3 (Tungo Tungo etc.); o novo tem **88 Brainmons próprios**. As 19 saem de vez, viram um mundo à parte ou coexistem?

### Passo 3 — F0.6 Batalha (Guia §4.5, §8 F0.6, §9.1)

`BattleData` (tabela de tipos dos **9 tipos**, golpes, stats-base por espécie — **precisam ser criados**), `BattleService` por turnos **100% no servidor** (`BattleRequest`/`BattleAction`/`BattleUpdate`), `BraindexService.AddXp` com level up, `BattleUI` + câmera Scriptable. Usa `Level`, `Xp`, `InSquad`.
**Pronto:** Guia F0.6 (a–e): números coerentes, `Level`/`Xp` sobem na sessão, cliente não age fora do turno, sair no meio não corrompe o Braindex, câmera sempre restaurada.

### Passo 4 — F0.7 Persistência (Guia §5.1, §9.2)

`DataService` com **1 DataStore versionado**, `UpdateAsync`, lock de sessão, autosave 60–120 s, `BindToClose`, modo "perfil temporário" se o load falhar (nunca salvar por cima). Serializar cada indivíduo: `{Id(GUID), Species, Shyne, Level, Xp, Biome, InSquad, CapturedAt}`; salvar também `WorldsUnlocked`, BC, traps, upgrades e o conjunto `Discovered` (para as 88×2 entradas do Braindex).
**Pronto:** sair e voltar restaura tudo; 2 servidores não duplicam perfil. **Não** lançar ao público nem abrir o roubo antes disso.

### Passo 5 — Animações de verdade (opcional, depende do orçamento)

Rig por arquétipo (quadrúpede/bípede/serpente/ave) no Blender + `AnimationController` no Roblox. Até lá o idle é o de Luau.

### Passo 6 — Revisão fina dos 88 modelos

Passar em cada um contra a imagem: serpentes (20, 43, 48, 51, 67, 80), humanoides magros, e decidir o destino dos "cenários" (31, 60, 62, 65, 72). Opcional: mais detalhe nos mais raros.

### Passo 7 — F0.8 Bases + roubo (Guia §3.6, §7.2, §8 F0.8, §9.3)

- **Onde:** `BaseBuilder` gera as bases **fora da caixa do mapa**. Use `BiomeBuilder.GetBounds()` (hoje 600 × 1260 st) e a regra do guia `hubOrigin = Vector3.new(maxX + 200, 0, centerZ)` → bases a partir de **x ≈ 500**, ligadas ao hub por portal (mesmo `PortalService`).
- **Roubo sobre os indivíduos:** pegar → carregar → entregar **move a `Configuration`** de `player.Braindex` do dono para o do ladrão, **transferência atômica**, nunca duplicar; `OwnerUserId` (não nome); trava com colisão **no servidor**; auto-lock de 20 s ao entrar.
- Decisões abertas do Guia §10.1 (quem pode ser roubado, `InSquad` protegido?, dono offline?, interceptação) precisam de resposta antes.
**Pronto:** Guia F0.8.

### Passo 8 — Polimento final e live-ops

Efeitos **Shyne** (partículas, sem `Highlight`), **eventos globais** de Mystic/Shyne (`MessagingService`, só um captura), performance com 12 jogadores, UI com o tema do Guia §6.2 (roxo `#5B3A8C`, oliva `#6B7A3A`, LCD `#7CFF8A`, dourado `#FFC933`).

### Decisões que preciso de você

1. Os **outros 7 mundos** (15 da ideia) virão? Em que ordem/tema?
2. As **19 espécies antigas**: descartar, coexistir ou virar mundo próprio?
3. Os **5 "cenários"** (31, 60, 62, 65, 72) são criaturas ou props do mapa?
4. Distribuição **espécie → mundo/tipo** e **ordem dos mundos** (§6 #5 e #7): ok ou quer ajustar?
5. Do Guia §10.1: batalha **por turnos** (recomendado) ou tempo real? Persistência **antes** ou depois da batalha? Quem pode ser roubado? Rebirth entra?

---

## 9. O que não foi verificado / limitações

**Importante:** o código do Roblox deste repositório (`src/`, ≈1,4 mil linhas) **foi escrito e conferido por revisão e por `rojo build` (o projeto compila e monta a árvore), mas NÃO foi executado no Studio.** Também **não há analisador Luau** instalado aqui, então a tipagem `--!strict` foi revisada à mão. Espere pequenos erros no primeiro Play.

| Item | Situação |
|---|---|
| Código Luau rodando no Studio | **não testado** |
| Aparência do mapa vs. imagem | **não comparado** |
| Contagem real de peças / tempo de boot | **não medida** (o `BiomeBuilder` imprime ao rodar) |
| `FacingFix` (frente do modelo) | **palpite** |
| Importação dos GLB pelo Open Cloud (textura, escala, hierarquia) | **não testada** — script escrito conforme a doc oficial, nunca executado |
| `InsertService:LoadAsset` com os assets enviados | **não testado** (assets precisam pertencer ao dono do jogo/place publicado) |
| Moderação do Roblox sobre os uploads | **desconhecida** |
| Integração com BC/Braindex | **inexistente** neste repo (`PortalService` só lê `BC` e `player.Braindex` se existirem) |
| Persistência | **inexistente** — nada sobrevive entre sessões |
| Roubo, batalha, captura, loja | **inexistentes** neste repo |
| Animação idle no Roblox | feita em Luau no selvagem; **o `Idle` dos GLB não é usado** |
| Revisão por personagem dos 88 modelos | **não feita** |
| Playlists do YouTube do guia | não revisei os vídeos; segui o `.md` que você me deu |

Pequenos pontos de atenção no código: `PortalService` cobra BC direto por um atributo (provisório até existir `ShopService`); `DevUnlockAll` está **ligado**; `WildSpawner` move os 48 modelos a 15 Hz do servidor (ok para esta escala; revisar se crescer).

---

## Apêndice A — As 88 espécies

`n` = número da imagem de referência (e do arquivo `assets/brainmon/NN_*`). Mundo/tipo/raridade são **[decisão minha]**, editáveis em `src/shared/Species.luau`. Raridade = a do mundo.

| n | Id | Nome | Tipo | Mundo | Raridade |
|---|---|---|---|---|---|
| 1 | `DogWarrior` | Dog Warrior | Sombra | 8. Arena das Sombras | Mystic |
| 2 | `MothSpider` | Moth Spider | Terra | 3. Pântano | Rare |
| 3 | `ArmoredCroc` | Armored Croc | Metal | 8. Arena das Sombras | Mystic |
| 4 | `MawMonster` | Maw Monster | Terra | 3. Pântano | Rare |
| 5 | `CoffeeBallerina` | Coffee Ballerina | Magia | 2. Banquete | Common |
| 6 | `AvocadoDeer` | Avocado Deer | Planta | 1. Selva dos Totens | Common |
| 7 | `CatChameleon` | Cat Chameleon | Planta | 1. Selva dos Totens | Common |
| 8 | `BunnyTan` | Bunny Tan | Terra | 1. Selva dos Totens | Common |
| 9 | `WhiteFlyer` | White Flyer | Raio | 5. Parque Neon | Epic |
| 10 | `PhoenixToucan` | Phoenix Toucan | Fogo | 6. Forja | Epic |
| 11 | `TurtleDragon` | Turtle Dragon | Água | 4. Cidade Abissal | Rare |
| 12 | `FlowerFairy` | Flower Fairy | Planta | 1. Selva dos Totens | Common |
| 13 | `SkyWhale` | Sky Whale | Água | 4. Cidade Abissal | Rare |
| 14 | `TealDragon` | Teal Dragon | Água | 4. Cidade Abissal | Rare |
| 15 | `HydraBlack` | Hydra Black | Sombra | 8. Arena das Sombras | Mystic |
| 16 | `MothCream` | Moth Cream | Terra | 3. Pântano | Rare |
| 17 | `NightBatdragon` | Night Batdragon | Magia | 7. Reino dos Cristais | Mystic |
| 18 | `IceLion` | Ice Lion | Gelo | 2. Banquete | Common |
| 19 | `WoodFoxSword` | Wood Fox Sword | Fogo | 6. Forja | Epic |
| 20 | `SkySerpent` | Sky Serpent | Magia | 7. Reino dos Cristais | Mystic |
| 21 | `GatorBlade` | Gator Blade | Fogo | 6. Forja | Epic |
| 22 | `IceGoodra` | Ice Goodra | Gelo | 2. Banquete | Common |
| 23 | `BlackBlueDragon` | Black Blue Dragon | Raio | 5. Parque Neon | Epic |
| 24 | `LatteDragon` | Latte Dragon | Magia | 2. Banquete | Common |
| 25 | `OrcaBird` | Orca Bird | Água | 4. Cidade Abissal | Rare |
| 26 | `RedArmorBeast` | Red Armor Beast | Metal | 6. Forja | Epic |
| 27 | `StarKite` | Star Kite | Raio | 5. Parque Neon | Epic |
| 28 | `GemTentacle` | Gem Tentacle | Magia | 5. Parque Neon | Epic |
| 29 | `CrystalDino` | Crystal Dino | Gelo | 7. Reino dos Cristais | Mystic |
| 30 | `JarTurtle` | Jar Turtle | Água | 4. Cidade Abissal | Rare |
| 31 | `TractorFarm` | Tractor Farm | Terra | 1. Selva dos Totens | Common |
| 32 | `LotusBeast` | Lotus Beast | Planta | 1. Selva dos Totens | Common |
| 33 | `IceCamelLion` | Ice Camel Lion | Gelo | 2. Banquete | Common |
| 34 | `RedFoxLeaf` | Red Fox Leaf | Fogo | 6. Forja | Epic |
| 35 | `NinjaFrog` | Ninja Frog | Água | 4. Cidade Abissal | Rare |
| 36 | `PineappleShark` | Pineapple Shark | Água | 4. Cidade Abissal | Rare |
| 37 | `DrumMonkey` | Drum Monkey | Terra | 1. Selva dos Totens | Common |
| 38 | `TreantWolf` | Treant Wolf | Planta | 1. Selva dos Totens | Common |
| 39 | `IceCamelDino` | Ice Camel Dino | Gelo | 2. Banquete | Common |
| 40 | `PenguinKnight` | Penguin Knight | Gelo | 2. Banquete | Common |
| 41 | `VoidWolf` | Void Wolf | Sombra | 8. Arena das Sombras | Mystic |
| 42 | `BladeCroc` | Blade Croc | Fogo | 6. Forja | Epic |
| 43 | `SkySerpent2` | Sky Serpent 2 | Planta | 1. Selva dos Totens | Common |
| 44 | `BlackDragon` | Black Dragon | Sombra | 8. Arena das Sombras | Mystic |
| 45 | `WhiteGuardian` | White Guardian | Magia | 7. Reino dos Cristais | Mystic |
| 46 | `OwlGriffin` | Owl Griffin | Sombra | 8. Arena das Sombras | Mystic |
| 47 | `DuckbillLion` | Duckbill Lion | Planta | 3. Pântano | Rare |
| 48 | `SeaSerpent` | Sea Serpent | Água | 4. Cidade Abissal | Rare |
| 49 | `MoonLion` | Moon Lion | Magia | 7. Reino dos Cristais | Mystic |
| 50 | `RobotDog` | Robot Dog | Metal | 5. Parque Neon | Epic |
| 51 | `FeatherSerpent` | Feather Serpent | Gelo | 7. Reino dos Cristais | Mystic |
| 52 | `PinkRibbonFox` | Pink Ribbon Fox | Magia | 2. Banquete | Common |
| 53 | `LilacGemCat` | Lilac Gem Cat | Magia | 7. Reino dos Cristais | Mystic |
| 54 | `AvocadoDeer2` | Avocado Deer 2 | Planta | 1. Selva dos Totens | Common |
| 55 | `IceLion2` | Ice Lion 2 | Gelo | 2. Banquete | Common |
| 56 | `BananaDolphin` | Banana Dolphin | Água | 4. Cidade Abissal | Rare |
| 57 | `WoodDragon` | Wood Dragon | Fogo | 6. Forja | Epic |
| 58 | `ChocoLolita` | Choco Lolita | Terra | 2. Banquete | Common |
| 59 | `VoxelWhale` | Voxel Whale | Água | 4. Cidade Abissal | Rare |
| 60 | `WitchCauldron` | Witch Cauldron | Sombra | 8. Arena das Sombras | Mystic |
| 61 | `PinkCat` | Pink Cat | Magia | 2. Banquete | Common |
| 62 | `ThunderTemple` | Thunder Temple | Raio | 5. Parque Neon | Epic |
| 63 | `BreadStego` | Bread Stego | Terra | 2. Banquete | Common |
| 64 | `LionCub` | Lion Cub | Terra | 1. Selva dos Totens | Common |
| 65 | `LabChamber` | Lab Chamber | Metal | 5. Parque Neon | Epic |
| 66 | `CrystalZilla` | Crystal Zilla | Metal | 7. Reino dos Cristais | Mystic |
| 67 | `WoodSerpent` | Wood Serpent | Planta | 3. Pântano | Rare |
| 68 | `JesterPatch` | Jester Patch | Magia | 5. Parque Neon | Epic |
| 69 | `HermitCrab` | Hermit Crab | Terra | 3. Pântano | Rare |
| 70 | `Mermaid` | Mermaid | Água | 4. Cidade Abissal | Rare |
| 71 | `MantisFairy` | Mantis Fairy | Planta | 3. Pântano | Rare |
| 72 | `EyeTotem` | Eye Totem | Terra | 1. Selva dos Totens | Common |
| 73 | `GoatSnail` | Goat Snail | Magia | 7. Reino dos Cristais | Mystic |
| 74 | `LatteWarrior` | Latte Warrior | Magia | 7. Reino dos Cristais | Mystic |
| 75 | `RadiationZilla` | Radiation Zilla | Metal | 3. Pântano | Rare |
| 76 | `LeafCat` | Leaf Cat | Planta | 1. Selva dos Totens | Common |
| 77 | `HoodFrog` | Hood Frog | Água | 3. Pântano | Rare |
| 78 | `OwlArcher` | Owl Archer | Planta | 1. Selva dos Totens | Common |
| 79 | `IceMammoth` | Ice Mammoth | Gelo | 2. Banquete | Common |
| 80 | `LeafSeadragon` | Leaf Seadragon | Água | 4. Cidade Abissal | Rare |
| 81 | `LimeGuardian` | Lime Guardian | Metal | 3. Pântano | Rare |
| 82 | `WhiteBallerina` | White Ballerina | Magia | 7. Reino dos Cristais | Mystic |
| 83 | `LanternBird` | Lantern Bird | Água | 4. Cidade Abissal | Rare |
| 84 | `TealZilla` | Teal Zilla | Terra | 3. Pântano | Rare |
| 85 | `LatteWitch` | Latte Witch | Magia | 2. Banquete | Common |
| 86 | `TotemLizard` | Totem Lizard | Terra | 1. Selva dos Totens | Common |
| 87 | `CloudBird` | Cloud Bird | Raio | 5. Parque Neon | Epic |
| 88 | `SteelRhino` | Steel Rhino | Metal | 6. Forja | Epic |

---

## Apêndice B — Referência rápida de código

### Atributos e instâncias criados em runtime

| Onde | Nome | Quem escreve | Significado |
|---|---|---|---|
| `Player` | `World` | servidor | 0 = hub, 1–8 = mundo atual |
| `Player` | `WorldsUnlocked` | servidor | maior mundo liberado |
| `Player` | `BC` | (futuro ShopService) | saldo; hoje só lido |
| `Player.Braindex` | `Configuration` por indivíduo | (futuro BraindexService) | atributos `Species`, `Shyne`, `Level`, `Xp`, `Biome`, `InSquad` |
| `Workspace` | `Map` | `BiomeBuilder` | recriado a cada boot |
| `Workspace` | `Wild` | `WildSpawner` | selvagens (tag `Wild`; atributos `World`, `SpeciesNumber`, `Species`, `Rarity`, `Shyne`, `Type`) |
| `ReplicatedStorage` | `BrainmonModels` | `BrainmonFactory` | biblioteca (1 por espécie) |
| `ReplicatedStorage.Remotes` | `WorldTravel`, `WorldState`, `WorldBanner` | Rojo | ver §5.3 |

### API dos módulos

```lua
-- BrainmonData (shared)
Data.Worlds[i]            -- { id, name, rarity, col, row, gate{species,bc}, style{...}, atmosphere{...} }
Data.OriginOf(i)          -- Vector3 do centro do mundo i
Data.SafeAtmosphere(a)    -- clamp na faixa segura
Data.GateText(i, owned, bc) -- "3 / 3 BRAINMONS · 2500 / 2500 BC"
Data.SpeciesById[id], Data.SpeciesByWorld[i], Data.RarityOf(sp)

-- BrainmonFactory (shared)
Factory.Preload() -> (reais, placeholders)       -- servidor, no boot
Factory.Create(speciesId, shyne?) -> Model       -- normalizado pela maior dimensão
Factory.FacingFix                                -- CFrame de calibração da frente

-- BiomeBuilder (server)
BiomeBuilder.Build() -> { folder, hubSpawn, worlds[i] = { folder, origin, spawn, zone, gatePos } }
BiomeBuilder.GetBounds() -> (centro, tamanho)    -- para BaseBuilder (F0.8)

-- PortalService (server)
PortalService.Init(map)
PortalService.Travel(player, idx) -> boolean     -- valida, cobra, teleporta
```

### Comandos úteis

```bash
rojo serve                                   # sincroniza src/ com o Studio
rojo build -o BRAINMON.rbxlx                 # monta um place a partir do projeto
python tools/upload_models.py --dry-run      # confere o upload
blender -b --python blender/run.py -- 6 7    # regenera Brainmons 6 e 7
```
