"""Switch only this isolated lab endpoint between signed BIND and unsigned responder."""
import os
import signal
import subprocess
import time

running = True
def stop(*_):
    global running
    running = False
signal.signal(signal.SIGTERM, stop)
signal.signal(signal.SIGINT, stop)
child = None
mode = None
try:
    while running:
        wanted = "unsigned" if os.path.exists("/run/unsigned") else "signed"
        if wanted != mode:
            if child:
                child.terminate()
                child.wait(timeout=10)
            command = (["python3", "-u", "/lab/unsigned.py"] if wanted == "unsigned" else
                       ["named", "-g", "-u", "root", "-n", "1", "-c", "/etc/bind/named.conf"])
            child = subprocess.Popen(command)
            mode = wanted
            print("AUTHORITY_MODE=" + mode, flush=True)
        if child.poll() is not None:
            raise RuntimeError(f"{mode} process exited: {child.returncode}")
        time.sleep(0.2)
finally:
    if child and child.poll() is None:
        child.terminate()
        child.wait(timeout=10)
