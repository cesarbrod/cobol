#prompts.md

These are the prompts used to create the initial versions of todo.cob and README.md

##todo.cob

```
Create a COBOL program to be compiled with GNUCobol. This is what the program must do.

It is a TODO List Manager. It will have the following functions:

# Create new task
Ask the user what the task is, limit to 140 characters. Ask the priority in the following way:
Is it urgent? Y/N
Is it important? Y/N
Store the task and its priority, along with the timestamp for the task creation

#List tasks
Ask the user if he wants to list all tasks: in this case, list the tasks in the following order:
Important and Not Urgent | Important and Urgent | Not Important and Urgent | Not Important and Not Urgent

Alternative, allow the user to show only the tasks that are
Important and Not Urgent | Important and Urgent | Not Important and Urgent | Not Important and Not Urgent

#Store tasks
The tasks must be stored in a plain text file in a way were the tasks will be sorted by timestamp (newest first)

This program is for educational purposes, so make sure clarity is more important than performance
or speed. Still, make the code clean as in the Clean Code paradigm.
```

##README.md

```
Now I want you to create a step-by-step tutorial explaining this program for a newbie. Reference line numbers,
chunks of code, programming fundamentals along with COBOL structures. The output must be a single md file.
```
