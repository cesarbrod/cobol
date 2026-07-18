IDENTIFICATION DIVISION.
PROGRAM-ID. resposta.

ENVIRONMENT DIVISION.
CONFIGURATION SECTION.
SOURCE-COMPUTER. POPOS-Linux.
OBJECT-COMPUTER. POPOS-Linux.

DATA DIVISION.
WORKING-STORAGE SECTION.
    01 resposta PIC IS 99.

PROCEDURE DIVISION.
begin.
    DISPLAY "Olha o Cobol no Linux!".
    MOVE 42 TO resposta.
    DISPLAY "A resposta para o mundo, o universo, e todas as coisas é......".
    DISPLAY resposta.
EXIT PROGRAM.
