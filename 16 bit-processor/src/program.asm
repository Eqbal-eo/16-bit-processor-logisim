; ============================================================
;  16-bit Custom Processor — Assembly Program
;  Task   : Count array elements NOT equal to 5
;  Author : Eqbal
;  GitHub : https://github.com/Eqbal-eo
;  Email  : eng.mhdeqbal@gmail.com
; ============================================================
;
;  Register Map:
;    X0 — Zero register (always 0)
;    X1 — RAM address pointer
;    X2 — Loop counter (counts down from array length)
;    X3 — Result counter (elements ≠ 5)
;    X4 — Current element (loaded from RAM)
;    X6 — Constant 5 (comparison value)
;    x7 _ 0000
;
;  Memory Layout:
;    RAM[0x00..0x07] — Input array (8 elements)
;    RAM[0x0A]       — Output (final result)
;
;  Test Input  : [6, 3, 5, 4, 5, 8, 5, 9]
;  Expected Out: 5  (elements 6,3,4,8,9 are ≠ 5)
; ============================================================

; --- Initialization ---
0.  ADDI X6, X0, #5     ; X6 = 5  (comparison target)
1.  ADDI X1, X0, #0     ; X1 = 0  (RAM pointer starts at address 0)
2.  ADDI X2, X0, #8     ; X2 = 8  (loop counter = array length)
3.  ADDI X3, X0, #0     ; X3 = 0  (result counter, will hold final answer)

; --- Loop Start ---
4.  BEQ  X2, X0, #6     ; if X2 == 0: all elements checked → EXIT to inst. 11
5.  LDR  X4, [X1, #0]   ; X4 = RAM[X1]  (load current element into X4)
6.  BEQ  X4, X6, #1     ; if X4 == 5: element equals 5 → SKIP increment (to inst. 8)
7.  ADDI X3, X3, #1     ; X3++  (element ≠ 5, count it)

; --- Loop Update ---
8.  ADDI X1, X1, #1     ; X1++  (advance pointer to next RAM address)
9.  SUBI X2, X2, #1     ; X2--  (decrement loop counter)
10. BEQ  X0, X0, #-7    ; UNCONDITIONAL jump → back to instruction 4

; --- Store Result & Halt ---
11. STR  X3, [X0, #10]  ; RAM[0x0A] = X3  (write final count to memory)
12. BEQ  X0, X0, #-1    ; HALT: infinite loop (PC stays at 0x0C)
