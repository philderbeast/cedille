module is-free where

open import lib

open import cedille-types
open import ctxt
open import syntax-util

is-free-e = 𝔹
check-erased = tt
skip-erased = ff

is-free-in-term : is-free-e → var → term → 𝔹
is-free-in-type : is-free-e → var → type → 𝔹
is-free-in-kind : is-free-e → var → kind → 𝔹
is-free-in-tk : is-free-e → var → tk → 𝔹
is-free-in-liftingType : is-free-e → var → liftingType → 𝔹

is-free-in-term ce x (App t Erased t') = is-free-in-term ce x t || (ce && is-free-in-term ce x t')
is-free-in-term ce x (App t NotErased t') = is-free-in-term ce x t || is-free-in-term ce x t'
is-free-in-term ce x (AppTp t tp) = is-free-in-term ce x t || (ce && is-free-in-type ce x tp)
is-free-in-term ce x (Hole x₁) = ff
is-free-in-term ce x (Lam _ b _ x' NoClass t) = ~ (x =string x') && is-free-in-term ce x t
is-free-in-term ce x (Lam _ b _ x' (SomeClass atk) t) = (ce && is-free-in-tk ce x atk) || (~ (x =string x') && is-free-in-term ce x t)
is-free-in-term ce x (Parens x₁ t x₂) = is-free-in-term ce x t
is-free-in-term ce x (Var _ x') = x =string x'

is-free-in-type ce x (Abs _ _ _ x' atk t) = is-free-in-tk ce x atk || (~ (x =string x') && is-free-in-type ce x t)
is-free-in-type ce x (Iota _ x' t) = ~ (x =string x') && is-free-in-type ce x t
is-free-in-type ce x (Lft _ t l) = is-free-in-term ce x t || is-free-in-liftingType ce x l
is-free-in-type ce x (TpApp t t') = is-free-in-type ce x t || is-free-in-type ce x t'
is-free-in-type ce x (TpAppt t t') = is-free-in-type ce x t || is-free-in-term ce x t'
is-free-in-type ce x (TpArrow t t') = is-free-in-type ce x t || is-free-in-type ce x t'
is-free-in-type ce x (TpEq t t') = is-free-in-term ce x t || is-free-in-term ce x t'
is-free-in-type ce x (TpParens x₁ t x₂) = is-free-in-type ce x t
is-free-in-type ce x (TpVar _ x') = x =string x'

is-free-in-kind ce x (KndArrow k k') = is-free-in-kind ce x k || is-free-in-kind ce x k'
is-free-in-kind ce x (KndParens x₁ k x₂) = is-free-in-kind ce x k
is-free-in-kind ce x (KndPi _ _ x' atk k) = is-free-in-tk ce x atk || (~ (x =string x') && is-free-in-kind ce x k)
is-free-in-kind ce x (KndTpArrow t k) = is-free-in-type ce x t || is-free-in-kind ce x k
is-free-in-kind ce x (KndVar _ x') = x =string x'
is-free-in-kind ce x (Star x₁) = ff

is-free-in-tk ce x (Tkt t) = is-free-in-type ce x t
is-free-in-tk ce x (Tkk k) = is-free-in-kind ce x k

is-free-in-liftingType ce x (LiftArrow l l') = is-free-in-liftingType ce x l || is-free-in-liftingType ce x l'
is-free-in-liftingType ce x (LiftParens x₁ l x₂) = is-free-in-liftingType ce x l
is-free-in-liftingType ce x (LiftPi _ x' t l) = is-free-in-type ce x t || (~ (x =string x') && is-free-in-liftingType ce x l)
is-free-in-liftingType ce x (LiftStar x₁) = ff
is-free-in-liftingType ce x (LiftTpArrow t l) = is-free-in-type ce x t || is-free-in-liftingType ce x l

is-free-in : {ed : exprd} → is-free-e → var → ⟦ ed ⟧ → 𝔹
is-free-in{TERM} e x t = is-free-in-term e x t 
is-free-in{TYPE} e x t = is-free-in-type e x t 
is-free-in{KIND} e x t = is-free-in-kind e x t 

abs-tk : lam → var → tk → type → type
abs-tk l x (Tkk k) tp = Abs posinfo-gen All posinfo-gen x (Tkk k) tp
abs-tk ErasedLambda x (Tkt tp') tp = Abs posinfo-gen All posinfo-gen x (Tkt tp') tp
abs-tk KeptLambda x (Tkt tp') tp with is-free-in check-erased x tp 
abs-tk KeptLambda x (Tkt tp') tp | tt = Abs posinfo-gen Pi posinfo-gen x (Tkt tp') tp
abs-tk KeptLambda x (Tkt tp') tp | ff = TpArrow tp' tp

data abs : Set where
  mk-abs : posinfo → binder → posinfo → var → tk → (var-free-in-body : 𝔹) → type → abs

to-abs : type → maybe abs
to-abs (Abs pi b pi' x atk tp) = just (mk-abs pi b pi' x atk (is-free-in-type check-erased x tp) tp)
to-abs (TpArrow tp1 tp2) = just (mk-abs posinfo-gen Pi posinfo-gen dummy-var (Tkt tp1) ff tp2)
to-abs _ = nothing
