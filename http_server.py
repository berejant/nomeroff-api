#!/usr/bin/env python3
import os
import sys
from threading import Lock
import warnings
from typing import Optional
from http.server import HTTPServer
from http.server import BaseHTTPRequestHandler
import cv2
import numpy as np
import sys

warnings.filterwarnings('ignore')

# packages will be availables inside DOcker container

lock = Lock()

# NomeroffNet path
NOMEROFF_NET_DIR = os.path.abspath('/nomeroff-net')
sys.path.append(NOMEROFF_NET_DIR)
# Import license plate recognition tools.
from NomeroffNet.YoloV5Detector import Detector
detector = Detector()
detector.load()

from NomeroffNet.BBoxNpPoints import NpPointsCraft, getCvZoneRGB, convertCvZonesRGBtoBGR, reshapePoints
npPointsCraft = NpPointsCraft()
npPointsCraft.load()

from NomeroffNet.OptionsDetector import OptionsDetector
from NomeroffNet.TextDetector import TextDetector

from NomeroffNet import TextDetector
from NomeroffNet import textPostprocessing

# load models
optionsDetector = OptionsDetector()
optionsDetector.load("latest")

textDetector = TextDetector.get_static_module("eu")
textDetector.load("latest")

def detect(image: bytes) -> Optional[str]:
    # Decode JPEG from memory into Numpy array using OpenCV
    img = cv2.imdecode(np.asarray(bytearray(image), dtype=np.uint8), cv2.IMREAD_COLOR)
    # Ensure that only one model is loaded among all threads.
    with lock:
      targetBoxes = detector.detect_bbox(img)
      all_points = npPointsCraft.detect(img, targetBoxes,[5,2,0])

      # cut zones
      zones = convertCvZonesRGBtoBGR([getCvZoneRGB(img, reshapePoints(rect, 1)) for rect in all_points])

      # predict zones attributes
      regionIds, stateIds = optionsDetector.predict(zones)
      regionNames = optionsDetector.getRegionLabels(regionIds)

      # find text with postprocessing by standart
      textArr = textDetector.predict(zones)
      textArr = textPostprocessing(textArr, regionNames)

    return textArr[0] if textArr else None

class SimpleHTTPRequestHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        content_len = int(self.headers.get('content-length', 0))
        post_body = self.rfile.read(content_len)

        number = detect(post_body)

        self.send_response(200)
        if number is not None:
            self.send_header('Content-type', 'text/plain')
            self.send_header('Content-Length', str(len(number)))
            self.end_headers()

            self.wfile.write(bytes(number, encoding='utf8'))

    def do_HEAD(self):
        self.send_response(200)
        self.end_headers()

httpd = HTTPServer(('0.0.0.0', 8020), SimpleHTTPRequestHandler)

httpd.serve_forever()
