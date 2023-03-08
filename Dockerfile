FROM python:latest

ENV POETRY_HOME=/opt/poetry \
    PYTHONFAULTHANDLER=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONHASHSEED=random \
    PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    PIP_DEFAULT_TIMEOUT=100 \
    POETRY_VIRTUALENVS_CREATE=false

RUN set -eux \
    && apt-get update \
    && apt-get install -y \
        python-dev \
        build-essential \
        curl

RUN curl -sSL https://install.python-poetry.org | python3 -

WORKDIR /app

COPY poetry.lock pyproject.toml /app/

RUN /opt/poetry/bin/poetry install

COPY . /app/

EXPOSE 6000
