FROM python:3.15-alpine
WORKDIR /app
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/
COPY src src
COPY pyproject.toml pyproject.toml
COPY uv.lock uv.lock

RUN uv sync --frozen
ENV PYTHONPATH=src
RUN uv run src/manage.py collectstatic --noinput
EXPOSE 8000
CMD ["uv", "run", "gunicorn", "core.wsgi:application", "--bind", "0.0.0.0:8000"]