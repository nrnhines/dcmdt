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


def select_dcdt(s):
    refcm = s(0.5)._ref_cm
    s.insert("dcdt")
    s(0.5).dcdt._ref_c = refcm
    # handle discontinuities
    fih = h.FInitializeHandler((playdiscon, s(0.5).dcdt))
    return fih


def discon(mech):
    global ss
    tend = mech.tbegin + mech.tdur
    if h.t < tend:
        h.cvode.event(tend, (discon, mech))
    eps = 1e-10
    seg = ss[0](0.5)
    qbefore = mech.cm(h.t - eps) * seg.v
    seg.v = qbefore / mech.cm(h.t + eps)
    h.cvode.re_init()


def playdiscon(mech):
    if h.t == 0:
        h.cvode.event(mech.tbegin, (discon, mech))


ss = model()
fih = select_dcdt(ss[0])
h.load_file("dcdt.ses")
h.run()
