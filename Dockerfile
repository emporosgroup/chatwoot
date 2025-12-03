FROM ruby:3.2.2 AS builder

ENV RAILS_ENV=production \
    NODE_OPTIONS=--max_old_space_size=4096 \
    BUNDLE_WITHOUT="development test" \
    BUNDLE_DEPLOYMENT=true

# Install required system packages
RUN apt-get update && \
    apt-get install -y build-essential nodejs npm curl gnupg libpq-dev git && \
    npm install --global yarn && \
    apt-get clean

WORKDIR /app

# Copy application code
COPY . /app

# Install Ruby dependencies
RUN bundle install --jobs 4

# Install JS packages
RUN yarn install --frozen-lockfile

# Precompile assets
RUN bundle exec rails assets:precompile

# ----------------------------
# Runtime Image
# ----------------------------
FROM ruby:3.2.2-slim

ENV RAILS_ENV=production \
    NODE_ENV=production \
    MALLOC_ARENA_MAX=2

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y libpq5 curl && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy built app
COPY --from=builder /app /app

# Expose default Chatwoot port
EXPOSE 3000

# Entrypoint
CMD ["bundle", "exec", "rails", "s", "-b", "0.0.0.0"]
