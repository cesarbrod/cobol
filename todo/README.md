# Understanding `todo.cob`: A Line-by-Line Tutorial

This tutorial walks through `todo.cob` from top to bottom. It assumes
you know basic programming concepts (variables, loops, conditionals,
functions) but have never touched COBOL. Every COBOL-specific structure gets
explained the first time it appears.

All line numbers below refer to `todo_manager.cob` as delivered.

---

## 1. The big picture before the code

Four things happen in this program, and everything else is plumbing to
support them:

1. **Ask the user for a task** (description, urgent Y/N, important Y/N).
2. **Load the existing tasks** from a text file into memory.
3. **Add the new task, sort everything by timestamp**, newest first.
4. **Save the whole list back to the file.**

Listing tasks reuses steps 2 and part of the display logic, filtered by
quadrant instead of writing.

There's no database. The "database" is a table (an array, in most languages'
terms) in memory, kept in sync with a plain text file. This is normal for a
small educational COBOL program — real business COBOL usually talks to
indexed files or a real database instead.

---

## 2. COBOL's shape: four divisions

Every COBOL program is split into up to four **DIVISIONs**, always in this
order. Think of them as four mandatory chapters:

| Division | Line | What it's for |
|---|---|---|
| IDENTIFICATION DIVISION | 14 | Names the program. Metadata only. |
| ENVIRONMENT DIVISION | 18 | Connects the program to the outside world (files, hardware). |
| DATA DIVISION | 25 | Declares every variable the program will use. |
| PROCEDURE DIVISION | 94 | The actual logic. Everything your program *does*. |

This is COBOL's biggest structural difference from languages like Python or
JavaScript: **you cannot declare a variable where you use it.** All storage
is declared upfront in the DATA DIVISION, then the PROCEDURE DIVISION only
manipulates what already exists. There's no `let x = 5` mid-logic.

Line 13, `>>SOURCE FORMAT FREE`, is a compiler directive telling GnuCOBOL to
accept free-format code (like C or Python) instead of the historical
fixed-column layout (where code literally had to start in column 8 or 12,
a rule inherited from 1959-era punch cards). Free format is easier to read
and is what this tutorial assumes.

---

## 3. IDENTIFICATION DIVISION (lines 14–16)

```cobol
IDENTIFICATION DIVISION.
PROGRAM-ID. TODO-MANAGER.
AUTHOR. Cesar Brod.
```

`PROGRAM-ID` is the only mandatory line here — it's the internal name of the
program, similar to a `class Main` or a Python module name. `AUTHOR` is
purely descriptive; the compiler ignores it.

---

## 4. ENVIRONMENT DIVISION (lines 18–23)

```cobol
ENVIRONMENT DIVISION.
INPUT-OUTPUT SECTION.
FILE-CONTROL.
    SELECT TASK-FILE ASSIGN TO WS-TASK-FILE-PATH
        ORGANIZATION IS LINE SEQUENTIAL
        FILE STATUS IS WS-FILE-STATUS.
```

This is the one and only place in the program where you connect an internal
file name (`TASK-FILE`, used everywhere else in the code) to an actual
filename on disk. `ASSIGN TO WS-TASK-FILE-PATH` points at a variable
(defined later, line 39) that holds the literal string `"tasks.txt"`.
Pointing at a variable instead of hardcoding the filename here is what lets
you change the file path in one place if you ever need to.

`ORGANIZATION IS LINE SEQUENTIAL` means: this is a plain text file, one
record per line, readable in any text editor. The alternative would be
`ORGANIZATION IS INDEXED`, which creates a binary file with fast lookups by
key — overkill and non-transparent for a learning project.

`FILE STATUS IS WS-FILE-STATUS` links a 2-character variable that COBOL
automatically updates after every file operation (open, read, write, close)
with a status code — `"00"` for success, `"10"` for end-of-file, `"35"` for
"file not found", and so on. This is COBOL's equivalent of a return code or
an exception — you don't get exceptions, you get a status code you're
expected to check.

---

## 5. DATA DIVISION — FILE SECTION (lines 25–32)

```cobol
DATA DIVISION.
FILE SECTION.
FD  TASK-FILE.
01  TASK-RECORD.
    05  TR-TIMESTAMP            PIC X(14).
    05  TR-URGENT-FLAG          PIC X(01).
    05  TR-IMPORTANT-FLAG       PIC X(01).
    05  TR-DESCRIPTION          PIC X(140).
```

