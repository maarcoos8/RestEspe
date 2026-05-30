from fastapi import APIRouter
from fastapi.responses import HTMLResponse

router = APIRouter(prefix="/deeplink", tags=["DeepLink"])


@router.get("/establecimiento/{id_establecimiento}", response_class=HTMLResponse)
def abrir_establecimiento(id_establecimiento: int):
    """Página intermedia para abrir la app por deep link con fallback web.

    Intenta abrir PinFood mediante esquema `pinfood://`. Si la app no está
    instalada, muestra un mensaje indicando que se necesita PinFood.
    """
    deep_link = f"pinfood://establecimiento/{id_establecimiento}"

    html = f"""
<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Abrir en PinFood</title>
  <style>
    :root {{
      --green: #008A45;
      --bg: #f7f4ee;
      --text: #2f3337;
      --muted: #6b7280;
    }}
    body {{
      margin: 0;
      min-height: 100vh;
      font-family: "Segoe UI", Tahoma, Geneva, Verdana, sans-serif;
      color: var(--text);
      background: radial-gradient(circle at top right, #ffffff 0%, var(--bg) 65%);
      display: grid;
      place-items: center;
      padding: 24px;
      box-sizing: border-box;
    }}
    .card {{
      width: min(520px, 100%);
      background: white;
      border-radius: 16px;
      padding: 28px;
      box-shadow: 0 12px 30px rgba(0, 0, 0, 0.08);
      border: 1px solid rgba(0, 0, 0, 0.06);
    }}
    h1 {{
      margin: 0 0 8px;
      font-size: 1.45rem;
    }}
    p {{
      margin: 0;
      line-height: 1.5;
      color: var(--muted);
    }}
    .actions {{
      margin-top: 20px;
      display: flex;
      gap: 12px;
      flex-wrap: wrap;
    }}
    a.button {{
      text-decoration: none;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      border-radius: 10px;
      padding: 10px 14px;
      background: var(--green);
      color: white;
      font-weight: 600;
    }}
    .small {{
      margin-top: 14px;
      font-size: .92rem;
      color: var(--muted);
    }}
  </style>
</head>
<body>
  <main class="card" role="main">
    <h1>Abrir establecimiento en PinFood</h1>
    <p>Estamos intentando abrir la aplicación PinFood con el establecimiento compartido.</p>
    <p class="small" id="fallback">Si no se abrió automáticamente, necesitas tener instalada la app PinFood en tu dispositivo.</p>
    <div class="actions">
      <a class="button" href="{deep_link}">Abrir en PinFood</a>
    </div>
  </main>
  <script>
    window.location.href = "{deep_link}";
  </script>
</body>
</html>
"""

    return HTMLResponse(content=html)
