	;; /////////////////////////////////////
	;; preserve rsp and subtract %1 from rsp
	%macro prolog 1
	push rbp
	mov rbp,rsp
	sub rsp,%1
	%endmacro

	;; //////////////////////////////
	;; preserve rsp and add %1 to rbp
	%macro prologb 1
	push rbp     
	mov rbp,rsp
	add rbp,%1
	%endmacro

	;; ////////////////////////////////////////////
	;; kill / undo last push without popping to reg
	%macro popkill 0
	add rsp,8
	%endmacro

	;; ///////////////////
	;; restore rsp and rbp
	%macro epilog 0
	mov rsp,rbp
	pop rbp
	%endmacro

	;; /////////////////////////////////
	;; count number of digits in integer
	;; returns length in rax
	%macro num_digits 1
	push r8
	push rcx
	push rdx
	
	xor r8,r8
	xor rax,rax		;reset and
	mov rax,%1		;set dividend
	
	.count_digits:
	inc r8			;inc len counter
	xor rdx,rdx		;reset remainder
	mov rcx,10		;set divisor to 10
	div rcx			;divide rax by rcx
	cmp rax,0		;stop if nothing left to divide
	jne .count_digits

	xor rax,rax		;reset and
	mov rax,r8		;set rax to len of number
	
	pop rdx
	pop rcx
	pop r8
	%endmacro

	;; /////////////////////////////////////
	;; output %1 to screen with length of %2
	;;
	;; uses: rsi, rdx, rax, rdi
	%macro prints 2
	;xor rsi,rsi
	;xor rdx,rdx
	push rdx
	
	xor rax,rax
	xor rdi,rdi
	mov rsi,%1		;set text output pointer	
	mov rdx,%2		;len of str
	mov rax,1
	mov rdi,1
	syscall

	pop rdx
	%endmacro

	;; /////////////////////////////////////////
	;; prints %1 to screen with length of %1_len
	;; requires 'string' and 'string_len' labels defined
	;; 
	;; uses: rsi, rdx, rax, rdi
	%macro printsl 1
	;xor rsi,rsi
	;xor rdx,rdx
	push rdx

	xor rax,rax
	xor rdi,rdi
	mov rsi,%1		;set text output pointer	
	mov rdx,%1_len		;len of str
	mov rax,1
	mov rdi,1
	syscall

	pop rdx
	%endmacro

	%macro printsl 2
	;xor rsi,rsi
	;xor rdx,rdx
	push rdx

	xor rax,rax
	xor rdi,rdi
	xor rdx,rdx

	mov rsi,%1%2		;set text output pointer	
	mov edx,[%1_len]	;len of str
	mov rax,1
	mov rdi,1
	syscall

	pop rdx
	%endmacro

	;; ////////////////////////////////////////
	;; same as prints but outputs newline after
	;;
	;; uses: rsi, rdx, rax, rdi
	%macro println 2
	push rdx
	
	prints %1,%2
	xor rdx,rdx
	xor rsi,rsi
	mov rax,1
	mov rdi,1
	;; push qword to prevent unaligned stack
	;; pushing less than qword messes up proceeding pushes
	push qword 10
	mov rsi,rsp		;set text output pointer	
	mov dl,1		;len of str
	syscall
	pop rsi			;pop qword 10

	pop rdx
	%endmacro

	;; print space
	%macro printspc 0
	push rdx
	
	xor rdx,rdx
	xor rsi,rsi
	mov rax,1
	mov rdi,1
	push qword 32
	mov rsi,rsp		;set text output pointer	
	mov dl,1		;len of str
	syscall
	pop rsi			;pop qword 10

	pop rdx
	%endmacro

	;; print ascii char
	%macro printchar 1
	push rdx
	
	xor rdx,rdx
	xor rsi,rsi
	mov rax,1
	mov rdi,1
	push qword %1
	mov rsi,rsp		;set text output pointer	
	mov dl,1		;len of str
	syscall
	pop rsi			;pop qword 10

	pop rdx
	%endmacro

	;; print new line
	%macro printnl 0
	push rdx
	
	xor rdx,rdx
	xor rsi,rsi
	mov rax,1
	mov rdi,1
	push qword 10
	mov rsi,rsp		;set text output pointer	
	mov dl,1		;len of str
	syscall
	pop rsi			;pop qword 10

	pop rdx
	%endmacro

	;; print integer dword
	%macro printint 1
	push rdi

	xor rdi,rdi
	movsxd rdi,%1
	call printi

	pop rdi
	%endmacro

	;; ////////////
	;; exit syscall
	%macro exit 1
	mov rax,60
	mov rdi,%1
	syscall
	%endmacro

	;; ///////////////////////////////////////////////////
	;; nanosleep
	;; e.g. nanosleep 0,500000000
	;; specify seconds in %1
	;; specify nano-seconds in %2: 500,000,000 uSec = 0.5s
	%define sys_nanosleep 35
	
	%macro nanosleep 2

	mov qword [sec],%1
	mov qword [usec],%2
	
	mov rax,sys_nanosleep
	mov rdi,timespec
	mov rsi,0
	syscall
	%endmacro

	;; /////////////////////////////////////
	;; return system time since epoch in rax
	%macro get_time 0
	push rdi

	xor rax,rax
	xor rdi,rdi
	mov rax,201
	syscall
	
	pop rdi
	%endmacro

	;; ///////////////////////////////
	;; wrapper for read_file function
	;; TODO: get length of read file.
	%assign READ_FILE_LEN 2000
	
	%macro LOAD_FILE 1
	push rax		;preserve RAX, RDI, RSI
	push rdi
	push rsi
	
	xor rax,rax		;clear RAX, RDI, RSI
	xor rdi,rdi
	xor rsi,rsi
	mov rax,%1_file		;RAX = filename
	mov rdi,%1_buf		;RDI = buffer to load data into
	mov rsi,%1_len		;RSI = len to read
	call read_file		;call read_file function

	xor rdi,rdi		;clear RDI, RAX
	xor rax,rax
	mov rdi,%1_buf		;mov _buf location to RDI
	call str_len		;get length of buffer
	mov [%1_len],eax	;store length back into _buf location
	
	pop rsi			;restore RSI, RDI, RAX
	pop rdi
	pop rax
	%endmacro

	;; /////////////////////////
	;; Read File Buffer by Byte
	;; READ_FILE [_byte,_word,_dword,_qword],label
	%macro READ_FILE 2
	push rbx
	push rcx
	push rdx
	
	xor rbx,rbx
	mov rbx,%1_buf		;get buffer position in RBX
	xor rdx,rdx
	mov edx,[%1_pos]	;get offset byte count in RDX
	add rbx,rdx		;add buffer pos (RBX) and offset (RDX)

	xor rax,rax

	%if %1==1
	mov al,byte [rbx]	;get byte data into return register (RAX)
	%elif %1==2
	mov ax,word [rbx]
	%elif %1==4
	mov eax,dword [rbx]
	%else
	mov rax,[rbx]
	%endif
	
	add rbx,1		;add 1 byte to offset
	mov [%1_pos],rbx	;store new position to _pos location
	
	pop rdx
	pop rcx
	pop rbx
	%endmacro

	;; ////////////////////////////////
	;; SET_READ_BUF rcx,story.chapter1
	%macro SET_READ_BUF 2
	xor %1,%1
	mov %1,%2_buf
	push %1
	%endmacro
	;; ////////////////////////////
	;; SET_READ_BUF story.chapter1
	;; use RCX
	%macro SET_READ_BUF 1
	xor rcx,rcx
	mov rcx,%1_buf
	push rcx
	%endmacro

	;; /////////////////////////////////////////////
	;; READ_NEXT rcx,[_byte, _word, _dword, _qword]
	%macro READ_NEXT 2
	pop %1
	xor rax,rax
	
	%if %2 = 1		;_byte
	mov al,byte [%1]
	add %1,1

	%elif %2 = 2		;_word
	mov ax,word [%1]
	add %1,2

	%elif %2 = 4		;_dword
	mov eax,dword [%1]
	add %1,4

	%else			;_qword
	mov rax,[%1]
	add %1,8
	%endif
	
	push %1
	%endmacro

	;; ////////////////////////////////////////
	;; READ_NEXT [_byte, _word, _dword, _qword]
	;; use RCX
	%macro READ_NEXT 1
	pop rcx
	xor rax,rax
	
	%if %1 = 1		;_byte
	mov al,byte [rcx]
	add rcx,1

	%elif %1 = 2		;_word
	mov ax,word [rcx]
	add rcx,2

	%elif %1 = 4		;_dword
	mov eax,dword [rcx]
	add rcx,4

	%else			;_qword
	mov rax,[rcx]
	add rcx,8
	%endif
	
	push rcx
	%endmacro

	;; ////////////////////////////
	;; READ_TEXT text_buffer_label
	%macro READ_TEXT 1
	pop rcx
	push rbx
	xor rax,rax
	xor rbx,rbx

	mov rbx,%1		;get location of input label
%%loop:
	mov al,byte [rcx]	;get character from file buffer
	mov [rbx],al		;put character into input label location

	add rbx,1		;increment label location
	add rcx,1		;increment file buffer position
	cmp al,0		;test if last character was 0, if true then stop.
	jne %%loop

	pop rbx
	push rcx
	%endmacro
	
	;; ////////////////////////
	;; END_READ rcx
	;; restore counter register
	%macro END_READ 1
	pop %1
	%endmacro

	;; /////////
	;; END_READ
	;; use RCX
	%macro END_READ 0
	pop rcx
	%endmacro