`FD` stands for **File Description**. It describes what one record (one
line) of `TASK-FILE` looks like, field by field.

Two new concepts appear here that you'll see for the rest of the program:

**Level numbers.** The `01` and `05` at the start of each line aren't
arbitrary — they express nesting, like indentation in Python or braces in
C. `01 TASK-RECORD` is the whole record; the `05` fields underneath are its
components. Level numbers don't have to be consecutive (01, 05, 10, 15... is
a very common convention, leaving room to insert 02–04 later if needed), but
a smaller number always contains larger numbers nested under it. This is
COBOL's version of a `struct` or a nested dictionary.

**PIC clauses.** `PIC` (short for **PICTURE**) declares a field's type and
exact size — something most modern languages leave to the runtime, but
COBOL fixes at compile time because it was built for fixed-width file
records. `PIC X(14)` means "alphanumeric (`X`), 14 characters, always
exactly 14, padded with spaces if the actual content is shorter." So:

- `TR-TIMESTAMP` — 14 characters, holds `YYYYMMDDHHMMSS`.
- `TR-URGENT-FLAG` — 1 character, `"Y"` or `"N"`.
- `TR-IMPORTANT-FLAG` — 1 character, `"Y"` or `"N"`.
- `TR-DESCRIPTION` — 140 characters, the task text (padded with trailing
  spaces if shorter).

Add those up: 14 + 1 + 1 + 140 = **156 characters per line**, always. That
fixed width is exactly what lets the program later read the file back
without any parsing logic — no commas, no delimiters, no quoting rules to
worry about. Every field starts and ends at a known column.

---

## 6. DATA DIVISION — WORKING-STORAGE SECTION (lines 34–89)

If FILE SECTION describes what's *on disk*, WORKING-STORAGE describes
everything the program keeps *in memory* while running: every variable,
counter, flag, and temporary buffer. This is the largest chunk of
declarations and it's grouped by purpose with comments (lines 36–38, 45–47,
etc.) — a `*>` starts a comment in free-format COBOL, equivalent to `//` or
`#`.

### 6.1 File handling state (lines 39–43)

```cobol
01  WS-TASK-FILE-PATH           PIC X(40) VALUE "tasks.txt".
01  WS-FILE-STATUS              PIC XX.
    88  FILE-OK                 VALUE "00".
    88  FILE-NOT-FOUND          VALUE "35".
    88  FILE-END                VALUE "10".
```

Note: WS is just a COBOL convention. It means WORKING-STORAGE.

`VALUE "tasks.txt"` sets the initial content of the field at program start
— this is COBOL's version of `= "tasks.txt"` at declaration time.

The `88` level is a COBOL feature with no direct equivalent in most modern
languages: a **condition name**. It doesn't create a new variable — it
creates a *named boolean test* against the variable one level above it. So
`88 FILE-OK VALUE "00"` means: whenever code says `IF FILE-OK`, COBOL
actually checks `IF WS-FILE-STATUS = "00"`. You'll see this used at line
353 (`IF FILE-OK`) and line 362 (`PERFORM UNTIL FILE-END`) — reading
`IF FILE-OK` is far clearer than reading `IF WS-FILE-STATUS = "00"`
scattered through the code, and it means the magic string `"00"` only
needs to be written once.

### 6.2 The in-memory task table (lines 48–56)

```cobol
01  WS-MAX-TASKS                PIC 9(4) VALUE 2000.
01  WS-TASK-COUNT                PIC 9(4) VALUE 0.
01  WS-TASK-TABLE.
    05  WS-TASK-ENTRY OCCURS 2000 TIMES
                              INDEXED BY WS-TASK-IDX.
        10  WS-T-TIMESTAMP       PIC X(14).
        10  WS-T-URGENT          PIC X(01).
        10  WS-T-IMPORTANT       PIC X(01).
        10  WS-T-DESCRIPTION     PIC X(140).
```

`PIC 9(4)` is a **numeric** field, 4 digits, unlike `PIC X` which is
text. `WS-TASK-COUNT` tracks how many tasks are currently loaded.

