# test of two capacitors with resistor between them. One of the
# capacitances (C1) varies with a user defined function.
# Gnd --)|--o--\/\/\/--o--|(---Gnd
#       C1  V1    R    V2 C2
# Steady state is V1 = V2
# Intuition is that (Q1=C1*V1) + (Q2=C2*V2) is conserved
#

from neuron import h, gui


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
    # s.insert("dcdt")
    # s(0.5).dcdt._ref_c = s(0.5)._ref_cm
    cp = h.DcDt(s(0.5))
    cp._ref_c = s(0.5)._ref_cm

    return ss, cp


m = model()

h.load_file("dcdt_pp.ses")
