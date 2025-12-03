FROM ruby:3.4.4 AS builder

ENV RAILS_ENV=production \
    NODE_OPTIONS=--max_old_space_size=4096 \
    BUNDLE_WITHOUT="development test" \
    BUNDLE_DEPLOYMENT=true

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

# Instalar PNPM
RUN npm install -g pnpm

WORKDIR /app
COPY . /app

# Bundler
RUN gem install bundler -v 2.5.16
RUN bundle config set without 'development test'
RUN bundle install --jobs 4 --retry 3

# PNPM installs
RUN pnpm install
RUN pnpm build

# Pré-compilar assets Rails
RUN bundle exec rake assets:precompile

FROM ruby:3.4.4

ENV RAILS_ENV=production

WORKDIR /app

COPY --from=builder /app /app

EXPOSE 3000
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
