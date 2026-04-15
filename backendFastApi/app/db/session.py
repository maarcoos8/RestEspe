# Configuracion de SQLAlchemy (Engine y Session)
import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")

# Validate DATABASE_URL early and give a helpful error message
if not DATABASE_URL:
    raise RuntimeError(
        "DATABASE_URL no está configurada. Añade DATABASE_URL a tu .env o a las variables de entorno. "
        "Ejemplo: DATABASE_URL='postgresql+psycopg://user:pass@localhost:5432/dbname'"
    )

# El engine es el puente real a la base de datos
engine = create_engine(DATABASE_URL)

# Cada vez que llamemos a SessionLocal, tendremos una conexión única
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Dependencia para FastAPI
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()