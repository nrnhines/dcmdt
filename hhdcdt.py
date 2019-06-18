from neuron import h, gui

#single compartment hh model
soma = h.Section(name='soma')
soma.L = 5
soma.diam = 100/h.PI/soma.L # 100 um2 area
soma.insert('hhdcdt')
ic = h.IClamp(soma(.5))
ic.delay = 1
ic.dur = 0.1
ic.amp = 0.3

h.newPlotV()
g = h.graphItem

g.exec_menu("Keep Lines")
h.cvode_active(1)
h.cvode.atol(1e-6)

# standard hh
h.run()

# activate the time varying capacitance effect on cm
for sec in h.allsec():
  for seg in sec:
    if True:
      h.setpointer(seg._ref_cm, 'c', seg.hhdcdt)
    else:
      # modern 'setpointer' syntax since
      #NEURON -- VERSION 7.7.1-9-g4ed4067b master (4ed4067b) 2019-06-15
      seg.hhdcdt._ref_c = seg._ref_cm

h.run()

# if the dcdt term is removed
h.usedcdt_hhdcdt = 0
h.run()
