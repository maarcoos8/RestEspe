# Configuracion de SQLAlchemy (Engine y Session)
import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")

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