`OCCURS 2000 TIMES` is COBOL's array declaration. This single clause turns
`WS-TASK-ENTRY` into a table of 2000 identical records, each with a
timestamp, urgent flag, important flag, and description — the in-memory
mirror of one line in `tasks.txt`. `2000` was a design choice: it's a
generous ceiling for a personal TODO list, declared once and reused as
`WS-MAX-TASKS` for documentation, even though the array size itself has to
be a literal number in the `OCCURS` clause (COBOL doesn't let you size an
array with a variable at declaration time).

`INDEXED BY WS-TASK-IDX` declares the variable you'll use to walk through
the table — `WS-TASK-IDX` behaves like an array index (`i` in `for (i =
0...)`) but COBOL manages its type and bounds-checking for you, and it's
scoped specifically to this table.

To reach one field of one row, you write `WS-T-TIMESTAMP(WS-TASK-IDX)` —
same idea as `table[i].timestamp` in a language with structs. You'll see
this pattern constantly from line 177 onward.

### 6.3 Sorting helpers (lines 61–70)

```cobol
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
```

`WS-SORT-I` and `WS-SORT-J` are two loop counters used by the bubble sort
(section 12). `WS-SORT-SWAPPED` is a boolean-style flag using the same `88`
condition-name trick as before — instead of `IF WS-SORT-SWAPPED = "Y"`
you'll read `IF SWAP-HAPPENED`. `WS-SORT-TEMP` is scratch space: a
one-record-sized holding area used while swapping two table rows (you can't
swap `A` and `B` directly without a temporary variable — the classic
`temp = a; a = b; b = temp` pattern, just declared upfront as COBOL
requires).

### 6.4 New-task capture (lines 75–79)

```cobol
01  WS-NEW-DESCRIPTION          PIC X(140).
01  WS-NEW-TIMESTAMP            PIC X(14).
01  WS-URGENT-ANSWER            PIC X(01).
01  WS-IMPORTANT-ANSWER         PIC X(01).
01  WS-CURRENT-DATETIME         PIC X(21).
```

These hold the raw answers from the user while creating a task, before
they're copied into the table. `WS-CURRENT-DATETIME` is 21 characters
because that's how much the built-in date/time function returns (see
section 9.3) — only the first 14 of those 21 characters are actually used.

### 6.5 Menu and listing control (lines 84–89)

```cobol
01  WS-MAIN-CHOICE              PIC X(01).
01  WS-KEEP-RUNNING             PIC X(01) VALUE "Y".
01  WS-LIST-ALL-ANSWER          PIC X(01).
01  WS-QUADRANT-CHOICE          PIC X(01).
01  WS-MATCH-COUNT              PIC 9(4).
01  WS-DISPLAY-LINE             PIC X(160).
```

`WS-KEEP-RUNNING` is the flag controlling the main program loop, starting
as `"Y"` (line 85) so the loop runs at least once. `WS-DISPLAY-LINE` is a
scratch buffer used to build one line of screen output before printing it
(see section 13.6) — 160 characters is just enough room for a timestamp,
brackets, and a full 140-character description.

---

## 7. PROCEDURE DIVISION: how COBOL organizes logic

```cobol
PROCEDURE DIVISION.

MAIN-CONTROL.
    ...
```

Everything from line 94 onward is executable logic. COBOL has no functions
in the sense of Python `def` or C — instead it has **paragraphs**: a name
(like `MAIN-CONTROL`, `CREATE-NEW-TASK`, `SHOW-MAIN-MENU`) followed by a
period, followed by statements, ending only when the next paragraph name
appears. You call a paragraph with `PERFORM ParagraphName` — that's COBOL's
version of calling a function. There are no parameters and no return
values; paragraphs simply read and write the shared WORKING-STORAGE
variables directly. This is a real difference from modern functions: every
paragraph has full access to every variable in the program, so naming
things clearly (as this program tries to do, e.g. `CAPTURE-URGENCY-ANSWER`,
`DISPLAY-TASKS-IMPORTANT-URGENT`) is how you keep it readable instead of
relying on parameter lists to document intent.

This program is deliberately organized as **one short "driver" paragraph
per feature, made of PERFORM calls to small single-purpose paragraphs**.
`MAIN-CONTROL` (line 96) and `CREATE-NEW-TASK` (line 132) read almost like
a table of contents. That's the "Clean Code" influence you asked for:
each paragraph does one thing, and the name says what.

---

## 8. The main loop (lines 96–127)

```cobol
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
```

