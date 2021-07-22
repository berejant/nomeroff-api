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
