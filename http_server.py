#!/usr/bin/env python3
import sys
import signal
import logging
import threading
import time
from http.server import HTTPServer
from http.server import BaseHTTPRequestHandler

from nomeroff_net import pipeline
from nomeroff_net.image_loaders.turbo_loader import TurboImageLoader
from turbojpeg import TJPF_RGB


class TurboBytesImageLoader(TurboImageLoader):
    def load(self, img_bytes):
        return self.jpeg.decode(img_bytes, TJPF_RGB)


number_plate_detection_and_reading = pipeline("number_plate_detection_and_reading", image_loader=TurboBytesImageLoader)
lock = threading.Lock()


class SimpleHTTPRequestHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        content_len = int(self.headers.get('content-length', 0))
        post_body = self.rfile.read(content_len)

        texts = number_plate_detection_and_reading([post_body])[0][-1]

        self.send_response(200)
        if texts:
            number = bytes(texts[0], encoding='utf8')
            self.send_header('Content-type', 'text/plain; charset=utf8')
            self.send_header('Content-Length', str(len(number)))
            self.end_headers()
            self.wfile.write(number)

    def do_HEAD(self):
        self.send_response(200)
        self.end_headers()


if __name__ == '__main__':
    logger = logging.getLogger(__name__)
    server = HTTPServer(('0.0.0.0', 8080), SimpleHTTPRequestHandler)

    def stop(signal_number, frame):
        server.shutdown()
        sys.exit(0)

    signal.signal(signal.SIGTERM, stop)

    # run server in daemon thread. When the main thread finishes
    # the daemon will also be killed.
    thread = threading.Thread(target=server.serve_forever)
    thread.daemon = True
    thread.start()
    logger.info("HTTP Server started")

    while True:
        time.sleep(1)
