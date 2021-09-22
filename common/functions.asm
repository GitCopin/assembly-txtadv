	%include "../common/macros.asm"

	;; global functions
	global get_input, printi, get_args
	;; global variables
	global user_input, arg_len,
	global arg_list, arg_list.arg2, arg_list.arg3, arg_list.arg4
	
	;; external functions
	extern str_len, str_copy
	
	section .data
buf:	times 50 db 0
user_input:	times 100 db 0
arg_len:	db 0
arg_list:
	.arg1:	times 50 db 0
	.arg2:	times 50 db 0
	.arg3:	times 50 db 0
	.arg4:	times 50 db 0
	.arg5:	times 50 db 0
	
	section .text

	;; //////////////////////////////
	;; user input syscall
	;; 
	;; returns string into user_input
get_input:
	mov rax,0
	mov rdi,1
	mov rsi,user_input		;variable to store input into
	mov rdx,14		;length to store

	syscall
	ret

write_output:
	mov rax,1
	mov rdi,1
	mov rsi,rcx		;set text output pointer to rbx	

	syscall
	ret

	;; //////////////////////////////
	;; print integer
	;; TODO: need to clear buf to 0's
	;; 
	;; rdi: input value
printi:	
	push rdx		;store rdx rax rcx on stack
	push rax
	push rcx

	xor r8,r8
	xor r9,r9
	
	xor rax,rax		;reset dividend
	xor rcx,rcx		;reset devisor
	xor r8,r8		;use for len of str
	inc r8			;give init len of 1
	mov rax,rdi		;mov input value

	;; get num if digits in input val
	.count_digits:
	inc r8			;inc len counter
	xor rdx,rdx		;reset remainder
	mov rcx,10		;set divisor to 10
	div rcx
	cmp rax,0		;stop if nothing left to divide
	jne .count_digits
	;;///////////////////////
	
	xor rdx,rdx		;reset rdx rax rcx
	xor rax,rax
	xor rcx,rcx

	mov rax,rdi		;dividend
	mov r9,buf		;point r9 to buf
	add r9,r8		;move pointer r8 chars

	mov [r9],byte 0	;add newline char
	sub r9,1		;sub pointer for next char. func stores nunber from right to left.

	.next_char:
	xor rdx,rdx		;reset remainder
	mov rcx,10		;divisor
	div rcx			;do the div
	
	add rdx,'0'		;add ascii '0' to convert to ascii
	sub r9,1		;move to next number
	mov [r9],dl		;move into string buffer
	
	cmp rax,0		;has the dividend reached zero yet?
	jne .next_char

	push rdx		;preserve rdx rax
	push rax
	push rdi
	inc r8			;inc to include newline char 10
	prints buf,r8		;print str buffer
	pop rdi
	pop rax
	pop rdx

	pop rcx
	pop rax
	pop rdx
	ret

	;; //////////////////////////////////////
	;; get command line arguments from system
	;; and return pointers in arg_list,
	;; arg count in arg_len
	;;
	;; arg_len: number of args available
	;; arg_list: buffer for arg string pointers
get_args:
	push rax
	push rdi
	push rcx
	push rbp

	xor r9,r9		;arg_list offset counter
	xor rax,rax 
	mov rax,[rbp]
	;; be sure to use the correct register size that will
	;; fit into mem size without overflowing and overwriting
	;; subsequent data.
	mov byte [arg_len],al	;move arg len into arg_len.
	add al,'0'
	mov [buf],al

	mov rdi,buf
	call str_len		;rdi: input str. rax: ret len
	
	println buf,rax
	
	xor rcx,rcx
	mov cl,byte [arg_len]	;be sure to match register size with size in mem

	.arg_loop:
	dec rcx
	push rcx
	
	add rbp,8
	mov rdi,[rbp]
	call str_len		;rdi: input str. rax: ret len

	;push rdi		;preserve rdi since println uses it
	;println [rbp],rax
	;pop rdi

	push rdi
	mov rdi,[rbp]
	mov rsi,arg_list
	add rsi,r9
	call str_copy
	add r9,50
	pop rdi

	
	pop rcx
	
	cmp rcx,0
	jne .arg_loop

	pop rbp
	pop rcx
	pop rdi
	pop rax
	
	ret
