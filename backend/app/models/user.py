from sqlalchemy import Boolean, Column, Integer, String, DateTime, Enum, Float
from datetime import datetime
from backend.app.database.database import Base
import enum

class Gender(str, enum.Enum):
    MALE = "мужской"
    FEMALE = "женский"

class Goal(str, enum.Enum):
    LOSE_WEIGHT = "похудеть"
    GAIN_MUSCLE = "набрать мышечную массу"
    GET_ENERGY = "зарядиться энергией"

class Diet(str, enum.Enum):
    NO_DIET = "без диеты"
    VEGAN = "веганская"
    VEGETARIAN = "вегетарианская"

class Experience(str, enum.Enum):
    NO_EXPERIENCE = "нету"
    LESS_THAN_YEAR = "меньше года"
    ONE_TO_THREE = "год-три"
    MORE_THAN_THREE = "более 3 лет"

class WorkoutFrequency(str, enum.Enum):
    ONE_TO_TWO = "1-2"
    THREE_TO_FOUR = "3-4"
    FOUR_TO_FIVE = "4-5"
    SIX_TO_SEVEN = "6-7"

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    name = Column(String, nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Новые поля для фитнес-профиля
    gender = Column(Enum(Gender), nullable=True)
    height = Column(Float, nullable=True)  # в сантиметрах
    weight = Column(Float, nullable=True)  # в килограммах
    goal = Column(Enum(Goal), nullable=True)
    target_weight = Column(Float, nullable=True)  # целевой вес в килограммах
    diet = Column(Enum(Diet), nullable=True)
    experience = Column(Enum(Experience), nullable=True)
    workout_frequency = Column(Enum(WorkoutFrequency), nullable=True)
