#!/usr/bin/python3

import argparse
from os import environ
from subprocess import run

from serial.tools import list_ports

from pathlib import Path

def get_port():
    found_devices = 0
    device_name = ""

    for port in list_ports.comports():
        if (port.description.find("Elbert V2")):
            found_devices += 1
            device_name = port.device

    if found_devices > 1:
        print ("ERROR: Found more than one Elbert V2, please provide port, i.e: ELBERT_PORT=/dev/ttyACM1 make flash_elbert_v2")
        return None
    if found_devices == 0:
        print ("ERROR: Can't find Elbert V2, please provide port manually, i.e: ELBERT_PORT=/dev/ttyACM1 make flash_elbert_v2")
        return None
    return device_name

try:
    port = environ["ELBERT_PORT"]
    print ("ELBERT_PORT: " + environ["ELBERT_PORT"])
except KeyError:
    port = get_port()

parser = argparse.ArgumentParser(description = "Script for detection and flashing ElbertV2 FPGA board")
parser.add_argument("--binary", dest="binary", action="store", help="Path to binary file", required=True)
args, rest = parser.parse_known_args()

my_path = Path(__file__).parent
if port is not None:
    print ("Flasing " + args.binary + ", to: " + port)
    run(["python3", my_path / "elbertconfig.py", port, args.binary])

