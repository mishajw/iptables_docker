FROM python:3.6-alpine

WORKDIR web
RUN echo "Hello, world!" >> index.html
CMD ["python", "-m", "http.server"]

