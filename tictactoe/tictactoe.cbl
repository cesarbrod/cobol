*>=============================================================
      *> TIC-TAC-TOE - two-player CLI game in COBOL
      *> Compile:  cobc -x -free tictactoe.cob -o tictactoe
      *> Run:      ./tictactoe
      *>=============================================================
       >>SOURCE FREE
       IDENTIFICATION DIVISION.
       PROGRAM-ID. TICTACTOE.

       DATA DIVISION.
       WORKING-STORAGE SECTION.

       01  WS-BOARD.
           05  WS-CELL             PIC X OCCURS 9 TIMES.

       01  WS-LINES-STR            PIC X(24)
               VALUE "123456789147258369159357".
       01  WS-LINES-TAB REDEFINES WS-LINES-STR.
           05  WS-LINE             OCCURS 8 TIMES.
               10  WS-POS          OCCURS 3 TIMES PIC 9.

       01  WS-CURRENT-PLAYER       PIC X    VALUE "X".
       01  WS-OTHER-PLAYER         PIC X.
       01  WS-MOVE-INPUT           PIC X(1).
       01  WS-MOVE                 PIC 9    VALUE 0.
       01  WS-MOVE-COUNT           PIC 9    VALUE 0.
       01  WS-GAME-OVER            PIC X    VALUE "N".
       01  WS-WINNER               PIC X    VALUE SPACE.
       01  WS-VALID-MOVE           PIC X    VALUE "N".
       01  WS-LINE-IDX             PIC 9.
       01  WS-P1                   PIC 9.
       01  WS-P2                   PIC 9.
       01  WS-P3                   PIC 9.
       01  WS-ERR-MSG              PIC X(40) VALUE SPACES.

       PROCEDURE DIVISION.

       MAIN-LOGIC.
           PERFORM INIT-BOARD
           DISPLAY " "
           DISPLAY "===== TIC-TAC-TOE ====="
           DISPLAY "Players enter a number 1-9 to place a mark."
           DISPLAY " "

           PERFORM UNTIL WS-GAME-OVER = "Y"
               PERFORM SHOW-BOARD
               PERFORM GET-MOVE
               PERFORM APPLY-MOVE
               PERFORM CHECK-WIN
               IF WS-WINNER NOT = SPACE
                   MOVE "Y" TO WS-GAME-OVER
               ELSE
                   IF WS-MOVE-COUNT = 9
                       MOVE "Y" TO WS-GAME-OVER
                   ELSE
                       PERFORM SWITCH-PLAYER
                   END-IF
               END-IF
           END-PERFORM

           PERFORM SHOW-BOARD

           IF WS-WINNER NOT = SPACE
               DISPLAY "*** Player " WS-WINNER " WINS! ***"
           ELSE
               DISPLAY "*** It's a draw. ***"
           END-IF

           DISPLAY " "
           STOP RUN.

      *>-------------------------------------------------------------
       INIT-BOARD.
           MOVE "1" TO WS-CELL(1)
           MOVE "2" TO WS-CELL(2)
           MOVE "3" TO WS-CELL(3)
           MOVE "4" TO WS-CELL(4)
           MOVE "5" TO WS-CELL(5)
           MOVE "6" TO WS-CELL(6)
           MOVE "7" TO WS-CELL(7)
           MOVE "8" TO WS-CELL(8)
           MOVE "9" TO WS-CELL(9).

      *>-------------------------------------------------------------
       SHOW-BOARD.
           DISPLAY " "
           DISPLAY "   " WS-CELL(1) " | " WS-CELL(2) " | " WS-CELL(3)
           DISPLAY "  ---+---+---"
           DISPLAY "   " WS-CELL(4) " | " WS-CELL(5) " | " WS-CELL(6)
           DISPLAY "  ---+---+---"
           DISPLAY "   " WS-CELL(7) " | " WS-CELL(8) " | " WS-CELL(9)
           DISPLAY " ".

      *>-------------------------------------------------------------
       GET-MOVE.
           MOVE "N" TO WS-VALID-MOVE
           PERFORM UNTIL WS-VALID-MOVE = "Y"
               MOVE SPACES TO WS-ERR-MSG
               DISPLAY "Player " WS-CURRENT-PLAYER
                   " - choose a cell (1-9): " WITH NO ADVANCING
               ACCEPT WS-MOVE-INPUT

               IF WS-MOVE-INPUT IS NUMERIC
                   MOVE WS-MOVE-INPUT TO WS-MOVE
                   IF WS-MOVE >= 1 AND WS-MOVE <= 9
                       IF WS-CELL(WS-MOVE) = "X" OR
                          WS-CELL(WS-MOVE) = "O"
                           DISPLAY "That cell is already taken."
                       ELSE
                           MOVE "Y" TO WS-VALID-MOVE
                       END-IF
                   ELSE
                       DISPLAY "Enter a number between 1 and 9."
                   END-IF
               ELSE
                   DISPLAY "Invalid input. Enter a number 1-9."
               END-IF
           END-PERFORM.

      *>-------------------------------------------------------------
       APPLY-MOVE.
           MOVE WS-CURRENT-PLAYER TO WS-CELL(WS-MOVE)
           ADD 1 TO WS-MOVE-COUNT.

      *>-------------------------------------------------------------
       CHECK-WIN.
           MOVE SPACE TO WS-WINNER
           PERFORM VARYING WS-LINE-IDX FROM 1 BY 1
                   UNTIL WS-LINE-IDX > 8 OR WS-WINNER NOT = SPACE
               MOVE WS-POS(WS-LINE-IDX 1) TO WS-P1
               MOVE WS-POS(WS-LINE-IDX 2) TO WS-P2
               MOVE WS-POS(WS-LINE-IDX 3) TO WS-P3

               IF WS-CELL(WS-P1) = WS-CELL(WS-P2) AND
                  WS-CELL(WS-P2) = WS-CELL(WS-P3) AND
                  (WS-CELL(WS-P1) = "X" OR WS-CELL(WS-P1) = "O")
                   MOVE WS-CELL(WS-P1) TO WS-WINNER
               END-IF
           END-PERFORM.

      *>-------------------------------------------------------------
       SWITCH-PLAYER.
           IF WS-CURRENT-PLAYER = "X"
               MOVE "O" TO WS-CURRENT-PLAYER
           ELSE
               MOVE "X" TO WS-CURRENT-PLAYER
           END-IF.
