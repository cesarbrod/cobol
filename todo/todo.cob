*>=============================================================
      *> TODO-MANAGER
      *>
      *> A simple Eisenhower-matrix TODO list manager.
      *>
      *> Each task is stored with an urgency flag, an importance flag
      *> and a creation timestamp. Tasks are persisted to a plain
      *> text file, always kept sorted with the newest task first.
      *>
      *> Written for GnuCOBOL. Compile with:
      *>   cobc -x -free todo.cob -o todo
      *>=============================================================
       >>SOURCE FORMAT FREE
       IDENTIFICATION DIVISION.
       PROGRAM-ID. TODO-MANAGER.
       AUTHOR. Cesar Brod.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT TASK-FILE ASSIGN TO WS-TASK-FILE-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  TASK-FILE.
       01  TASK-RECORD.
           05  TR-TIMESTAMP            PIC X(14).
           05  TR-URGENT-FLAG          PIC X(01).
           05  TR-IMPORTANT-FLAG       PIC X(01).
           05  TR-DESCRIPTION          PIC X(140).

       WORKING-STORAGE SECTION.

      *>-------------------------------------------------------------
      *> File handling
      *>-------------------------------------------------------------
       01  WS-TASK-FILE-PATH           PIC X(40) VALUE "tasks.txt".
       01  WS-FILE-STATUS              PIC XX.
           88  FILE-OK                 VALUE "00".
           88  FILE-NOT-FOUND          VALUE "35".
           88  FILE-END                VALUE "10".

      *>-------------------------------------------------------------
      *> In-memory task table (loaded from / saved to the file)
      *>-------------------------------------------------------------
       01  WS-MAX-TASKS                PIC 9(4) VALUE 2000.
       01  WS-TASK-COUNT                PIC 9(4) VALUE 0.
       01  WS-TASK-TABLE.
           05  WS-TASK-ENTRY OCCURS 2000 TIMES
                                     INDEXED BY WS-TASK-IDX.
               10  WS-T-TIMESTAMP       PIC X(14).
               10  WS-T-URGENT          PIC X(01).
               10  WS-T-IMPORTANT       PIC X(01).
               10  WS-T-DESCRIPTION     PIC X(140).

      *>-------------------------------------------------------------
      *> Sorting helpers
      *>-------------------------------------------------------------
       01  WS-SORT-I                   PIC 9(4).
       01  WS-SORT-J                   PIC 9(4).
       01  WS-SORT-SWAPPED             PIC X(01).
           88  SWAP-HAPPENED           VALUE "Y".
           88  NO-SWAP-HAPPENED        VALUE "N".
       01  WS-SORT-TEMP.
           05  WS-TEMP-TIMESTAMP        PIC X(14).
           05  WS-TEMP-URGENT           PIC X(01).
           05  WS-TEMP-IMPORTANT        PIC X(01).
           05  WS-TEMP-DESCRIPTION      PIC X(140).

      *>-------------------------------------------------------------
      *> New-task capture
      *>-------------------------------------------------------------
       01  WS-NEW-DESCRIPTION          PIC X(140).
       01  WS-NEW-TIMESTAMP            PIC X(14).
       01  WS-URGENT-ANSWER            PIC X(01).
       01  WS-IMPORTANT-ANSWER         PIC X(01).
       01  WS-CURRENT-DATETIME         PIC X(21).

      *>-------------------------------------------------------------
      *> Menu / listing control
      *>-------------------------------------------------------------
       01  WS-MAIN-CHOICE              PIC X(01).
       01  WS-KEEP-RUNNING             PIC X(01) VALUE "Y".
       01  WS-LIST-ALL-ANSWER          PIC X(01).
       01  WS-QUADRANT-CHOICE          PIC X(01).
       01  WS-MATCH-COUNT              PIC 9(4).
       01  WS-DISPLAY-LINE             PIC X(160).

      *>-------------------------------------------------------------
      *> PROCEDURE DIVISION
      *>-------------------------------------------------------------
       PROCEDURE DIVISION.

       MAIN-CONTROL.
           PERFORM UNTIL WS-KEEP-RUNNING = "N"
               PERFORM SHOW-MAIN-MENU
               PERFORM UNTIL WS-MAIN-CHOICE = "1"
                          OR WS-MAIN-CHOICE = "2"
                          OR WS-MAIN-CHOICE = "3"
                   DISPLAY "Please enter 1, 2 or 3."
                   PERFORM SHOW-MAIN-MENU
               END-PERFORM

               EVALUATE WS-MAIN-CHOICE
                   WHEN "1"
                       PERFORM CREATE-NEW-TASK
                   WHEN "2"
                       PERFORM LIST-TASKS
                   WHEN "3"
                       MOVE "N" TO WS-KEEP-RUNNING
               END-EVALUATE
           END-PERFORM

           DISPLAY " "
           DISPLAY "Goodbye!"
           STOP RUN.

       SHOW-MAIN-MENU.
           DISPLAY " ".
           DISPLAY "========== TODO MANAGER ==========".
           DISPLAY "1. Create new task".
           DISPLAY "2. List tasks".
           DISPLAY "3. Exit".
           DISPLAY "Choose an option: " WITH NO ADVANCING.
           ACCEPT WS-MAIN-CHOICE.

      *>=============================================================
      *> CREATE A NEW TASK
      *>=============================================================
       CREATE-NEW-TASK.
           PERFORM CAPTURE-TASK-DESCRIPTION
           PERFORM CAPTURE-URGENCY-ANSWER
           PERFORM CAPTURE-IMPORTANCE-ANSWER
           PERFORM CAPTURE-CURRENT-TIMESTAMP

           PERFORM LOAD-TASKS-FROM-FILE
           PERFORM APPEND-NEW-TASK-TO-TABLE
           PERFORM SORT-TASKS-NEWEST-FIRST
           PERFORM SAVE-TASKS-TO-FILE

           DISPLAY " ".
           DISPLAY "Task saved.".

       CAPTURE-TASK-DESCRIPTION.
           DISPLAY " ".
           DISPLAY "Describe the task (max 140 characters):".
           ACCEPT WS-NEW-DESCRIPTION.

       CAPTURE-URGENCY-ANSWER.
           MOVE SPACES TO WS-URGENT-ANSWER
           PERFORM UNTIL WS-URGENT-ANSWER = "Y" OR WS-URGENT-ANSWER = "N"
               DISPLAY "Is it urgent? (Y/N): " WITH NO ADVANCING
               ACCEPT WS-URGENT-ANSWER
               MOVE FUNCTION UPPER-CASE(WS-URGENT-ANSWER)
                   TO WS-URGENT-ANSWER
           END-PERFORM.

       CAPTURE-IMPORTANCE-ANSWER.
           MOVE SPACES TO WS-IMPORTANT-ANSWER
           PERFORM UNTIL WS-IMPORTANT-ANSWER = "Y"
                      OR WS-IMPORTANT-ANSWER = "N"
               DISPLAY "Is it important? (Y/N): " WITH NO ADVANCING
               ACCEPT WS-IMPORTANT-ANSWER
               MOVE FUNCTION UPPER-CASE(WS-IMPORTANT-ANSWER)
                   TO WS-IMPORTANT-ANSWER
           END-PERFORM.

       CAPTURE-CURRENT-TIMESTAMP.
           MOVE FUNCTION CURRENT-DATE TO WS-CURRENT-DATETIME
           MOVE WS-CURRENT-DATETIME(1:14) TO WS-NEW-TIMESTAMP.

       APPEND-NEW-TASK-TO-TABLE.
           ADD 1 TO WS-TASK-COUNT
           SET WS-TASK-IDX TO WS-TASK-COUNT
           MOVE WS-NEW-TIMESTAMP  TO WS-T-TIMESTAMP(WS-TASK-IDX)
           MOVE WS-URGENT-ANSWER  TO WS-T-URGENT(WS-TASK-IDX)
           MOVE WS-IMPORTANT-ANSWER
                                  TO WS-T-IMPORTANT(WS-TASK-IDX)
           MOVE WS-NEW-DESCRIPTION
                                  TO WS-T-DESCRIPTION(WS-TASK-IDX).

      *>=============================================================
      *> LIST TASKS
      *>=============================================================
       LIST-TASKS.
           PERFORM LOAD-TASKS-FROM-FILE

           IF WS-TASK-COUNT = 0
               DISPLAY " "
               DISPLAY "There are no tasks yet."
           ELSE
               PERFORM ASK-LIST-ALL-OR-FILTERED
           END-IF.

       ASK-LIST-ALL-OR-FILTERED.
           MOVE SPACES TO WS-LIST-ALL-ANSWER
           PERFORM UNTIL WS-LIST-ALL-ANSWER = "Y"
                      OR WS-LIST-ALL-ANSWER = "N"
               DISPLAY " "
               DISPLAY "List all tasks? (Y/N): " WITH NO ADVANCING
               ACCEPT WS-LIST-ALL-ANSWER
               MOVE FUNCTION UPPER-CASE(WS-LIST-ALL-ANSWER)
                   TO WS-LIST-ALL-ANSWER
           END-PERFORM

           IF WS-LIST-ALL-ANSWER = "Y"
               PERFORM LIST-ALL-QUADRANTS-IN-ORDER
           ELSE
               PERFORM LIST-ONE-CHOSEN-QUADRANT
           END-IF.

       LIST-ALL-QUADRANTS-IN-ORDER.
           PERFORM DISPLAY-QUADRANT-HEADER-1
           PERFORM DISPLAY-TASKS-IMPORTANT-NOT-URGENT
           PERFORM DISPLAY-QUADRANT-HEADER-2
           PERFORM DISPLAY-TASKS-IMPORTANT-URGENT
           PERFORM DISPLAY-QUADRANT-HEADER-3
           PERFORM DISPLAY-TASKS-NOT-IMPORTANT-URGENT
           PERFORM DISPLAY-QUADRANT-HEADER-4
           PERFORM DISPLAY-TASKS-NOT-IMPORTANT-NOT-URGENT.

       LIST-ONE-CHOSEN-QUADRANT.
           PERFORM SHOW-QUADRANT-MENU
           PERFORM UNTIL WS-QUADRANT-CHOICE = "1"
                      OR WS-QUADRANT-CHOICE = "2"
                      OR WS-QUADRANT-CHOICE = "3"
                      OR WS-QUADRANT-CHOICE = "4"
               DISPLAY "Please enter 1, 2, 3 or 4."
               PERFORM SHOW-QUADRANT-MENU
           END-PERFORM

           EVALUATE WS-QUADRANT-CHOICE
               WHEN "1"
                   PERFORM DISPLAY-QUADRANT-HEADER-1
                   PERFORM DISPLAY-TASKS-IMPORTANT-NOT-URGENT
               WHEN "2"
                   PERFORM DISPLAY-QUADRANT-HEADER-2
                   PERFORM DISPLAY-TASKS-IMPORTANT-URGENT
               WHEN "3"
                   PERFORM DISPLAY-QUADRANT-HEADER-3
                   PERFORM DISPLAY-TASKS-NOT-IMPORTANT-URGENT
               WHEN "4"
                   PERFORM DISPLAY-QUADRANT-HEADER-4
                   PERFORM DISPLAY-TASKS-NOT-IMPORTANT-NOT-URGENT
           END-EVALUATE.

       SHOW-QUADRANT-MENU.
           DISPLAY " ".
           DISPLAY "Which group do you want to see?".
           DISPLAY "1. Important and Not Urgent".
           DISPLAY "2. Important and Urgent".
           DISPLAY "3. Not Important and Urgent".
           DISPLAY "4. Not Important and Not Urgent".
           DISPLAY "Choose an option: " WITH NO ADVANCING.
           ACCEPT WS-QUADRANT-CHOICE.

      *>-------------------------------------------------------------
      *> Quadrant headers
      *>-------------------------------------------------------------
       DISPLAY-QUADRANT-HEADER-1.
           DISPLAY " ".
           DISPLAY "--- Important and Not Urgent ---".

       DISPLAY-QUADRANT-HEADER-2.
           DISPLAY " ".
           DISPLAY "--- Important and Urgent ---".

       DISPLAY-QUADRANT-HEADER-3.
           DISPLAY " ".
           DISPLAY "--- Not Important and Urgent ---".

       DISPLAY-QUADRANT-HEADER-4.
           DISPLAY " ".
           DISPLAY "--- Not Important and Not Urgent ---".

      *>-------------------------------------------------------------
      *> Quadrant listings
      *> The table is always kept sorted newest-first, so a single
      *> pass over it in order already yields newest-first output.
      *>-------------------------------------------------------------
       DISPLAY-TASKS-IMPORTANT-NOT-URGENT.
           MOVE 0 TO WS-MATCH-COUNT
           PERFORM VARYING WS-TASK-IDX FROM 1 BY 1
                   UNTIL WS-TASK-IDX > WS-TASK-COUNT
               IF WS-T-IMPORTANT(WS-TASK-IDX) = "Y"
                  AND WS-T-URGENT(WS-TASK-IDX) = "N"
                   PERFORM DISPLAY-ONE-TASK
                   ADD 1 TO WS-MATCH-COUNT
               END-IF
           END-PERFORM
           PERFORM DISPLAY-NONE-FOUND-IF-EMPTY.

       DISPLAY-TASKS-IMPORTANT-URGENT.
           MOVE 0 TO WS-MATCH-COUNT
           PERFORM VARYING WS-TASK-IDX FROM 1 BY 1
                   UNTIL WS-TASK-IDX > WS-TASK-COUNT
               IF WS-T-IMPORTANT(WS-TASK-IDX) = "Y"
                  AND WS-T-URGENT(WS-TASK-IDX) = "Y"
                   PERFORM DISPLAY-ONE-TASK
                   ADD 1 TO WS-MATCH-COUNT
               END-IF
           END-PERFORM
           PERFORM DISPLAY-NONE-FOUND-IF-EMPTY.

       DISPLAY-TASKS-NOT-IMPORTANT-URGENT.
           MOVE 0 TO WS-MATCH-COUNT
           PERFORM VARYING WS-TASK-IDX FROM 1 BY 1
                   UNTIL WS-TASK-IDX > WS-TASK-COUNT
               IF WS-T-IMPORTANT(WS-TASK-IDX) = "N"
                  AND WS-T-URGENT(WS-TASK-IDX) = "Y"
                   PERFORM DISPLAY-ONE-TASK
                   ADD 1 TO WS-MATCH-COUNT
               END-IF
           END-PERFORM
           PERFORM DISPLAY-NONE-FOUND-IF-EMPTY.

       DISPLAY-TASKS-NOT-IMPORTANT-NOT-URGENT.
           MOVE 0 TO WS-MATCH-COUNT
           PERFORM VARYING WS-TASK-IDX FROM 1 BY 1
                   UNTIL WS-TASK-IDX > WS-TASK-COUNT
               IF WS-T-IMPORTANT(WS-TASK-IDX) = "N"
                  AND WS-T-URGENT(WS-TASK-IDX) = "N"
                   PERFORM DISPLAY-ONE-TASK
                   ADD 1 TO WS-MATCH-COUNT
               END-IF
           END-PERFORM
           PERFORM DISPLAY-NONE-FOUND-IF-EMPTY.

       DISPLAY-ONE-TASK.
           MOVE SPACES TO WS-DISPLAY-LINE
           STRING
               "[" WS-T-TIMESTAMP(WS-TASK-IDX) "] "
               FUNCTION TRIM(WS-T-DESCRIPTION(WS-TASK-IDX))
               DELIMITED BY SIZE
               INTO WS-DISPLAY-LINE
           END-STRING
           DISPLAY FUNCTION TRIM(WS-DISPLAY-LINE).

       DISPLAY-NONE-FOUND-IF-EMPTY.
           IF WS-MATCH-COUNT = 0
               DISPLAY "(no tasks in this group)"
           END-IF.

      *>=============================================================
      *> FILE ACCESS
      *>=============================================================
       LOAD-TASKS-FROM-FILE.
           MOVE 0 TO WS-TASK-COUNT
           OPEN INPUT TASK-FILE

           IF FILE-OK
               PERFORM READ-ALL-RECORDS-INTO-TABLE
               CLOSE TASK-FILE
           ELSE
      *>       No file yet on first run: start with an empty list.
               CONTINUE
           END-IF.

       READ-ALL-RECORDS-INTO-TABLE.
           PERFORM UNTIL FILE-END
               READ TASK-FILE
                   AT END
                       SET FILE-END TO TRUE
                   NOT AT END
                       PERFORM STORE-RECORD-IN-TABLE
               END-READ
           END-PERFORM.

       STORE-RECORD-IN-TABLE.
           ADD 1 TO WS-TASK-COUNT
           SET WS-TASK-IDX TO WS-TASK-COUNT
           MOVE TR-TIMESTAMP      TO WS-T-TIMESTAMP(WS-TASK-IDX)
           MOVE TR-URGENT-FLAG    TO WS-T-URGENT(WS-TASK-IDX)
           MOVE TR-IMPORTANT-FLAG TO WS-T-IMPORTANT(WS-TASK-IDX)
           MOVE TR-DESCRIPTION    TO WS-T-DESCRIPTION(WS-TASK-IDX).

       SAVE-TASKS-TO-FILE.
           OPEN OUTPUT TASK-FILE
           PERFORM VARYING WS-TASK-IDX FROM 1 BY 1
                   UNTIL WS-TASK-IDX > WS-TASK-COUNT
               MOVE WS-T-TIMESTAMP(WS-TASK-IDX)  TO TR-TIMESTAMP
               MOVE WS-T-URGENT(WS-TASK-IDX)     TO TR-URGENT-FLAG
               MOVE WS-T-IMPORTANT(WS-TASK-IDX)  TO TR-IMPORTANT-FLAG
               MOVE WS-T-DESCRIPTION(WS-TASK-IDX) TO TR-DESCRIPTION
               WRITE TASK-RECORD
           END-PERFORM
           CLOSE TASK-FILE.

      *>=============================================================
      *> SORTING
      *> Plain bubble sort, newest timestamp first. Chosen for
      *> clarity over speed, in line with the small size of a
      *> personal TODO list.
      *>=============================================================
       SORT-TASKS-NEWEST-FIRST.
      *>     Loop runs at least once, and stops as soon as a full
      *>     pass completes with no swaps, meaning the table is
      *>     already ordered newest-first.
           PERFORM WITH TEST AFTER UNTIL NO-SWAP-HAPPENED
               SET NO-SWAP-HAPPENED TO TRUE
               PERFORM VARYING WS-SORT-I FROM 1 BY 1
                       UNTIL WS-SORT-I > WS-TASK-COUNT - 1
                   COMPUTE WS-SORT-J = WS-SORT-I + 1
                   IF WS-T-TIMESTAMP(WS-SORT-I) < WS-T-TIMESTAMP(WS-SORT-J)
                       PERFORM SWAP-TABLE-ENTRIES
                       SET SWAP-HAPPENED TO TRUE
                   END-IF
               END-PERFORM
           END-PERFORM.

       SWAP-TABLE-ENTRIES.
           MOVE WS-T-TIMESTAMP(WS-SORT-I)  TO WS-TEMP-TIMESTAMP
           MOVE WS-T-URGENT(WS-SORT-I)     TO WS-TEMP-URGENT
           MOVE WS-T-IMPORTANT(WS-SORT-I)  TO WS-TEMP-IMPORTANT
           MOVE WS-T-DESCRIPTION(WS-SORT-I) TO WS-TEMP-DESCRIPTION

           MOVE WS-T-TIMESTAMP(WS-SORT-J)  TO WS-T-TIMESTAMP(WS-SORT-I)
           MOVE WS-T-URGENT(WS-SORT-J)     TO WS-T-URGENT(WS-SORT-I)
           MOVE WS-T-IMPORTANT(WS-SORT-J)  TO WS-T-IMPORTANT(WS-SORT-I)
           MOVE WS-T-DESCRIPTION(WS-SORT-J) TO WS-T-DESCRIPTION(WS-SORT-I)

           MOVE WS-TEMP-TIMESTAMP    TO WS-T-TIMESTAMP(WS-SORT-J)
           MOVE WS-TEMP-URGENT       TO WS-T-URGENT(WS-SORT-J)
           MOVE WS-TEMP-IMPORTANT    TO WS-T-IMPORTANT(WS-SORT-J)
           MOVE WS-TEMP-DESCRIPTION  TO WS-T-DESCRIPTION(WS-SORT-J).
