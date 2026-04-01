FROM dart:stable AS base

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    gdal-bin \
    libgdal-dev \
    clang \
    libclang-dev \
    pkg-config \
    lcov \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy only pubspec first for dependency caching.
COPY ./pubspec.yaml ./pubspec.yaml
RUN dart pub get

# Copy the rest of the repository.
COPY . .

# Runtime image for tests that need GDAL shared libraries.
FROM base AS native-test-base

# Extended image for binding generation via ffigen/libclang.
FROM native-test-base AS bindings-base

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
RUN lcov --summary coverage/lcov.info    

# Coverage threshold check.
FROM coverage AS coverage-check
ARG COVERAGE_MIN=95
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


# Doc — generate API documentation into doc/api/.
#
# Generate + extract:
#   docker build --target doc -t gdal_dart:doc .
#   docker run --rm gdal_dart:doc | tar -xzf -
FROM base AS doc
RUN dart doc
RUN test -f doc/api/index.html && echo "API docs generated: $(find doc/api -name '*.html' | wc -l) HTML files"
RUN tar -czf /doc-api.tar.gz doc/api
ENTRYPOINT ["cat", "/doc-api.tar.gz"]

# Bindings generation.
FROM bindings-base AS bindings
RUN dart run ffigen

# Publish dry-run.
FROM base AS publish-check
RUN dart pub publish --dry-run