`PERFORM UNTIL <condition>` is COBOL's `while` loop, except the condition
describes when to **stop**, not when to continue — closer to a `do...while
NOT condition` in C. The outer loop (line 97) keeps the whole program alive
until `WS-KEEP-RUNNING` becomes `"N"`.

The inner loop (lines 99–104) is **input validation**: show the menu, and
if the answer isn't `"1"`, `"2"`, or `"3"`, complain and ask again. This
exact validate-and-reprompt pattern repeats throughout the program (urgency,
importance, list-all-or-filtered, quadrant choice) — always the same shape:
loop while the answer isn't in the allowed set.

`EVALUATE` is COBOL's `switch`/`match` statement. `WHEN "1"` is a case
label; unlike C's `switch`, there's no fallthrough to worry about and no
`break` needed — each `WHEN` branch stops automatically at the next `WHEN`
or at `END-EVALUATE`.

`MOVE "N" TO WS-KEEP-RUNNING` is how COBOL assigns a value — `MOVE source
TO destination`. Note the direction: source first, destination second,
opposite of `destination = source` in C-like languages. This trips up
almost every newcomer to COBOL at least once.

`STOP RUN.` terminates the program — COBOL's `exit()` / `sys.exit()`, but
only ever used once, right at the natural end of `MAIN-CONTROL`.

---

## 9. Creating a task (lines 132–182)

### 9.1 The driver paragraph

```cobol
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
```

Read this top to bottom and it's plain English: gather the four pieces of
data, load what's already saved, add the new one, sort, save. Nothing here
does the actual work — it delegates to eight paragraphs, each named for
exactly what it does. This is the whole point of breaking logic into small
paragraphs: you can understand *what* happens without yet knowing *how*.

### 9.2 Capturing the description (lines 146–149)

```cobol
CAPTURE-TASK-DESCRIPTION.
    DISPLAY " ".
    DISPLAY "Describe the task (max 140 characters):".
    ACCEPT WS-NEW-DESCRIPTION.
```

`DISPLAY` prints to the screen — COBOL's `print()`. `ACCEPT` reads user
input into a variable — COBOL's `input()`. Because `WS-NEW-DESCRIPTION` was
declared as `PIC X(140)` (line 75), `ACCEPT` physically cannot store more
than 140 characters — anything the user types beyond that is simply not
captured. That's the entire enforcement of the "140 character limit"
requirement: it's a side effect of the field's fixed size, not a
length-check `IF` statement. This is a good example of using the type
system to enforce a rule instead of writing defensive code for it.

### 9.3 Capturing urgency and importance (lines 151–168)

```cobol
CAPTURE-URGENCY-ANSWER.
    MOVE SPACES TO WS-URGENT-ANSWER
    PERFORM UNTIL WS-URGENT-ANSWER = "Y" OR WS-URGENT-ANSWER = "N"
        DISPLAY "Is it urgent? (Y/N): " WITH NO ADVANCING
        ACCEPT WS-URGENT-ANSWER
        MOVE FUNCTION UPPER-CASE(WS-URGENT-ANSWER)
            TO WS-URGENT-ANSWER
    END-PERFORM.
```

`MOVE SPACES TO WS-URGENT-ANSWER` resets the field before the loop starts
— otherwise a leftover value from a previous task (this paragraph runs once
per task created) could accidentally satisfy the loop's exit condition
before the user even answers.

`WITH NO ADVANCING` on `DISPLAY` suppresses the automatic newline, so the
next `ACCEPT` reads input on the same line as the prompt — familiar if
you've used `print(..., end="")` in Python or `printf` without `\n` in C.

`FUNCTION UPPER-CASE(...)` is a **built-in function** — COBOL has a small
standard library of these (`UPPER-CASE`, `TRIM`, `CURRENT-DATE`, etc.),
called with `FUNCTION Name(arguments)`. Here it means the user can type
`y`, `Y`, `n`, or `N` and the program normalizes it to uppercase before
checking the loop condition. `CAPTURE-IMPORTANCE-ANSWER` (lines 160–168) is
the identical pattern for the importance question.

### 9.4 Capturing the timestamp (lines 170–172)

```cobol
CAPTURE-CURRENT-TIMESTAMP.
    MOVE FUNCTION CURRENT-DATE TO WS-CURRENT-DATETIME
    MOVE WS-CURRENT-DATETIME(1:14) TO WS-NEW-TIMESTAMP.
```

