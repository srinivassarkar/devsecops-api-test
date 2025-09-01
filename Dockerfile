# Multi-stage build for security and size optimization
FROM node:18-alpine AS base

# Install security updates and dumb-init for proper signal handling
RUN apk --no-cache add dumb-init \
    && apk --no-cache upgrade \
    && rm -rf /var/cache/apk/*

# Create non-root user
RUN addgroup -g 1001 -S nodejs \
    && adduser -S nodejs -u 1001

# ============================================
# Dependencies stage
# ============================================
FROM base AS deps

# Set working directory
WORKDIR /app

# Copy package files
COPY --chown=nodejs:nodejs package*.json ./

# Install only production dependencies
RUN npm ci --only=production --no-audit --no-fund \
    && npm cache clean --force

# ============================================
# Build stage (if needed for compilation)
# ============================================
FROM base AS build

WORKDIR /app

# Copy package files
COPY --chown=nodejs:nodejs package*.json ./

# Install all dependencies (including dev for testing)
RUN npm ci --no-audit --no-fund

# Copy source code
COPY --chown=nodejs:nodejs . .

# Run tests
RUN npm test

# ============================================
# Production stage
# ============================================
FROM base AS production

# Set NODE_ENV
ENV NODE_ENV=production
ENV PORT=3000
ENV APP_VERSION=1.0.0

# Set working directory
WORKDIR /app

# Copy production dependencies from deps stage
COPY --from=deps --chown=nodejs:nodejs /app/node_modules ./node_modules

# Copy application code
COPY --chown=nodejs:nodejs app.js ./

# Create package.json with only production info
COPY --chown=nodejs:nodejs package.json ./

# Switch to non-root user
USER nodejs

# Expose port (non-privileged port)
EXPOSE 3000

# Add health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3000/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) })"

# Use dumb-init to handle signals properly
ENTRYPOINT ["dumb-init", "--"]

# Run the application
CMD ["node", "app.js"]

# Add metadata labels
LABEL maintainer="devsecops@example.com"
LABEL version="1.0.0"
LABEL description="Secure Node.js API for DevSecOps demonstration"