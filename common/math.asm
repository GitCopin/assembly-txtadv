	;; global functions
	global distance_i2ef, math_abs
	;; global variables
	
	;; external functions
	extern str_len, str_copy, printi
	
	section .data

expo:	dd 10.0
x:	dd 4.2
y:	dd 3.7
h:	dd 0.0

	section .text

	;; rdi: x
	;; rsi: y
	;; rax: return int describing a float with exponent of 2. (x10^2)
	;;      e.g. 123 = 1.23
distance_i2ef:	
	;; clear xmm0 xmm1 xmm2
	xorpd xmm0,xmm0
	xorpd xmm1,xmm1
	xorpd xmm2,xmm2
	xorpd xmm3,xmm3
	;; cvtsi2sd xmm0,

	;; load x1 and square
	cvtsi2ss xmm0,rdi
	divss xmm0,[expo]

	mulss xmm0,xmm0
	;; load y1 and square
	cvtsi2ss xmm1,rsi
	divss xmm1,[expo]

	mulss xmm1,xmm1
	;; add squared x and y
	addss xmm0,xmm1
	;; calc square root
	sqrtss xmm1,xmm0

	;; mult by 10 and convert to int
	mulss xmm1,[expo]

	;; return distance in rax
	xor rax,rax
	cvtss2si rax,xmm1

	ret
	
math_abs:

	ret