`FUNCTION CURRENT-DATE` returns 21 characters:
`YYYYMMDDHHMMSSssTTTTTT` (date, time to the second, hundredths of a
second, and a timezone offset). The program only wants the first 14
characters (`YYYYMMDDHHMMSS`).

`WS-CURRENT-DATETIME(1:14)` is **reference modification** — COBOL's
substring syntax. It means "starting at character position 1, take 14
characters." This is equivalent to Python's `WS-CURRENT-DATETIME[0:14]`,
just with 1-based instead of 0-based indexing (COBOL counts from 1
everywhere, not 0).

Choosing `YYYYMMDDHHMMSS` as the timestamp format isn't arbitrary: sorting
these strings *alphabetically* produces the same order as sorting them
*chronologically*, because each field is fixed-width and most-significant
first (year, then month, then day...). That's exactly what makes the plain
`<` comparison used in the sort (section 12) correct without needing to
parse the string into an actual date type.

### 9.5 Appending to the table (lines 174–182)

```cobol
APPEND-NEW-TASK-TO-TABLE.
    ADD 1 TO WS-TASK-COUNT
    SET WS-TASK-IDX TO WS-TASK-COUNT
    MOVE WS-NEW-TIMESTAMP  TO WS-T-TIMESTAMP(WS-TASK-IDX)
    MOVE WS-URGENT-ANSWER  TO WS-T-URGENT(WS-TASK-IDX)
    MOVE WS-IMPORTANT-ANSWER
                           TO WS-T-IMPORTANT(WS-TASK-IDX)
    MOVE WS-NEW-DESCRIPTION
                           TO WS-T-DESCRIPTION(WS-TASK-IDX).
```

`ADD 1 TO WS-TASK-COUNT` is COBOL's `count += 1`. `SET index TO value` is
how you assign to an index variable specifically (as opposed to `MOVE`,
which you use for regular fields) — COBOL keeps index arithmetic separate
from general data movement. After these two lines, `WS-TASK-IDX` points at
the next free slot in the table, and the four `MOVE` statements fill it in
— same idea as `table.append({...})` in Python, just spelled out field by
field because COBOL tables aren't dynamically resizable structures.

---

## 10. Listing tasks (lines 187–257)

### 10.1 The driver

```cobol
LIST-TASKS.
    PERFORM LOAD-TASKS-FROM-FILE

    IF WS-TASK-COUNT = 0
        DISPLAY " "
        DISPLAY "There are no tasks yet."
    ELSE
        PERFORM ASK-LIST-ALL-OR-FILTERED
    END-IF.
```

Standard `IF / ELSE / END-IF` — every `IF` block in free-format COBOL
needs its own `END-IF` (or a period) to know where it stops, since COBOL
doesn't use braces or indentation to define blocks.

### 10.2 Choosing all-tasks vs. one quadrant (lines 197–222)

```cobol
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
```

Same validate-and-reprompt pattern as before. `LIST-ALL-QUADRANTS-IN-ORDER`
is worth noticing for what it *doesn't* do: it doesn't sort or filter
anything itself. It just calls eight paragraphs in the exact sequence the
Eisenhower Matrix requires (Important+Not Urgent → Important+Urgent →
Not Important+Urgent → Not Important+Not Urgent). The actual filtering
logic lives one level down, in the `DISPLAY-TASKS-*` paragraphs — this
paragraph is purely about *order*.

### 10.3 Choosing one quadrant (lines 224–257)

```cobol
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
```

Same shape as `MAIN-CONTROL`'s `EVALUATE` (section 8): validate the menu
choice, then dispatch to the matching paragraph pair (header + list).

---

## 11. Displaying tasks (lines 262–344)

### 11.1 Headers (lines 262–276)

```cobol
DISPLAY-QUADRANT-HEADER-1.
    DISPLAY " ".
    DISPLAY "--- Important and Not Urgent ---".
```

Four tiny, near-identical paragraphs, one per quadrant label. They could
have been merged into one paragraph taking a "which quadrant" flag, but
keeping them separate keeps each call site (`PERFORM
DISPLAY-QUADRANT-HEADER-1`) self-explanatory without you needing to know
what argument means what — a small trade of a few extra lines for
readability.

### 11.2 Filtering one quadrant (lines 283–329)

```cobol
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
```

