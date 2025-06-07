import logging
from datetime import timedelta
from fastapi import APIRouter, Depends, HTTPException, status, Request
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from backend.app.core.security import verify_password, get_password_hash, create_access_token, get_current_user
from backend.app.core.config import settings
from backend.app.database.database import get_db
from backend.app.models.user import User, Gender, Goal, Diet, Experience, WorkoutFrequency
from pydantic import BaseModel, EmailStr, confloat

logger = logging.getLogger(__name__)
router = APIRouter()
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

class UserCreate(BaseModel):
    email: EmailStr
    password: str
    name: str | None = None
    gender: Gender | None = None
    height: confloat(ge=30, le=250) | None = None  # рост в см
    weight: confloat(ge=10, le=300) | None = None  # вес в кг
    goal: Goal | None = None
    target_weight: confloat(ge=10, le=300) | None = None  # целевой вес в кг
    diet: Diet | None = None
    experience: Experience | None = None
    workout_frequency: WorkoutFrequency | None = None

class Token(BaseModel):
    access_token: str
    token_type: str

class UserResponse(BaseModel):
    id: int
    email: str
    name: str | None
    is_active: bool
    gender: Gender | None
    height: float | None
    weight: float | None
    goal: Goal | None
    target_weight: float | None
    diet: Diet | None
    experience: Experience | None
    workout_frequency: WorkoutFrequency | None

    class Config:
        from_attributes = True

class LoginRequest(BaseModel):
    email: str
    password: str

@router.post("/register", response_model=UserResponse)
def register(user: UserCreate, db: Session = Depends(get_db)):
    db_user = db.query(User).filter(User.email == user.email).first()
    if db_user:
        raise HTTPException(
            status_code=400,
            detail="Email already registered"
        )
    
    hashed_password = get_password_hash(user.password)
    db_user = User(
        email=user.email,
        hashed_password=hashed_password,
        name=user.name,
        is_active=True,
        gender=user.gender,
        height=user.height,
        weight=user.weight,
        goal=user.goal,
        target_weight=user.target_weight,
        diet=user.diet,
        experience=user.experience,
        workout_frequency=user.workout_frequency
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    
    return UserResponse(
        id=db_user.id,
        email=db_user.email,
        name=db_user.name,
        is_active=db_user.is_active,
        gender=db_user.gender,
        height=db_user.height,
        weight=db_user.weight,
        goal=db_user.goal,
        target_weight=db_user.target_weight,
        diet=db_user.diet,
        experience=db_user.experience,
        workout_frequency=db_user.workout_frequency
    )

@router.post("/token", response_model=Token)
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == form_data.username).first()
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.email}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

@router.post("/login", response_model=Token)
async def login_with_json(request: Request, login_data: LoginRequest, db: Session = Depends(get_db)):
    logger.info(f"Login attempt for email: {login_data.email}")
    
    try:
        # Используем select для оптимизации запроса
        user = db.query(User).filter(User.email == login_data.email).first()
        
        if not user:
            logger.warning(f"Login failed: User not found for email {login_data.email}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Incorrect email or password",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        # Проверяем пароль
        if not verify_password(login_data.password, user.hashed_password):
            logger.warning(f"Login failed: Invalid password for email {login_data.email}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Incorrect email or password",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        # Создаем токен с минимальным временем жизни
        access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={"sub": user.email}, expires_delta=access_token_expires
        )
        
        logger.info(f"Login successful for email: {login_data.email}")
        return {"access_token": access_token, "token_type": "bearer"}
        
    except Exception as e:
        logger.error(f"Unexpected error during login: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error"
        )
    finally:
        # Закрываем сессию сразу после использования
        db.close()

@router.get("/check-email")
def check_email(email: str, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == email).first()
    return {"exists": user is not None}

@router.get("/me", response_model=UserResponse)
async def read_users_me(current_user: User = Depends(get_current_user)):
    return current_user
