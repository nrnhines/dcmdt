# test of two capacitors with resistor between them. One of the
# capacitances (C1) varies with a user defined function.
# Gnd --)|--o--\/\/\/--o--|(---Gnd
#       C1  V1    R    V2 C2
# Steady state is V1 = V2
# Intuition is that (Q1=C1*V1) + (Q2=C2*V2) is conserved
#
# Charge conservation at forcing function on/off discontinuities is
# managed by events initiated below by an FInitializeHandler

from neuron import h, gui
from math import pi, sin, cos


def model():
    # ss = [h.Section(name="s"+str(i)) for i in range(2)]
    h("create s[2]")  # avoid some bugs with GUI + python sections
    ss = [h.s[i] for i in range(2)]
    for s in ss:
        s.L = 10
        s.diam = 10
        s.cm = 1
    s = ss[0]
    ss[1].connect(s(1.0))
    return ss


# -------------------
# Begin dcdtplay implementation option
# -------------------

# parameters for capacitance forcing
c1 = 1.0  # uF/cm2
c2 = 0.5  # uF/cm2
w = 1  # /ms
tbegin = 1.0  # ms
tdur = 2.75  # ms
tstep = 0.025  # ms

# The play vectors
tvec = h.Vector()
cmvec = h.Vector()
dcdtvec = h.Vector()


def select_dcdt_play(s):
    s.insert("dcdtplay")
    cmvec.play(s(0.5)._ref_cm, tvec, 1)
    dcdtvec.play(s(0.5).dcdtplay._ref_dc, tvec, 1)
    fillplay()
    # Handle on/off discontinuities
    fih = h.FInitializeHandler(playdiscon)
    return fih  # must keep alive by saving return value


# capacitance forcing function
def cm(t):
    if t >= tbegin and t <= (tbegin + tdur):
        return c1 + c2 * sin(2 * pi * w * (t - tbegin))
    else:
        return c1


# capacitance derivative of above cm(t)
def dcmdt(t):
    if t >= tbegin and t <= (tbegin + tdur):
        return c2 * 2 * pi * w * cos(2 * pi * w * (t - tbegin))
    else:
        return 0.0


# Fill the play vectors
def fillplay():
    tfinish = tbegin + tdur
    tvec.indgen(tbegin, tfinish, tstep)
    # constant before tbegin
    tvec.insrt(0, tbegin)
    tvec.insrt(0, 0)
    cmvec.resize(0)
    dcdtvec.resize(0)
    for t in tvec:
        cmvec.append(cm(t))
        dcdtvec.append(dcmdt(t))
    # constant before tbegin
    cmvec[0] = cmvec[1] = c1
    dcdtvec[0] = dcdtvec[1] = 0.0
    # constant after tfinish
    for t in [tfinish, 1e5]:
        tvec.append(t)
        cmvec.append(c1)
        dcdtvec.append(0)


def discon():
    global ss
    if h.t < tbegin + tdur:
        h.cvode.event(tbegin + tdur, discon)
    eps = 1e-10
    seg = ss[0](0.5)
    qbefore = cm(h.t - eps) * seg.v
    seg.v = qbefore / cm(h.t + eps)
    if h.cvode.active():
        h.cvode.re_init()


def playdiscon():
    tstop = tbegin + tdur
    fillplay()  # parameters might have changed
    h.cvode.event(tbegin, discon)


# -------------------
# End dcdtplay option
# -------------------

import sys

parms = sys.modules[__name__]


def parm_panel():
    h.xpanel("Play parameters")
    for name in ["c1", "c2", "w", "tbegin", "tdur", "tstep"]:
        h.xvalue(name, (parms, name), 1, fillplay)
    h.xpanel()


ss = model()
cmech = select_dcdt_play(ss[0])
h.load_file("dcdt_play.ses")
parm_panel()
h.run()
