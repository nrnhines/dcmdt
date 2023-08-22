: Provides an example of how to manage variable capacitance using
: the relation q = c*v so that i = (c*dv/dt) + (dc/dt * v)
: The capacitance is assumed to be c(t)
: The effect of changing capacitance on the (c*dv/dt) term is accomplished
: via a POINTER to the compartment cm (set up in hoc) where the c pointer
: is assigned a value in the BEFORE BREAKPOINT block.  The effect of
: the (dc/dt * v) term is accomplished in the BREAKPOINT block.
: This is a POINT_PROCESS to allow charge conservation q=c*v across a
: discontinuity in c

UNITS {
  (nA) = (nanoamp)
  (mV) = (millivolt)
  (uF) = (microfarad)
  (um) = (micron)
  PI = (pi) (1)
}

NEURON {
  POINT_PROCESS DcDt
  THREADSAFE
  RANGE c1, c2, w, tbegin, tdur, dc
  POINTER c
  NONSPECIFIC_CURRENT i
}
 
PARAMETER {
  c1 = 1 (uF/cm2)
  c2 = 0 (uF/cm2)
  w = 0 (/ms)
  tbegin = 1e9 (ms) 
  tdur = 0 (ms)
  dc (uF/cm2-ms)
}
 
ASSIGNED {
  c (uF/cm2)
  i (nA)
  v (mV)
  area (um2)
}
 
FUNCTION cm(t(ms)) (uF/cm2) {
  if (t >= tbegin && t <= (tbegin + tdur)) {
    cm = c1 + c2*sin(2*PI*w*(t - tbegin))
  }else{
    cm = c1
  }
}
        
FUNCTION dcmdt(t(ms))(uF/cm2-ms) {
  if (t >= tbegin && t <= (tbegin + tdur)) {
    dcmdt = c2*2*PI*w*cos(2*PI*w*(t - tbegin))
  }else{
    dcmdt = 0
  }
}

INITIAL {
  dc = 0
  net_send(tbegin, 1)
}

BEFORE BREAKPOINT {
  c = cm(t)
  dc = dcmdt(t)
}

BREAKPOINT {
  i = dc*v*area*(1e-5)
}

NET_RECEIVE(w) {
  LOCAL qbefore, cafter, epsilon, tt
  epsilon = 1e-10 (ms)
  if (flag == 1) { : turn on stim
    tt = tbegin
    qbefore = cm(tt - epsilon)*v : charge prior to discontinuity
    cafter = cm(tt + epsilon) : capacitance after discontinuity
    v = qbefore/cafter
    net_send(tdur, 2)
  } else if (flag == 2) { : turn off stim
    tt = tbegin + tdur
    qbefore = cm(tt - epsilon)*v : charge prior to discontinuity
    cafter = cm(tt + epsilon) : capacitance after discontinuity
    v = qbefore/cafter
  }
}