`PERFORM VARYING x FROM 1 BY 1 UNTIL condition` is COBOL's classic
counted `for` loop — equivalent to `for (x = 1; !condition; x++)` in C, or
`for x in range(1, n+1)` in Python. Here it walks every row of the task
table from index 1 to `WS-TASK-COUNT`.

Inside the loop, the `IF` checks both flags for this exact quadrant
(Important = `"Y"`, Urgent = `"N"`). If both match, it prints the task
(`PERFORM DISPLAY-ONE-TASK`) and bumps a counter. That counter,
`WS-MATCH-COUNT`, exists purely so the paragraph can tell afterward whether
it found anything at all — which is what `DISPLAY-NONE-FOUND-IF-EMPTY`
(line 341) checks to print `"(no tasks in this group)"` instead of an
empty section.

The other three `DISPLAY-TASKS-*` paragraphs (lines 295, 307, 319) are the
same structure with the two `IF` conditions flipped for their quadrant.
Four paragraphs that look almost identical is a deliberate simplicity
trade-off: a single generic "filter by two Y/N parameters" paragraph would
be shorter, but COBOL paragraphs don't take parameters, so achieving that
would mean routing through extra flag variables — arguably harder to
follow than four paragraphs that say exactly what they filter for right in
their names.

**Why no separate sort is needed here:** the table is already sorted
newest-first every time a task is created (see section 12), and it's
reloaded fresh from the file (also already sorted, since it was saved
sorted) at the top of `LIST-TASKS`. So a single top-to-bottom pass through
the table, in order, naturally produces newest-first output within each
quadrant — no extra sorting step at display time.

### 11.3 Building one line of output (lines 331–339)

```cobol
DISPLAY-ONE-TASK.
    MOVE SPACES TO WS-DISPLAY-LINE
    STRING
        "[" WS-T-TIMESTAMP(WS-TASK-IDX) "] "
        FUNCTION TRIM(WS-T-DESCRIPTION(WS-TASK-IDX))
        DELIMITED BY SIZE
        INTO WS-DISPLAY-LINE
    END-STRING
    DISPLAY FUNCTION TRIM(WS-DISPLAY-LINE).
```

`STRING ... INTO field` is COBOL's string concatenation — it glues several
pieces together into one field, in order: a literal `"["`, the timestamp,
a literal `"] "`, then the trimmed description. `DELIMITED BY SIZE` means
"use the whole size of each piece, don't stop at any special character" —
the alternative, `DELIMITED BY SPACE`, would stop copying at the first
space, which is not what we want here since descriptions contain spaces.

`FUNCTION TRIM(...)` strips leading/trailing spaces — necessary because
`WS-T-DESCRIPTION` is a fixed 140-character field, so a short description
like `"Buy milk"` is actually stored as `"Buy milk"` followed by 132
trailing spaces. Without `TRIM`, every line printed would be padded out to
full width.

**The `MOVE SPACES TO WS-DISPLAY-LINE` on the first line matters more than
it looks.** `WS-DISPLAY-LINE` is a shared 160-character buffer reused for
every task printed. If a long description's `STRING` result is followed
later by a shorter one, and the buffer isn't cleared first, leftover
characters from the *previous* task can remain sitting after the new,
shorter text — because `STRING` only overwrites as many characters as it
writes, not the whole field. This was an actual bug caught during testing
of this program: without the `MOVE SPACES` reset, "Fix production bug"
printed as "Fix production bugy report", with the tail end of the previous
line's text bleeding through. Clearing the buffer before every `STRING`
call is the fix, and it's a pattern worth remembering any time you reuse a
fixed-size buffer in a loop.

---

## 12. Sorting: the bubble sort (lines 397–427)

```cobol
SORT-TASKS-NEWEST-FIRST.
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
```

This is a **bubble sort**, one of the simplest sorting algorithms to
understand (though not the fastest — more on that below). The idea: repeatedly
scan through the table comparing each pair of neighbors; whenever a pair is
out of order, swap them. Keep making full passes until a pass happens with
zero swaps — that means everything is finally in order.

Breaking down the COBOL specifically:

- `PERFORM WITH TEST AFTER UNTIL condition` is a **do-while** loop: run the
  body *first*, then check the condition, repeating until it's true. This
  matters here because it guarantees at least one pass through the table
  even if there's only one task — a plain `PERFORM UNTIL` (test-before,
  like the loops used everywhere else in this program) would need its flag
  pre-set correctly to avoid skipping the first pass entirely, which is an
  easy mistake to make.
