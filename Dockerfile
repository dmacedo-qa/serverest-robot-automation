# Test runner image: Python + the pinned Robot Framework stack. Used by `docker compose run tests`.
FROM python:3.13.15-slim-trixie@sha256:7c61056e61ac89e852de05f3dc6fa51a6dd2181797bceed46aa725dd7cb2cd3b

WORKDIR /suite
ENV PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY config ./config
COPY data ./data
COPY libraries ./libraries
COPY resources ./resources
COPY tests ./tests

ENTRYPOINT ["robot", "--argumentfile", "config/robot.args"]
CMD ["tests"]
