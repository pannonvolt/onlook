# Build Onlook web client
FROM oven/bun:1 AS builder

WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV STANDALONE_BUILD=true

COPY . .
RUN bun install --frozen-lockfile

# Railway passes service variables as build arguments.
ARG NEXT_PUBLIC_SUPABASE_URL
ARG NEXT_PUBLIC_SUPABASE_ANON_KEY
ARG NEXT_PUBLIC_SITE_URL
ARG SUPABASE_DATABASE_URL
ARG SUPABASE_SERVICE_ROLE_KEY
ARG OPENROUTER_API_KEY
ARG CSB_API_KEY

RUN cd apps/web/client && bun run build:standalone

# Run only the standalone output; build arguments are not runtime defaults.
FROM oven/bun:1 AS runner

WORKDIR /app
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV HOSTNAME=0.0.0.0
ENV PORT=3000

COPY --from=builder /app/apps/web/client/.next/standalone ./

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD bun -e "fetch('http://localhost:'+process.env.PORT).then(r => r.ok ? process.exit(0) : process.exit(1)).catch(() => process.exit(1))"

CMD ["bun", "apps/web/client/server.js"]