- `SET NO-SWAP-HAPPENED TO TRUE` (line 402) resets the flag to "nothing
  swapped yet" at the start of *every* pass. If the inner loop completes
  without ever setting it back to `SWAP-HAPPENED`, the outer loop's
  condition becomes true and sorting stops.
- The inner `PERFORM VARYING` (lines 403–404) walks pairs of neighboring
  rows: `WS-SORT-I` and `WS-SORT-J` (always `I + 1`, computed on line 405).
  It stops one row early (`UNTIL WS-SORT-I > WS-TASK-COUNT - 1`) because
  comparing row `I` to row `I+1` would go out of bounds on the very last
  row otherwise.
- `IF WS-T-TIMESTAMP(WS-SORT-I) < WS-T-TIMESTAMP(WS-SORT-J)` — this is the
  entire "newest first" rule. Because timestamps are stored as
  `YYYYMMDDHHMMSS` text (see section 9.4), an *older* timestamp is
  alphabetically *smaller*. So "row I is older than row J" (meaning they're
  in the wrong order for a newest-first list) is caught by ordinary string
  comparison — no date-math required.

**A note on this being a deliberate trade-off, not an oversight:** bubble
sort has to make up to roughly `n²` comparisons for `n` tasks, so it gets
slow for large lists. For a personal TODO list this is fine — even a few
thousand tasks sort near-instantly on modern hardware — but if this table
ever grew to tens of thousands of rows, you'd want a faster algorithm (like
quicksort or mergesort). The choice here favors "obviously correct and easy
to read" over "fast," which the original brief explicitly asked for.

### The swap itself (lines 413–427)

```cobol
SWAP-TABLE-ENTRIES.
    MOVE WS-T-TIMESTAMP(WS-SORT-I)  TO WS-TEMP-TIMESTAMP
    MOVE WS-T-URGENT(WS-SORT-I)     TO WS-TEMP-URGENT
    MOVE WS-T-IMPORTANT(WS-SORT-I)  TO WS-TEMP-IMPORTANT
    MOVE WS-T-DESCRIPTION(WS-SORT-I) TO WS-TEMP-DESCRIPTION

    MOVE WS-T-TIMESTAMP(WS-SORT-J)  TO WS-T-TIMESTAMP(WS-SORT-I)
    ...
    MOVE WS-TEMP-TIMESTAMP    TO WS-T-TIMESTAMP(WS-SORT-J)
    ...
```

This is the textbook three-step swap: copy row I into a temporary holding
area (`WS-SORT-TEMP`, declared back in section 6.3), copy row J into row
I's old spot, then copy the temporary (row I's original data) into row J.
It's done field-by-field (timestamp, urgent, important, description)
because COBOL doesn't have a single "swap this whole record" statement —
each `MOVE` only handles one field at a time (or one group, but here the
group is split for clarity).

---

## 13. File access: loading and saving (lines 349–389)

### 13.1 Loading (lines 349–359)

```cobol
LOAD-TASKS-FROM-FILE.
    MOVE 0 TO WS-TASK-COUNT
    OPEN INPUT TASK-FILE

    IF FILE-OK
        PERFORM READ-ALL-RECORDS-INTO-TABLE
        CLOSE TASK-FILE
    ELSE
        CONTINUE
    END-IF.
```

`OPEN INPUT TASK-FILE` attempts to open the file for reading. Right after,
`IF FILE-OK` checks the `88`-level condition name from section 6.1 — did
that open actually succeed? If the file doesn't exist yet (true on the very
first run of the program, before any task has ever been saved), the open
fails, `FILE-OK` is false, and the `ELSE` branch runs `CONTINUE` — COBOL's
"do nothing, this is intentional" no-op, used here to explicitly say: it's
fine if the file is missing, just proceed with an empty table
(`WS-TASK-COUNT` was already reset to 0 on line 350).

### 13.2 Reading every record (lines 361–369)

```cobol
READ-ALL-RECORDS-INTO-TABLE.
    PERFORM UNTIL FILE-END
        READ TASK-FILE
            AT END
                SET FILE-END TO TRUE
            NOT AT END
                PERFORM STORE-RECORD-IN-TABLE
        END-READ
    END-PERFORM.
```

