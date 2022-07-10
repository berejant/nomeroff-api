# syntax = docker/dockerfile:experimental
FROM tensorflow/tensorflow:2.9.1
ARG VERSION=3.1.0
ARG TZ=Europe/Kiev
ARG TEST_IMAGE_URL=https://raw.githubusercontent.com/ria-com/nomeroff-net/v3.1.0/data/examples/oneline_images/example1.jpeg
ARG TEST_IMAGE_EXPECTED=AC4921CB

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN --mount=type=cache,mode=0755,target=/var/cache/apt \
    apt update && \
    apt install -y git gcc libglib2.0-0 libgl1-mesa-glx libturbojpeg \
    && rm -rf /var/lib/apt/lists/*
RUN /usr/bin/python3 -m pip install --upgrade pip
RUN --mount=type=cache,mode=0755,target=/root/.cache/pip \
    curl --fail --output requirements.txt \
    https://raw.githubusercontent.com/ria-com/nomeroff-net/v${VERSION}/requirements.txt && \
    pip install -r requirements.txt && rm requirements.txt
RUN pip install https://github.com/ria-com/nomeroff-net/archive/refs/tags/v${VERSION}.zip

ENV PYTHONWARNINGS="ignore"
# initial run and load clovaai/CRAFT-pytorch and ultralytics/yolov5, AutoShape, models.
RUN python -c "from nomeroff_net import pipeline; pipeline('number_plate_detection_and_reading')"


# test that recognize works fine
RUN curl --fail --output 1.jpg "${TEST_IMAGE_URL}" \
    && python -c "from nomeroff_net import pipeline; \
     print(pipeline('number_plate_detection_and_reading', image_loader='turbo')(['/1.jpg'])[0][-1][0]);" \
     | grep "${TEST_IMAGE_EXPECTED}" \
   && rm 1.jpg

COPY http_server.py /http_server.py

EXPOSE 8080

ENTRYPOINT ["/http_server.py"]
HEALTHCHECK --interval=20s --timeout=15s --start-period=20s \
  CMD curl -I --retry-max-time 10 --connect-timeout 3 --max-time 3 --retry 3 --fail http://localhost:8080 || \
      bash -c 'kill -15 1 && (sleep 2; kill -9 1)'
