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
 
COMMENT
 This is the original Hodgkin-Huxley treatment for the set of sodium, 
  potassium, and leakage channels found in the squid giant axon membrane.
  ("A quantitative description of membrane current and its application 
  conduction and excitation in nerve" J.Physiol. (Lond.) 117:500-544 (1952).)
 Membrane voltage is in absolute mV and has been reversed in polarity
  from the original HH convention and shifted to reflect a resting potential
  of -65 mV.
 Remember to set celsius=6.3 (or whatever) in your HOC file.
 See squid.hoc for an example of a simulation using this model.
 SW Jaslove  6 March, 1992
ENDCOMMENT
 
UNITS {
        (mA) = (milliamp)
        (mV) = (millivolt)
	(S) = (siemens)
}

? interface
NEURON {
        SUFFIX hhdcdt
  THREADSAFE : assigned GLOBALs will be per thread
        REPRESENTS NCIT:C17145   : sodium channel
        REPRESENTS NCIT:C17008   : potassium channel
        USEION na READ ena WRITE ina REPRESENTS CHEBI:29101
        USEION k READ ek WRITE ik REPRESENTS CHEBI:29103
  GLOBAL usedcdt
  RANGE c0, c1
  POINTER c
        NONSPECIFIC_CURRENT il
        RANGE gnabar, gkbar, gl, el, gna, gk
        GLOBAL minf, hinf, ninf, mtau, htau, ntau
}
 
PARAMETER {
  usedcdt = 1
  c0 = 0.88 (microfarad/cm2)
  c1 = 0.13 (microfarad/cm2)
        gnabar = .12 (S/cm2)	<0,1e9>
        gkbar = .036 (S/cm2)	<0,1e9>
        gl = .0003 (S/cm2)	<0,1e9>
        el = -54.3 (mV)
}
 
STATE {
        m h n
}
 
ASSIGNED {
  c (microfarad/cm2)
  idc (mA/cm2)
        v (mV)
        celsius (degC)
        ena (mV)
        ek (mV)

	gna (S/cm2)
	gk (S/cm2)
        ina (mA/cm2)
        ik (mA/cm2)
        il (mA/cm2)
        minf hinf ninf
	mtau (ms) htau (ms) ntau (ms)
}
 
BEFORE BREAKPOINT {
  VERBATIM
  if (_p_c) {
  ENDVERBATIM
    c = c0 + c1*(1 - m)
  VERBATIM
  }
  ENDVERBATIM
}

? currents
BREAKPOINT {
        SOLVE states METHOD cnexp
        gna = gnabar*m*m*m*h
	ina = gna*(v - ena)
        gk = gkbar*n*n*n*n
	ik = gk*(v - ek)      
        il = gl*(v - el)
  idc = 0
  VERBATIM
  if (_p_c) {
  ENDVERBATIM
  rates(v)
  idc = -c1*((minf - m)/mtau)*v*(0.001)
  VERBATIM
  }
  ENDVERBATIM
  if (usedcdt) {
    il = il + idc
  }
}
 
 
INITIAL {
	rates(v)
	m = minf
	h = hinf
	n = ninf
}

? states
DERIVATIVE states {  
        rates(v)
        m' =  (minf-m)/mtau
        h' = (hinf-h)/htau
        n' = (ninf-n)/ntau
}
 
:LOCAL q10


? rates
PROCEDURE rates(v(mV)) {  :Computes rate and other constants at current v.
                      :Call once from HOC to initialize inf at resting v.
        LOCAL  alpha, beta, sum, q10
        TABLE minf, mtau, hinf, htau, ninf, ntau DEPEND celsius FROM -100 TO 100 WITH 200

UNITSOFF
        q10 = 3^((celsius - 6.3)/10)
                :"m" sodium activation system
        alpha = .1 * vtrap(-(v+40),10)
        beta =  4 * exp(-(v+65)/18)
        sum = alpha + beta
	mtau = 1/(q10*sum)
        minf = alpha/sum
                :"h" sodium inactivation system
        alpha = .07 * exp(-(v+65)/20)
        beta = 1 / (exp(-(v+35)/10) + 1)
        sum = alpha + beta
	htau = 1/(q10*sum)
        hinf = alpha/sum
                :"n" potassium activation system
        alpha = .01*vtrap(-(v+55),10) 
        beta = .125*exp(-(v+65)/80)
	sum = alpha + beta
        ntau = 1/(q10*sum)
        ninf = alpha/sum
}
 
FUNCTION vtrap(x,y) {  :Traps for 0 in denominator of rate eqns.
        if (fabs(x/y) < 1e-6) {
                vtrap = y*(1 - x/y/2)
        }else{
                vtrap = x/(exp(x/y) - 1)
        }
}
 
UNITSON
