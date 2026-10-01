#!/usr/bin/env python3
"""Envia os GLB de assets/brainmon/*/brainmon_NN.glb para o Roblox (Open Cloud Assets API) e gera
src/shared/BrainmonAssets.luau  (mapa  numero-da-especie -> assetId).

Uso (PowerShell):
    $env:ROBLOX_API_KEY  = "<sua chave>"      # nunca commitar nem colar em chat
    $env:ROBLOX_USER_ID  = "<seu userId>"     # OU  $env:ROBLOX_GROUP_ID = "<groupId>"
    python tools/upload_models.py --dry-run   # lista o que seria enviado
    python tools/upload_models.py             # envia tudo (retoma de onde parou)
    python tools/upload_models.py --only 6 7  # so algumas especies

A chave precisa de: Access Permissions "assets" com Read + Write (create.roblox.com > Credentials).
Docs: https://create.roblox.com/docs/cloud/guides/usage-assets  (Model aceita .glb, content-type model/gltf-binary)
So biblioteca padrao (urllib): nenhuma dependencia para instalar.
"""
import argparse
import json
import os
import re
import sys
import time
import urllib.error
import urllib.request
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MODELS = ROOT / "assets" / "brainmon"
OUT = ROOT / "src" / "shared" / "BrainmonAssets.luau"
API = "https://apis.roblox.com/assets/v1"


def load_existing() -> dict[int, int]:
    if not OUT.exists():
        return {}
    return {int(a): int(b) for a, b in re.findall(r"\[(\d+)\]\s*=\s*(\d+)", OUT.read_text(encoding="utf8"))}


def save(ids: dict[int, int]) -> None:
    body = "".join(f"\t[{n}] = {ids[n]},\n" for n in sorted(ids))
    OUT.write_text(
        "--!strict\n"
        "-- Mapa [numero da especie] = assetId do Model no Roblox. GERADO por tools/upload_models.py (nao editar a mao).\n"
        "-- Vazio = o jogo usa o bloco-placeholder colorido por tipo ate o upload ser feito.\n"
        "return {\n" + body + "} :: { [number]: number }\n",
        encoding="utf8",
    )


def multipart(fields: dict[str, str], file_field: str, filename: str, content: bytes, ctype: str):
    b = uuid.uuid4().hex
    parts = []
    for k, v in fields.items():
        parts.append(f'--{b}\r\nContent-Disposition: form-data; name="{k}"\r\n\r\n{v}\r\n'.encode())
    parts.append(
        f'--{b}\r\nContent-Disposition: form-data; name="{file_field}"; filename="{filename}"\r\n'
        f"Content-Type: {ctype}\r\n\r\n".encode() + content + b"\r\n"
    )
    parts.append(f"--{b}--\r\n".encode())
    return b"".join(parts), f"multipart/form-data; boundary={b}"


def call(req: urllib.request.Request, retries: int = 5) -> dict:
    for attempt in range(retries):
        try:
            with urllib.request.urlopen(req, timeout=120) as r:
                return json.loads(r.read().decode() or "{}")
        except urllib.error.HTTPError as e:
            detail = e.read().decode(errors="replace")
            if e.code in (429, 500, 502, 503) and attempt < retries - 1:
                time.sleep(2 ** attempt * 2)  # backoff
                continue
            raise SystemExit(f"HTTP {e.code} em {req.full_url}: {detail}")
    raise SystemExit("falhou apos varias tentativas")


def upload(key: str, creator: dict, n: int, slug: str, path: Path) -> int:
    meta = {
        "assetType": "Model",
        "displayName": f"Brainmon {n:02d} {slug}"[:50],
        "description": "Brainmon (BRAINMON) - modelo blocky gerado no Blender",
        "creationContext": {"creator": creator},
    }
    body, ctype = multipart({"request": json.dumps(meta)}, "fileContent", path.name, path.read_bytes(), "model/gltf-binary")
    req = urllib.request.Request(f"{API}/assets", data=body, method="POST", headers={"x-api-key": key, "Content-Type": ctype})
    op = call(req)["path"]  # "operations/<id>"
    for _ in range(60):  # ate ~2 min
        time.sleep(2)
        res = call(urllib.request.Request(f"{API}/{op}", headers={"x-api-key": key}))
        if res.get("done"):
            if "response" in res:
                return int(res["response"]["assetId"])
            raise SystemExit(f"upload recusado ({n} {slug}): {res.get('error') or res}")
    raise SystemExit(f"timeout esperando a operacao {op} ({n} {slug})")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--only", type=int, nargs="*")
    a = ap.parse_args()

    jobs = []
    for d in sorted(MODELS.iterdir()):
        m = re.match(r"(\d+)_(.+)", d.name)
        glb = d / f"brainmon_{m.group(1)}.glb" if m else None
        if m and glb.exists():
            jobs.append((int(m.group(1)), m.group(2), glb))
    if a.only:
        jobs = [j for j in jobs if j[0] in a.only]

    ids = load_existing()
    todo = [j for j in jobs if j[0] not in ids]
    print(f"{len(jobs)} modelos, {len(jobs) - len(todo)} ja enviados, {len(todo)} a enviar")
    if a.dry_run:
        for n, slug, glb in todo:
            print(f"  {n:02d} {slug}  ({glb.stat().st_size // 1024} KB)")
        return

    key = os.environ.get("ROBLOX_API_KEY")
    user, group = os.environ.get("ROBLOX_USER_ID"), os.environ.get("ROBLOX_GROUP_ID")
    if not key or not (user or group):
        sys.exit("Defina ROBLOX_API_KEY e ROBLOX_USER_ID (ou ROBLOX_GROUP_ID).")
    creator = {"groupId": group} if group else {"userId": user}

    for n, slug, glb in todo:
        ids[n] = upload(key, creator, n, slug, glb)
        save(ids)  # grava a cada modelo: se cair no meio, retoma
        print(f"  {n:02d} {slug} -> {ids[n]}")
        time.sleep(1)
    print("pronto:", OUT)


if __name__ == "__main__":
    main()
