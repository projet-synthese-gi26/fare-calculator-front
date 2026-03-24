# =============================================================
# DOCKERFILE — FRONTEND VITE / REACT
# Pas de Nginx. Le container sert l'app via "vite preview"
# (équivalent prod de "npm run dev", sert le /dist buildé).
# La terminaison HTTP / reverse proxy est gérée par le
# docker-compose infra du serveur.
# =============================================================

# -----------------------------------------------------------
# STAGE 1 — builder
# -----------------------------------------------------------
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci --prefer-offline

COPY . .

# --- VITE_* injectées via --build-arg au moment du build ---
ARG VITE_API_BASE_URL
ARG VITE_API_KEY
ARG VITE_MAPBOX_TOKEN
ARG VITE_MAPBOX_STYLE
ARG VITE_NOMINATIM_BASE_URL
ARG VITE_OPENMETEO_BASE_URL
ARG VITE_MODE=production
ARG VITE_ENABLE_GEOLOCATION=true
ARG VITE_CACHE_TTL=3600000
ARG VITE_API_TIMEOUT=30000
ARG VITE_GA_ID
ARG VITE_FIREBASE_API_KEY
ARG VITE_FIREBASE_AUTH_DOMAIN
ARG VITE_FIREBASE_PROJECT_ID
ARG VITE_FIREBASE_STORAGE_BUCKET
ARG VITE_FIREBASE_MESSAGING_SENDER_ID
ARG VITE_FIREBASE_APP_ID
ARG VITE_FIREBASE_BILLING_ENABLED=false

RUN printf "VITE_API_BASE_URL=%s\n\
VITE_API_KEY=%s\n\
VITE_MAPBOX_TOKEN=%s\n\
VITE_MAPBOX_STYLE=%s\n\
VITE_NOMINATIM_BASE_URL=%s\n\
VITE_OPENMETEO_BASE_URL=%s\n\
VITE_MODE=%s\n\
VITE_ENABLE_GEOLOCATION=%s\n\
VITE_CACHE_TTL=%s\n\
VITE_API_TIMEOUT=%s\n\
VITE_GA_ID=%s\n\
VITE_FIREBASE_API_KEY=%s\n\
VITE_FIREBASE_AUTH_DOMAIN=%s\n\
VITE_FIREBASE_PROJECT_ID=%s\n\
VITE_FIREBASE_STORAGE_BUCKET=%s\n\
VITE_FIREBASE_MESSAGING_SENDER_ID=%s\n\
VITE_FIREBASE_APP_ID=%s\n\
VITE_FIREBASE_BILLING_ENABLED=%s\n" \
  "$VITE_API_BASE_URL" "$VITE_API_KEY" "$VITE_MAPBOX_TOKEN" \
  "$VITE_MAPBOX_STYLE" "$VITE_NOMINATIM_BASE_URL" "$VITE_OPENMETEO_BASE_URL" \
  "$VITE_MODE" "$VITE_ENABLE_GEOLOCATION" "$VITE_CACHE_TTL" \
  "$VITE_API_TIMEOUT" "$VITE_GA_ID" "$VITE_FIREBASE_API_KEY" \
  "$VITE_FIREBASE_AUTH_DOMAIN" "$VITE_FIREBASE_PROJECT_ID" \
  "$VITE_FIREBASE_STORAGE_BUCKET" "$VITE_FIREBASE_MESSAGING_SENDER_ID" \
  "$VITE_FIREBASE_APP_ID" "$VITE_FIREBASE_BILLING_ENABLED" \
  > .env

RUN npm run build

# -----------------------------------------------------------
# STAGE 2 — runner
# Node Alpine léger. On garde node_modules uniquement pour
# vite preview (vite doit être dans les devDependencies).
# -----------------------------------------------------------
FROM node:20-alpine AS runner

WORKDIR /app

COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/vite.config.js ./vite.config.js

EXPOSE 3000

#HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
#  CMD wget -qO- http://localhost:3000/ || exit 1

# vite preview sert le /dist buildé sur le port 4173
CMD ["npx", "vite", "preview", "--host", "0.0.0.0", "--port", "3000"]