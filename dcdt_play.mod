: Provides an example of how to manage variable capacitance using
: the relation q = c*v so that i = (c*dv/dt) + (dc/dt * v)
: The capacitance is assumed to be c(t)
: The effect of changing capacitance on the (c*dv/dt) term is accomplished
: with Vector.play to cm and Vector.play to dc.
: The effect of the (dc/dt * v) term is accomplished in the BREAKPOINT block.
: If there are discontinuites in the c function (e.g. at the beginning and
: end), charge conservation must be imposed by interpreter code.


UNITS {
  (mA) = (milliamp)
  (mV) = (millivolt)
  (uF) = (microfarad)
  PI = (pi) (1)
}

NEURON {
  SUFFIX dcdtplay
  THREADSAFE
  RANGE dc
  NONSPECIFIC_CURRENT i
}
 
PARAMETER {
  dc (uF/cm2-ms)
}
 
ASSIGNED {
  i (mA/cm2)
  v (mV)
}
 
INITIAL {
  dc = 0
}

BREAKPOINT {
  i = dc*v*(0.001)
}
