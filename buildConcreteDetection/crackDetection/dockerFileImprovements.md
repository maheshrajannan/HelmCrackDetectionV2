# Dockerfile Improvements — crackDetection

Improved version of `dockerfile` with rationale. Original is unchanged.

## Improved Dockerfile

```dockerfile
# Python 3.12 slim — current stable, smaller attack surface
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

# Only runtime lib needed by opencv-python-headless
# (build-essential and libgl1 removed — wheels need no compiler, headless needs no libGL)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy requirements first for layer caching — deps reinstall only when this file changes
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY crackDetection.py .

# Pre-create watch folders so the script doesn't crash when no volume is mounted
RUN mkdir -p uploads/images/completed

# Run as non-root (satisfies K8s runAsNonRoot policies)
RUN useradd --create-home --uid 1000 appuser \
    && chown -R appuser:appuser /app
USER appuser

# No EXPOSE — this is a folder-polling background worker, it listens on no port

CMD ["python", "crackDetection.py"]
```

## Recommended requirements.txt (pinned)

```
numpy==1.26.4
opencv-python-headless==4.10.0.84
```

## Changes vs. original

| # | Change | Why |
|---|--------|-----|
| 1 | Removed `build-essential` | numpy/opencv install as prebuilt wheels; no compiler needed. Saves ~250MB. |
| 2 | Removed `libgl1` | Only full `opencv-python` links libGL; headless variant doesn't. |
| 3 | Use `requirements.txt` with pinned versions | Reproducible builds; better layer caching than inline `pip install`. |
| 4 | `python:3.10-slim` → `python:3.12-slim` | 3.10 is aging; Python has no LTS releases. |
| 5 | `RUN mkdir -p uploads/images/completed` | Script lists `uploads/images` at startup — crashes with `FileNotFoundError` if no volume mounted. |
| 6 | Removed `EXPOSE 8081` | Misleading — the script opens no port. |
| 7 | Added non-root `USER appuser` | Container security baseline; aligns with K8s `runAsNonRoot`. |
| 8 | Consolidated `ENV`, added `PIP_NO_CACHE_DIR` | Fewer layers; no pip cache in image. |
| 9 | Removed commented-out dead code | Git history preserves old versions. |

Net effect: image size drops from ~1GB to ~300MB, faster builds, no crash without a mounted volume, passes non-root pod security policies.

## Follow-ups (app code, not Dockerfile)

- `crackDetection.py` logs to `error.log` inside the container — switch to stdout logging for K8s (`kubectl logs` / log collectors).
- `.dockerignore` paths (`/uploads/...`) don't match older `upload/` references — harmless now, worth normalizing.
