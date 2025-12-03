FROM ruby:3.2.2 AS builder

ENV RAILS_ENV=production \
    NODE_OPTIONS=--max_old_space_size=4096 \
    BUNDLE_WITHOUT="development test" \
    BUNDLE_DEPLOYMENT=true

# -----------------------------
# Install system packages
# -----------------------------
RUN apt-get update -qq && apt-get install -y \
  build-essential \
  libpq-dev \
  nodejs \
  npm \
  curl \
  gnupg2 \
  git \
  imagemagick \
  libvips && \
  apt-get clean

WORKDIR /app

# -----------------------------
# Copy application
# -----------------------------
COPY . /app

# -----------------------------
# Ruby packages
# -----------------------------
RUN gem install bundler -v 2.5.9
RUN bundle config set without 'development test'
RUN bundle install --jobs 4 --retry 3

# -----------------------------
# JS packages
# -----------------------------
RUN npm install --global yarn
RUN yarn install --network-timeout 600000
RUN yarn build

# -----------------------------
# Precompile assets
# -----------------------------
RUN bundle exec rake assets:precompile

# -----------------------------
# Final stage
# -----------------------------
FROM ruby:3.2.2

ENV RAILS_ENV=production

WORKDIR /app

COPY --from=builder /app /app

EXPOSE 3000

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
