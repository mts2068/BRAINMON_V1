# BRAINMON — Status

Steal-a-Brainrot × Pokémon ("brainrot italiano"). 88 espécies, 8 mundos, Rojo + Studio.
Atualizado: 2026-10-01 · HEAD `2bff61d`

---

## ✅ Feito

### Mapa — Hub virou "town" (`BiomeBuilder.luau`)
- Avenida central E-W: calçada + tapete vermelho + trim dourado; postes flanqueando; sebes; árvores de fundo.
- Fonte de cristal com luz no centro; plazas/discos; rio + cascata.
- **Props da town** (posições do mockup): em volta da fonte — SHOP, ROBUX SHOP, FUSE MACHINE, SPIN THE WHEEL; numa ponta — TOP EARN / TOP TIME; na outra — NPC "Vender Brainmon" + NPC "Batalhar".
- Labels das estruturas: menores e **no topo** de cada uma (não mais flutuando no meio).

### Bases dos jogadores — estilo "garagem" (`BaseBuilder.luau` + `BaseService.luau`)
- 12 plots alinhados à avenida (`Data.BaseSlots()`): moldura cinza + banner marrom com o nome + chão de tapete vermelho + 4 pads.
- **Economia acumula+coleta**: os Brainmons na base geram renda por segundo → acumula em "pending" → pisar na **Collect Zone** banca o valor (×CashMulti) nos BrainCoins.
- Squad é só time de batalha; **a base é a fonte de renda**.

### Economia / dados (`BrainmonData.luau` + `BraindexService.luau`)
- Braindex guarda indivíduos (Species/Shyne/Level/Xp/Placed…).
- Renda por raridade: Common 3 · Rare 20 · Epic 140 · Mystic 1000 /s; Shyne ×5.
- `D.Money(n)`: 1 / 1K / 1M / 1Bi / 1T / 1Qa / 1Qi… (abreviação verificada).

### HUD (`HudClient.client.luau`)
- **BrainCoins** no canto superior direito (formatado).
- Cluster de 6 botões à esquerda (SHOP / REBIRTH / BRAINDEX / BATTLE / TRADE / INVENTORY), na ordem do mockup.
- Já são ImageButton; hoje caem em quadrado colorido (fallback). **Faltam os IDs dos ícones.**

### Domos de energia (`BiomeBuilder.luau`)
- Caixa oca **fosca, cúbica, cobrindo a área toda** de cada mundo, na cor do mundo.
- São **barreiras sólidas** (CanCollide): só se entra por portal ou pelo seletor M.

### Eventos (`EventService.luau`)
- De 2–5 min, aparece 1 Brainmon **Epic→Mystic em Shyne** no hub por 90s; primeiro a capturar leva.
- O **banner acima do cristal só aparece durante o evento** (escondido o resto do tempo).

### Captura (`WildSpawner.luau`)
- Prompt "Capturar" → vai pro Braindex → entra na base automaticamente → respawn do selvagem.
- Verificado in-game: capturei 2 Epics, coletei → BC $8.54K.

---

## ⏳ Falta

**Você faz:**
- Importar os 6 ícones (`assets/hud/btn_*.png`) no Asset Manager do Studio → me mandar os `rbxassetid` (preencho a tabela `ICONS`).
- Pesquisa breve das mecânicas (como quiser): SHOP, BRAINDEX, SPIN THE WHEEL, REBIRTH, ovos, lucky block, ROBUX SHOP.

**Eu faço (na ordem combinada):**
1. Portais-arco: restyle dos 8 portões como arcos de pedra com label de requisito.
2. NPC "Vender Brainmon" (vender por BC) + painéis BRAINDEX / INVENTORY com os bichos reais.
3. Configurar os sistemas acima (após sua pesquisa): lojas, roda, rebirth, ovos, lucky block.
4. Máquina de fusão (regras inferidas).
5. Leaderboards com dados reais (Top Earn / Top Time).
6. Minigame de captura (anéis) no lugar do hold; grab/sell nas bases; lock/steal de base.
7. **Batalha PVP + PVAI** (final).

**Infra pendente:**
- Persistência / DataStore (nada salva ainda — Passo 4).
- Desligar `DevUnlockAll` quando for pra valer.

---

## Como rodar
`rojo serve` + plugin no Studio sincroniza `src/` → DataModel. O mapa é 100% gerado no boot (`Bootstrap.server.luau`), nada montado à mão.