`READ TASK-FILE` reads the next line into `TASK-RECORD` (declared in the
FILE SECTION, section 5). COBOL's `READ` statement has two built-in
branches: `AT END`, which runs automatically when there's nothing left to
read, and `NOT AT END`, which runs when a record was actually read
successfully. This is COBOL's way of handling "loop until the file runs
out" without you manually checking a return value after every read — the
branching is baked into the `READ` statement itself. `SET FILE-END TO
TRUE` sets the `88`-level flag that stops the surrounding `PERFORM UNTIL`.

### 13.3 Copying one record into the table (lines 371–377)

```cobol
STORE-RECORD-IN-TABLE.
    ADD 1 TO WS-TASK-COUNT
    SET WS-TASK-IDX TO WS-TASK-COUNT
    MOVE TR-TIMESTAMP      TO WS-T-TIMESTAMP(WS-TASK-IDX)
    MOVE TR-URGENT-FLAG    TO WS-T-URGENT(WS-TASK-IDX)
    MOVE TR-IMPORTANT-FLAG TO WS-T-IMPORTANT(WS-TASK-IDX)
    MOVE TR-DESCRIPTION    TO WS-T-DESCRIPTION(WS-TASK-IDX).
```

Same shape as `APPEND-NEW-TASK-TO-TABLE` (section 9.5) — grow the count,
point the index at the new slot, copy every field. The only difference is
the source: here it's copying from the file record (`TR-*` fields) instead
of from the user's fresh answers (`WS-NEW-*` fields).

### 13.4 Saving (lines 379–389)

```cobol
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
```

`OPEN OUTPUT` (as opposed to `OPEN INPUT`, used for loading) opens the file
for writing and, importantly, **truncates it** — any old content is wiped
the moment the file opens. That's exactly what's needed here: the program
always rewrites the *entire* file from the in-memory table, rather than
appending, because the table might now be in a different order (newly
sorted) than what was on disk before.

The loop walks the table start to finish, copies each row's four fields
into the `TASK-RECORD` buffer, and `WRITE TASK-RECORD` appends that buffer
as the next line of the file. Because `SORT-TASKS-NEWEST-FIRST` already ran
before this paragraph is called (see `CREATE-NEW-TASK`, section 9.1), the
table — and therefore the file — ends up newest-first, satisfying the
storage requirement directly, with no special-casing needed in the save
logic itself.

---

## 14. Tracing one full run, start to finish

Put it all together by following what happens when you pick "1. Create new
task", answer the prompts, then later pick "2. List tasks" → "Y" (list
all):

1. `MAIN-CONTROL` (96) shows the menu, reads `"1"`, calls `CREATE-NEW-TASK`.
2. `CREATE-NEW-TASK` (132) asks for the description (146), urgency (151),
   importance (160), and stamps the current time (170).
3. It loads whatever's already in `tasks.txt` into the table
   (`LOAD-TASKS-FROM-FILE`, 349), adds the new task at the end of the table
   (`APPEND-NEW-TASK-TO-TABLE`, 174), bubble-sorts the table newest-first
   (`SORT-TASKS-NEWEST-FIRST`, 397), and rewrites the whole file
   (`SAVE-TASKS-TO-FILE`, 379).
4. Back at the menu, you pick `"2"`. `LIST-TASKS` (187) reloads the file
   into the table (again — the table isn't kept between menu actions,
   the file is the single source of truth) and asks "List all? (Y/N)".
5. You answer `"Y"`. `LIST-ALL-QUADRANTS-IN-ORDER` (214) runs through the
   four quadrants in the fixed Eisenhower order, each time printing a
   header then scanning the table top-to-bottom for matches
   (`DISPLAY-TASKS-*`, 283–329) — which, since the table is already
   newest-first, prints each quadrant's tasks newest-first automatically.
6. Each matching task is formatted and printed by `DISPLAY-ONE-TASK` (331),
   which builds `[timestamp] description` into a cleared buffer before
   showing it.

Every requirement from the original spec — 140-character limit, Y/N
urgency and importance prompts, timestamped storage, four-quadrant
ordering, filtered single-quadrant view, newest-first plain-text storage —
maps to a specific, named paragraph somewhere in this trace. That mapping
is the payoff of writing small, clearly named paragraphs instead of one
long block of logic: you can point at any requirement and know exactly
where in the file to look.
