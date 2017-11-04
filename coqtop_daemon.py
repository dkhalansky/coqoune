from coqtop import *
import socket
import os
import sys
sock = socket.socket()
sock.bind(("127.0.0.1", 0))
with open(sys.argv[1], "w") as f:
    f.write(str(sock.getsockname()[1]))
restart_coq()
sys.stdout = open(sys.argv[2], "w")
sys.stderr = sys.stdout
sock.listen(5)
while True:
    (s, a) = sock.accept()
    c = s.recv(0x4000)
    r = eval(c)
    s.send(str(r).encode("utf-8"))
    s.close()
