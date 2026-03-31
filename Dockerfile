FROM dart:stable AS base

WORKDIR /app

# Copy only pubspec first for dependency caching.
COPY ./pubspec.yaml ./pubspec.yaml
RUN dart pub get

# Copy the rest of the repository.
COPY . .

# Runtime image for tests that need GDAL shared libraries.
FROM base AS native-test-base
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        gdal-bin \
        libgdal-dev \
    && rm -rf /var/lib/apt/lists/*

# Extended image for binding generation via ffigen/libclang.
FROM native-test-base AS bindings-base
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        clang \
        libclang-dev \
        pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Analyze.
FROM base AS analyze
RUN dart analyze

# Test.
FROM native-test-base AS test
RUN dart test

# Coverage report.
FROM native-test-base AS coverage
ARG COVERAGE_VERSION=1.15.0
RUN dart pub global activate coverage ${COVERAGE_VERSION}
ENV PATH="/root/.pub-cache/bin:${PATH}"
RUN dart test --coverage=coverage
RUN dart pub global run coverage:format_coverage \
    --packages=.dart_tool/package_config.json \
    --report-on=lib \
    --lcov \
    --in=coverage \
    --out=coverage/lcov.info

# Coverage threshold check.
FROM coverage AS coverage-check
ARG COVERAGE_MIN=80
RUN awk -F'[,:]' -v min="$COVERAGE_MIN" '\
    /^DA:/ { total += 1; if ($3 > 0) hit += 1 } \
    END { \
      if (total == 0) { \
        print "No coverage data found in coverage/lcov.info"; \
        exit 1; \
      } \
      pct = (hit / total) * 100; \
      printf "Line coverage: %.2f%% (threshold %.2f%%)\n", pct, min; \
      if (pct < min) { exit 2 } \
    }' coverage/lcov.info

# Doc.
FROM base AS doc
RUN dart doc

# Bindings generation.
FROM bindings-base AS bindings
RUN dart run ffigen

# Publish dry-run.
FROM base AS publish-check
RUN dart pub publish --dry-run
