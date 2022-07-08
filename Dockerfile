FROM tensorflow/tensorflow:2.3.2

ENV TZ=Europe/Kiev
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt update && apt install -y git libsm6 libxrender1 libgl1 libfontconfig1 libxtst6 libturbojpeg

WORKDIR /
RUN git clone  https://github.com/ria-com/nomeroff-net.git \
  && cd nomeroff-net/ \
  && sed -i 's/^tensorflow/#&/' requirements.txt \
  && pip install --no-cache-dir -r requirements.txt \
  && cd ../

COPY init.py /init.py
RUN /init.py && rm /init.py
COPY http_server.py /http_server.py

EXPOSE 8020

ENTRYPOINT ["/http_server.py"]
HEALTHCHECK CMD curl -I --connect-timeout 3 --max-time 5 --fail http://localhost:8020 || exit 1
