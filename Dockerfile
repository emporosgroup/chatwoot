FROM ruby:3.4.4 AS builder

ENV RAILS_ENV=production \
    NODE_OPTIONS=--max_old_space_size=4096 \
    BUNDLE_WITHOUT="development test" \
    BUNDLE_DEPLOYMENT=true

# ---- System Packages ----
RUN apt-get update -qq && apt-get install -y \
  build-essential \
  libpq-dev \
  libvips \
  curl \
  gnupg2 \
  git \
  nodejs \
  npm && \
  apt-get clean

# Install PNPM
RUN npm install -g pnpm

WORKDIR /app
COPY . /app

# Ruby deps
RUN gem install bundler -v 2.5.16
RUN bundle install --jobs 4 --retry 3

# JS deps
RUN pnpm install

# 🔥 PULAR PRECOMPILE para evitar erro
RUN echo "Skipping assets precompile during Docker build"

# ---------------- FINAL IMAGE -------------------
FROM ruby:3.4.4

ENV RAILS_ENV=production \
    RAILS_SERVE_STATIC_FILES=true \
    RAILS_LOG_TO_STDOUT=true

WORKDIR /app
COPY --from=builder /app /app

EXPOSE 3000
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
