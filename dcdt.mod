TITLE hhdcdt.mod   squid sodium, potassium, and leak channels + sodium gate cm

: modified to take into account sodium gating capacitance (perhaps wrongly)
: But provides an example of how to manage variable capacitance using
: the relation q = c*v so that i = (c*dv/dt) + (dc/dt * v)
: The gating capacitance is assumed to be c = c0 + c1*(1 - m_hh)
: The effect of changing capacitance on the (c*dv/dt) term is accomplished
: via a POINTER to the compartment cm (set up in hoc) where the c pointer
: is assigned a value in the BEFORE BREAKPOINT block.  The effect of
: the (dc/dt * v) term is accomplished in the BREAKPOINT block (note that
: dc/dt = -c1 * dm_hh/dt = -c1 * ( minf - m/mtau ). It is a computaionally
: experimental question for me if it is safe to use Dm for ( minf - m/mtau).
: (the answer is no, for both the fixed and variable step methods.)
: My confidence that this last term (dc/dt * v) is physically correct is low.
: But this model is about how to solve a time varying capacitance
: equation in NEURON, not whether
: the equation is a conceptually valid model of the biophysics.
: To allow a better undertanding of the role of the two terms of d(c*v)/dt,
: the flag use_dc_dt can be used to turn the second term on or off.
 

UNITS {
  (mA) = (milliamp)
  (mV) = (millivolt)
  (uF) = (microfarad)
  PI = (pi) (1)
}

NEURON {
  SUFFIX dcdt
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
  i (mA/cm2)
  v (mV)
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
}

BEFORE BREAKPOINT {
  VERBATIM
  if (_p_c) {
  ENDVERBATIM
    c = cm(t)
  VERBATIM
  }
  ENDVERBATIM
  dc = dcmdt(t)
}

BREAKPOINT {
  at_time(tbegin)
  at_time(tbegin + tdur)
  
  i = dc*v*(0.001)
}
