	;; functions
	global str_copy, str_clear, str_comp, str_split_ptr, str_comp_ptr, str_len, str_to_int
	;; variables
	
	section .data
	
	section .text

	;; //////////////////
	;; String Length
	;; 
	;; rdi: input string
	;; rax: return length
str_len:
	push rdi
	
	xor rax,rax		;reset counter
	;; decrement rdi pointer so first increment will be at beginning
	dec rdi			
	
	.loop:
	;; mov rax,byte '1'
	inc rdi
	inc rax	
	cmp [rdi],byte 0		;check to see if counter is at zero
	jne .loop			;if not, keep going

	pop rdi
	ret

	;; //////////////////
	;; String Copy
	;; 
	;; rdi: input string
	;; rsi: output string
str_copy:
	push r9
	
	.loop:
	;; mov rax,byte '1'
	mov r9, [rdi]	;grab char from input str at rdx
	mov [rsi], r9b	;move char byte to str2 at rdx
	inc rdi
	inc rsi
	cmp r9b,0		;check to see if counter is at zero
	jne .loop		;if not, keep going

	pop r9
	ret

	;; //////////////////////////////
	;; convert string to integer
	;; 
	;; rdi: ptr to str
	;; rax: return value
str_to_int:
	;; uses r8,r9,r10,rdi,rax,rcx,rdx
	;; preserve rcx,rdx
	push rcx
	push rdx
	
	;; >123456
	xor r10,r10		;store start of ptr to str
	xor r9,r9		;value from string
	xor r8,r8		;temp return result, moves final return to rax

	mov r10,rdi
	
	;; get len of number in str
	.move_to_end:
	mov r9b,byte [rdi]
	inc rdi
	cmp r9b,0
	jne .move_to_end
	dec rdi			;after finding end of str '0' back off to last char
	
	xor r9,r9
	xor rcx,rcx		;multiplier
	mov cl,1
	.loop:

	;; if character is null
	xor r9,r9
	dec rdi			;increase pointer to number str
	
	cmp rdi,r10		;start position of pointer
	jl .done

	mov r9b,byte [rdi]	;grab char from input str at rdi

	;; get numeric value from char
	sub r9,'0'
	
	mov rax,r9		;move value to rax for mul
	mul rcx			;multiply by rcx = 
	xor rdx,rdx		;clear mul overflow
	
	add r8,rax		;add to return value
	
	xor rax,rax		;clear rax
	mov al,10		;mov 10 multiplier to rax
	mul rcx			;multiply cur rcx (x10)
	xor rdx,rdx		;clear mul overflow
	mov rcx,rax		;mov new mul value to rcx
	
	jmp .loop

	.done:
	mov rax,r8

	pop rdx
	pop rcx
	ret

	;; ///////////////////////////////
	;; TODO: convert integer to string
int_to_str:


	ret

	;; ////////////////
	;; String Compare
	;; 
	;; rdi: str1
	;; rsi: str2
	;; rdx: length
	;; rax: returns 0 (no match) or 1 (match)
str_comp:		
	.loop:
	;; mov rax,byte '1'
	dec rdx			;decrement len counter
	mov r9, [rdi+rdx]	;get char from str1
	mov r10, [rsi+rdx]	;get char from str2
	cmp r9b, r10b		;compare char1, char2
	jne .no_bueno		;no equal no bueno
	;; Keep looping until end
	cmp rdx,0		
	jne .loop		;compare and jump if len counter not zero
	
	;; All match
	mov rax,1
	ret
	;; Did not match
	.no_bueno:
	mov rax,0
	ret

	;; /////////////////
	;; String Clear
	;;
	;; rdi: str to clear
	;; clear memory at rdi
str_clear:
	.loop:
	cmp [rdi],byte 0	;if rdi reaches '0'...
	je .done		;...then stop clearing.

	mov [rdi],byte 0	;clear current position in rdi
	inc rdi			;increment to next char position

	jmp .loop		;continue looping
	
	.done:
	ret

	;; ///////////////////////////////////////////////////
	;; compare data from 2 pointers rdi, rsi return in rax
	;; 
	;; rdi: compare pointer 1
	;; rsi: compare pointer 2
	;; rax: return - 1 (match) or 0 (no match)
str_comp_ptr:
	;mov rdi,[rdi]
	xor rax,rax
	.loop:
	mov r9b,byte [rsi]		;grab char byte from rsi at current ptr pos
	mov r10b,byte [rdi]		;grab char byte from rdi at current ptr pos
	;; mov rax,byte '1'
	;mov r9b, dil	;get char from str1
	;mov r10b, sil	;get char from str2
	cmp r10b,0		;if rdi reaches null, shows over.
	je .done
	
	cmp r9b, r10b		;compare char1, char2
	jne .no_bueno		;no equal no bueno
	;; Keep looping until end
	inc rdi			;increment pointer position in buffer
	inc rsi			;increment pointer position in buffer
	
	cmp r10b,0		
	jne .loop		;compare and jump if len counter not zero
	.done:
	;; All match
	mov rax,1
	ret
	;; Did not match
	.no_bueno:
	mov rax,0
	ret

	;; ////////////////////////////////////////////
	;; splits string and returns split positions in rax pointer
	;; 
	;; rdi: input
	;; rsi: split char
	;; rax: return ptr buffer
str_split_ptr:
	xor rcx,rcx		;ptr buffer counter (*8)
	xor r11,r11		;len counter
	inc r11			;start with len of 1
	;jmp .store_ptr
	mov [rax],rdi	;set first ptr in array to beginning of str
	add rcx,9	;inc to next index position
	
	.loop:
	;; clear r10 register of garbage outside the first 8 bits
	xor r10,r10		;register to store compare char
	;; mov char from string with offset into lowest byte of rax
	mov r10b,byte [rdi]	
	inc rdi			;inc pointer to input str
	inc r11			;inc len counter
	
	;; compare current char to split char, if they match
	;; jump and store to split pointer array
	cmp r10b,sil		;compare with split byte rsi
	je .store_ptr
	cmp r10b,10
	je .store_ptr
	.cont:

	;; keep scanning input string until end is reached
	cmp r10b,10
	jne .loop
	
	ret

	.store_ptr:
	;; move pointer to current location of string into ptr buffer struct index
	mov [rax+rcx],rdi
	mov [rdi-1],byte 44	;replace split char with 44 ','
	dec r11b		;back off len to not include split char
	;; len of previous index
	mov [rax+rcx-1],r11b		;move to previous pointer buffer struct
	;inc rcx			;inc index counter
	add rcx,9
	xor r11,r11		;reset len counter
	jmp .cont
