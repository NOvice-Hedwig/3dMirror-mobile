from pydantic import BaseModel, Field, EmailStr
from typing import Optional
from datetime import datetime


class BodyDataIn(BaseModel):
    weight_kg:    float         = Field(..., gt=20, lt=300)
    body_fat_pct: Optional[float] = Field(None, ge=3, le=70)
    waist_cm:     Optional[float] = Field(None, ge=40, le=200)
    hip_cm:       Optional[float] = None
    lean_mass_kg: Optional[float] = None
    fat_mass_kg:  Optional[float] = None


class ActivityDataIn(BaseModel):
    workout_type: str            = "rest"
    duration_min: Optional[int]  = Field(None, ge=1, le=600)
    intensity:    Optional[str]  = None
    steps:        Optional[int]  = None


class AvatarParamsIn(BaseModel):
    height_norm:      float
    weight_norm:      float
    body_fat_norm:    float
    waist_norm:       float
    hip_norm:         float
    shoulder_norm:    float
    muscle_norm:      float
    gender:           str
    lighting_profile: str = "studio_minimal"


class SessionIn(BaseModel):
    user_id:       str
    body_data:     BodyDataIn
    avatar_params: AvatarParamsIn
    activity_data: Optional[ActivityDataIn] = None
    thumbnail_url: Optional[str]            = None


class SessionOut(BaseModel):
    id:            str
    user_id:       str
    created_at:    datetime
    body_data:     dict
    avatar_params: dict
    activity_data: Optional[dict] = None
    thumbnail_url: Optional[str]  = None


class PhotoOut(BaseModel):
    id:           str
    user_id:      str
    session_id:   Optional[str]  = None
    angle:        str
    file_path:    str
    llm_analysis: Optional[dict] = None
    created_at:   datetime


class BodyAnalysisResult(BaseModel):
    shoulder_width_norm:  Optional[float] = None
    waist_norm:           Optional[float] = None
    hip_norm:             Optional[float] = None
    limb_proportion_norm: Optional[float] = None
